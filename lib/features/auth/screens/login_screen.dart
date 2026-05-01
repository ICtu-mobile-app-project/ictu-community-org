import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/theme/app_text_styles.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/navigation/app_routes.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';
import 'package:ictu_community_org/core/widgets/glass_input.dart';
import 'package:ictu_community_org/core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  final UserRole? initialRole;
  const LoginScreen({super.key, this.initialRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _schoolDomain = '@ictuniversity.edu.cm';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _passwordObscured = true;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final String normalizedEmail = _emailController.text.trim().toLowerCase();
    if (!normalizedEmail.endsWith(_schoolDomain)) {
      setState(() {
        _errorText =
            'Please login with your ICT University email (@ictuniversity.edu.cm).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final AuthFlowResponse response = await authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!response.isSuccess) {
      setState(() {
        _errorText = response.message ?? 'Login failed. Please try again.';
      });
      return;
    }

    final UserRole resolvedRole = response.role ?? UserRole.student;

    if (resolvedRole == UserRole.lecturer) {
      context.goNamed(AppRoutes.lecturerHome);
      return;
    }

    context.goNamed(
      AppRoutes.appShell,
      pathParameters: <String, String>{'role': resolvedRole.dbValue},
    );
  }

  void _onGoogleSignIn() {
    _signInWithGoogle();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleSubmitting = true;
      _errorText = null;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final AuthFlowResponse response = await authController.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isGoogleSubmitting = false;
    });

    if (!response.isSuccess) {
      setState(() {
        _errorText = response.message ?? 'Google sign-in failed. Please try again.';
      });
      return;
    }

    final UserRole resolvedRole = response.role ?? UserRole.student;

    if (resolvedRole == UserRole.lecturer) {
      context.goNamed(AppRoutes.lecturerHome);
      return;
    }

    context.goNamed(
      AppRoutes.appShell,
      pathParameters: <String, String>{'role': resolvedRole.dbValue},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 52,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back, color: Colors.white70),
                            ),
                          ),
                          Center(
                            child: Text(
                              'ICTU COMMUNITY',
                              style: AppTextStyles.h2.copyWith(
                                fontSize: 16,
                                letterSpacing: 3,
                                color: AppColors.primaryContainer,
                                shadows: [
                                  Shadow(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.55),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/Logo.png',
                              width: 96,
                              height: 96,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.initialRole == UserRole.lecturer
                                ? 'Staff Portal Login'
                                : 'Sign in to your account',
                            style: AppTextStyles.h1,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.initialRole == UserRole.lecturer
                                ? 'Access your staff dashboard and tools.'
                                : 'Use your ICTU email and password to continue.',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          GlassInput(
                            label: 'Email address',
                            controller: _emailController,
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            placeholder: 'name$_schoolDomain',
                          ),
                          const SizedBox(height: 16),
                          GlassInput(
                            label: 'Password',
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            obscureText: _passwordObscured,
                            placeholder: 'Enter your password',
                            suffix: IconButton(
                              onPressed: () {
                                setState(() => _passwordObscured = !_passwordObscured);
                              },
                              icon: Icon(
                                _passwordObscured ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white54,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: 'Login',
                            onTap: (_isSubmitting || _isGoogleSubmitting) ? null : _onLogin,
                            isLoading: _isSubmitting,
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorText!,
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.error,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: (_isSubmitting || _isGoogleSubmitting)
                                ? null
                                : _onGoogleSignIn,
                            icon: _isGoogleSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.g_mobiledata_rounded, size: 26),
                            label: const Text('Sign in with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              final UserRole targetRole =
                                  widget.initialRole ?? UserRole.student;
                              context.goNamed(
                                AppRoutes.signup,
                                pathParameters: <String, String>{
                                  'role': targetRole.dbValue,
                                },
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryContainer,
                              textStyle: AppTextStyles.labelSm.copyWith(
                                color: AppColors.primaryContainer,
                              ),
                            ),
                            child: const Text('Need an account? Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

