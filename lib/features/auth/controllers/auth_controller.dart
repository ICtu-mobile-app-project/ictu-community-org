import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

class AuthController {
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

  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  final ValueNotifier<UserRole?> activeRole = ValueNotifier<UserRole?>(null);

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

    try {
      // Primary source of truth for routing is profiles.role.
      final Map<String, dynamic>? profile = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      if (profile != null) {
        final String? roleValue = profile['role'] as String?;
        if (roleValue != null && roleValue.trim().isNotEmpty) {
          return UserRole.fromDb(roleValue);
        }
      }

      // Fallback to bootstrap function if profile row is missing/empty.
      final Session? session = client.auth.currentSession;
      if (session != null) {
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
      }

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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
