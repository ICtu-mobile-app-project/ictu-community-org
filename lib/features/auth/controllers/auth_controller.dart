import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ictu_community_org/core/constants/ictu_constants.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../models/user_role.dart';

class AuthFlowResponse {
  const AuthFlowResponse({
    required this.isSuccess,
    this.message,
    this.role,
    this.requiresEmailVerification = false,
  });

  final bool isSuccess;
  final String? message;
  final UserRole? role;
  final bool requiresEmailVerification;
}

class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  AuthController._internal() {
    _authSubscription = _client?.auth.onAuthStateChange.listen((event) {
      _isLoggedIn = event.session != null;
      notifyListeners();
    });
  }

  static const String _emailRedirectTo = String.fromEnvironment(
    'SUPABASE_EMAIL_REDIRECT_TO',
  );

  // Needed for native Google Sign-In to return an idToken on Android.
  static String get _googleWebClientId {
    return const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID').isNotEmpty
        ? const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID')
        : dotenv.get('GOOGLE_WEB_CLIENT_ID', fallback: '');
  }

  // Google Client Secret (kept for potential server-side verification or future use)
  static String get _googleClientSecret {
    return const String.fromEnvironment('GOOGLE_CLIENT_SECRET').isNotEmpty
        ? const String.fromEnvironment('GOOGLE_CLIENT_SECRET')
        : dotenv.get('GOOGLE_CLIENT_SECRET', fallback: '');
  }

  // Used for Supabase OAuth redirect (PKCE) flows. This must match the deep link
  // configured in AndroidManifest.xml (and iOS URL schemes if enabled).
  // Override via: --dart-define=SUPABASE_OAUTH_REDIRECT_TO=...
  static const String _oauthRedirectTo = String.fromEnvironment(
    'SUPABASE_OAUTH_REDIRECT_TO',
    defaultValue: 'ictucommunity://auth/callback',
  );

  bool _isLoggedIn = false;
  UserRole? _activeRole;

  bool get isLoggedIn => _isLoggedIn;
  UserRole? get activeRole => _activeRole;

  StreamSubscription<AuthState>? _authSubscription;

  SupabaseClient? get _client {
    if (!SupabaseBootstrap.isConfigured) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<AuthFlowResponse> signIn({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    final SupabaseClient? client = _client;
    if (client == null) {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    if (!_isSchoolEmail(normalizedEmail)) {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Use your ICT University email ending with @ictuniversity.edu.cm.',
      );
    }

    try {
      final AuthResponse authResult = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final User? user = authResult.user;
      final Session? session = authResult.session;
      if (user == null || session == null) {
        return const AuthFlowResponse(
          isSuccess: false,
          message: 'Login failed. Please check your email and password.',
        );
      }

      final UserRole resolvedRole = await _fetchRole(user.id);
      _activeRole = resolvedRole;
      _isLoggedIn = true;
      notifyListeners();

      return AuthFlowResponse(isSuccess: true, role: resolvedRole);
    } on AuthException catch (error) {
      return AuthFlowResponse(isSuccess: false, message: error.message);
    } catch (_) {
      return const AuthFlowResponse(
        isSuccess: false,
        message: 'Unexpected error while logging in. Please try again.',
      );
    }
  }

  Future<AuthFlowResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    required String faculty,
    required String program,
    required int yearLevel,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    final String normalizedFullName = fullName.trim();
    final SupabaseClient? client = _client;
    if (client == null) {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    if (!_isSchoolEmail(normalizedEmail)) {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Use your ICT University email ending with @ictuniversity.edu.cm.',
      );
    }

    try {
      final AuthResponse signUpResult = await client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: <String, dynamic>{
          'full_name': normalizedFullName,
          'role': role.dbValue,
          'faculty': faculty,
          'program': program,
          'year_level': yearLevel,
        },
        emailRedirectTo: _emailRedirectTo.isEmpty ? null : _emailRedirectTo,
      );

      final User? user = signUpResult.user;
      if (user == null) {
        return const AuthFlowResponse(
          isSuccess: false,
          message: 'Could not create account. Please try again.',
        );
      }

      final FunctionResponse signupBootstrap = await client.functions.invoke(
        'auth-signup',
        body: <String, dynamic>{
          'user_id': user.id,
          'full_name': normalizedFullName,
          'email': normalizedEmail,
          'role': role.dbValue,
          'faculty': faculty,
          'program': program,
          'year_level': yearLevel,
        },
      );

      if (signupBootstrap.status >= 400) {
        return AuthFlowResponse(
          isSuccess: false,
          message: _extractFunctionErrorMessage(signupBootstrap.data),
        );
      }

      if (signupBootstrap.data is Map<String, dynamic>) {
        final Map<String, dynamic> payload =
            signupBootstrap.data as Map<String, dynamic>;
        if (payload['ok'] != true) {
          return AuthFlowResponse(
            isSuccess: false,
            message: _extractFunctionErrorMessage(payload),
          );
        }
      }

      return const AuthFlowResponse(
        isSuccess: true,
        requiresEmailVerification: true,
      );
    } on AuthException catch (error) {
      return AuthFlowResponse(isSuccess: false, message: error.message);
    } on FunctionException catch (error) {
      return AuthFlowResponse(
        isSuccess: false,
        message: _extractFunctionErrorMessage(error.details),
      );
    } catch (_) {
      return const AuthFlowResponse(
        isSuccess: false,
        message: 'Unexpected error while creating account. Please try again.',
      );
    }
  }

  Future<AuthFlowResponse> signInWithGoogle() async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    try {
      final _GoogleAuthResult result = await _signInSupabaseWithGoogle(client);
      final String? email = result.user.email;
      if (email == null || !_isSchoolEmail(email)) {
        await client.auth.signOut();
        return const AuthFlowResponse(
          isSuccess: false,
          message:
              'Use your ICT University email ending with @ictuniversity.edu.cm.',
        );
      }

      final UserRole resolvedRole = await _fetchRole(result.user.id);
      _activeRole = resolvedRole;
      _isLoggedIn = true;
      notifyListeners();
      return AuthFlowResponse(isSuccess: true, role: resolvedRole);
    } on _GoogleAuthCanceled {
      return const AuthFlowResponse(
        isSuccess: false,
        message: 'Google sign-in was cancelled.',
      );
    } on _GoogleAuthMissingIdToken {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Google sign-in is not fully configured (missing idToken). Set GOOGLE_WEB_CLIENT_ID and configure Google in Supabase Auth settings.',
      );
    } on AuthException catch (error) {
      return AuthFlowResponse(isSuccess: false, message: error.message);
    } catch (_) {
      return const AuthFlowResponse(
        isSuccess: false,
        message: 'Unexpected error while signing in with Google. Please try again.',
      );
    }
  }

  Future<AuthFlowResponse> signUpWithGoogle({
    String? fullName,
    required UserRole role,
    required String faculty,
    required String program,
    required int yearLevel,
  }) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    try {
      final _GoogleAuthResult result = await _signInSupabaseWithGoogle(client);

      final String? email = result.user.email;
      if (email == null || !_isSchoolEmail(email)) {
        await client.auth.signOut();
        return const AuthFlowResponse(
          isSuccess: false,
          message:
              'Use your ICT University email ending with @ictuniversity.edu.cm.',
        );
      }

      final String resolvedName = (fullName ?? '').trim().isNotEmpty
          ? (fullName ?? '').trim()
          : (result.googleDisplayName?.trim().isNotEmpty == true
              ? result.googleDisplayName!.trim()
              : 'ICTU User');

      // Store metadata on the auth user as well (helps for future routing fallbacks).
      try {
        await client.auth.updateUser(
          UserAttributes(
            data: <String, dynamic>{
              'full_name': resolvedName,
              'role': role.dbValue,
              'faculty': faculty,
              'program': program,
              'year_level': yearLevel,
            },
          ),
        );
      } catch (_) {
        // Non-fatal; profile bootstrap via edge function remains the source of truth.
      }

      final FunctionResponse signupBootstrap = await client.functions.invoke(
        'auth-signup',
        body: <String, dynamic>{
          'user_id': result.user.id,
          'full_name': resolvedName,
          'email': email,
          'role': role.dbValue,
          'faculty': faculty,
          'program': program,
          'year_level': yearLevel,
        },
      );

      if (signupBootstrap.status >= 400) {
        return AuthFlowResponse(
          isSuccess: false,
          message: _extractFunctionErrorMessage(signupBootstrap.data),
        );
      }

      if (signupBootstrap.data is Map<String, dynamic>) {
        final Map<String, dynamic> payload =
            signupBootstrap.data as Map<String, dynamic>;
        if (payload['ok'] != true) {
          return AuthFlowResponse(
            isSuccess: false,
            message: _extractFunctionErrorMessage(payload),
          );
        }
      }

      _activeRole = role;
      _isLoggedIn = true;
      notifyListeners();
      return AuthFlowResponse(isSuccess: true, role: role);
    } on _GoogleAuthCanceled {
      return const AuthFlowResponse(
        isSuccess: false,
        message: 'Google sign-up was cancelled.',
      );
    } on _GoogleAuthMissingIdToken {
      return const AuthFlowResponse(
        isSuccess: false,
        message:
            'Google sign-up is not fully configured (missing idToken). Set GOOGLE_WEB_CLIENT_ID and configure Google in Supabase Auth settings.',
      );
    } on AuthException catch (error) {
      return AuthFlowResponse(isSuccess: false, message: error.message);
    } on FunctionException catch (error) {
      return AuthFlowResponse(
        isSuccess: false,
        message: _extractFunctionErrorMessage(error.details),
      );
    } catch (_) {
      return const AuthFlowResponse(
        isSuccess: false,
        message: 'Unexpected error while signing up with Google. Please try again.',
      );
    }
  }

  Future<UserRole?> restoreCurrentUserRole() async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return null;
    }

    final User? currentUser = client.auth.currentUser;
    final Session? currentSession = client.auth.currentSession;
    if (currentUser == null || currentSession == null) {
      _isLoggedIn = false;
      _activeRole = null;
      notifyListeners();
      return null;
    }

    final UserRole role = await _fetchRole(currentUser.id);
    _activeRole = role;
    _isLoggedIn = true;
    notifyListeners();
    return role;
  }

  Future<void> signOut() async {
    final SupabaseClient? client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
    _isLoggedIn = false;
    _activeRole = null;
    notifyListeners();
  }

  Future<UserRole> _fetchRole(String userId) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return UserRole.student;
    }

    // Primary source of truth for routing is profiles.role.
    // NOTE: This select can fail if RLS policies are missing/too strict. In that
    // case we still want to try the backend bootstrap function.
    Map<String, dynamic>? profile;
    try {
      profile = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    if (profile != null) {
      final String? roleValue = profile['role'] as String?;
      if (roleValue != null && roleValue.trim().isNotEmpty) {
        return UserRole.fromDb(roleValue);
      }
    }

    // Fallback to bootstrap function if profile row is missing/empty OR cannot
    // be read due to RLS.
    final Session? session = client.auth.currentSession;
    if (session != null) {
      try {
        final FunctionResponse bootstrapResponse = await client.functions
            .invoke(
              'auth-login-bootstrap',
              headers: <String, String>{
                'Authorization': 'Bearer ${session.accessToken}',
              },
              body: <String, dynamic>{
                'user_id': userId,
                'access_token': session.accessToken,
              },
            );

        if (bootstrapResponse.status < 400) {
          final String? roleValue = _extractRoleFromBootstrapPayload(
            bootstrapResponse.data,
          );
          if (roleValue != null && roleValue.trim().isNotEmpty) {
            return UserRole.fromDb(roleValue);
          }
        }
      } catch (_) {
        // Ignore bootstrap errors and continue with metadata fallback.
      }
    }

    try {
      final User? currentUser = client.auth.currentUser;
      final String? metadataRole =
          currentUser?.userMetadata?['role'] as String?;
      return UserRole.fromDb(metadataRole);
    } catch (_) {
      return UserRole.student;
    }
  }

  String? _extractRoleFromBootstrapPayload(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final dynamic role = payload['role'];
      if (role is String && role.trim().isNotEmpty) {
        return role;
      }
      return null;
    }

    if (payload is String && payload.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          final dynamic role = decoded['role'];
          if (role is String && role.trim().isNotEmpty) {
            return role;
          }
        }
      } catch (_) {
        // Ignore malformed payload and keep fallback resolution chain.
      }
    }

    return null;
  }

  bool _isSchoolEmail(String email) {
    final String value = email.toLowerCase();
    return value.endsWith(ICTUConstants.schoolEmailDomain);
  }

  String _extractFunctionErrorMessage(dynamic payload) {
    if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      final dynamic value = payload['error'] ?? payload['message'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return 'Signup failed. Please check your information and try again.';
  }

  Future<_GoogleAuthResult> _signInSupabaseWithGoogle(SupabaseClient client) async {
    // Prefer the native google_sign_in flow on Android/iOS where supported.
    // If it's not configured (missing google-services.json / missing Web client id)
    // or the platform isn't supported (desktop), fallback to Supabase OAuth.
    final bool isMobileTarget =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobileTarget) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: const <String>['email', 'profile'],
          // On Android, idToken retrieval often requires a serverClientId (Web client id).
          serverClientId:
              _googleWebClientId.isEmpty ? null : _googleWebClientId,
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw const _GoogleAuthCanceled();
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        final String? accessToken = googleAuth.accessToken;

        if (idToken == null || idToken.trim().isEmpty) {
          // This typically means Google Sign-In isn't fully configured for the
          // current app (missing serverClientId / google-services.json).
          throw const _GoogleAuthMissingIdToken();
        }

        final AuthResponse authResponse = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        final User? user = authResponse.user;
        final Session? session = authResponse.session;
        if (user == null || session == null) {
          throw const AuthException('Google sign-in failed. Please try again.');
        }

        return _GoogleAuthResult(
          user: user,
          session: session,
          googleDisplayName: googleUser.displayName,
        );
      } on PlatformException {
        // Native Google Sign-In not available / not configured; fallback below.
      } on _GoogleAuthMissingIdToken {
        // Fallback below.
      }
    }

    return _signInSupabaseWithGoogleOAuth(client);
  }

  Future<_GoogleAuthResult> _signInSupabaseWithGoogleOAuth(
    SupabaseClient client,
  ) async {
    // Redirect-based flow (PKCE) - supported on web and desktop.
    final Completer<Session> sessionCompleter = Completer<Session>();
    late final StreamSubscription<AuthState> sub;

    sub = client.auth.onAuthStateChange.listen((event) {
      final Session? session = event.session;
      if (session != null && !sessionCompleter.isCompleted) {
        sessionCompleter.complete(session);
      }
    });

    try {
      final bool launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirectTo.trim().isEmpty ? null : _oauthRedirectTo,
        scopes: 'email profile',
      );

      if (!launched && !kIsWeb) {
        throw const AuthException('Could not open the browser for Google sign-in.');
      }

      final Session session = await sessionCompleter.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw const AuthException(
            'Google sign-in timed out. Please try again.',
          );
        },
      );

      final User? user = client.auth.currentUser;
      if (user == null) {
        throw const AuthException('Google sign-in failed. Please try again.');
      }

      return _GoogleAuthResult(
        user: user,
        session: session,
        googleDisplayName: user.userMetadata?['full_name'] as String?,
      );
    } finally {
      await sub.cancel();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class _GoogleAuthResult {
  const _GoogleAuthResult({
    required this.user,
    required this.session,
    required this.googleDisplayName,
  });

  final User user;
  final Session session;
  final String? googleDisplayName;
}

class _GoogleAuthCanceled implements Exception {
  const _GoogleAuthCanceled();
}

class _GoogleAuthMissingIdToken implements Exception {
  const _GoogleAuthMissingIdToken();
}

