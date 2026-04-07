import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const String _emailRedirectTo = String.fromEnvironment(
    'SUPABASE_EMAIL_REDIRECT_TO',
  );
  static const String _schoolDomain = '@ictuniversity.edu.cm';

  AuthController() {
    _authSubscription = _client?.auth.onAuthStateChange.listen((event) {
      isLoggedIn.value = event.session != null;
    });
  }

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
        message: 'Use your ICT University email ending with @ictuniversity.edu.cm.',
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
      activeRole.value = resolvedRole;
      isLoggedIn.value = true;

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

    if (!_isEmailAllowedForRole(email: normalizedEmail)) {
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
      isLoggedIn.value = false;
      activeRole.value = null;
      return null;
    }

    final UserRole role = await _fetchRole(currentUser.id);
    activeRole.value = role;
    isLoggedIn.value = true;
    return role;
  }

  Future<void> signOut() async {
    final SupabaseClient? client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
    isLoggedIn.value = false;
    activeRole.value = null;
  }

  Future<UserRole> _fetchRole(String userId) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return UserRole.student;
    }

    try {
      final Map<String, dynamic>? profile = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        return UserRole.fromDb(profile['role'] as String?);
      }

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

        if (bootstrapResponse.status < 400 &&
            bootstrapResponse.data is Map<String, dynamic>) {
          final Map<String, dynamic> data =
              bootstrapResponse.data as Map<String, dynamic>;
          final String? roleValue = data['role'] as String?;
          if (roleValue != null && roleValue.trim().isNotEmpty) {
            return UserRole.fromDb(roleValue);
          }
        }
      }


      final User? currentUser = client.auth.currentUser;
      final String? metadataRole = currentUser?.userMetadata?['role'] as String?;
      return UserRole.fromDb(metadataRole);
    } catch (_) {
      return UserRole.student;
    }
  }

  bool _isSchoolEmail(String email) {
    final String value = email.toLowerCase();
    return value.endsWith(_schoolDomain);
  }

  bool _isEmailAllowedForRole({required String email}) {
    return _isSchoolEmail(email);
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

  void dispose() {
    _authSubscription?.cancel();
    isLoggedIn.dispose();
    activeRole.dispose();
  }
}
