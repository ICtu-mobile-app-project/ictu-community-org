import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/auth/screens/signup_screen.dart';
import 'package:ictu_community_org/features/home/screens/lecturer_dashboard_screen.dart';
import 'package:ictu_community_org/features/navigation/screens/main_shell.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/theme/app_text_styles.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/app_top_bar.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';
import 'package:ictu_community_org/core/widgets/glass_input.dart';
import 'package:ictu_community_org/core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _schoolDomain = '@ictuniversity.edu.cm';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LecturerDashboardScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MainShell(userRole: resolvedRole),
      ),
    );
  }

  void _onGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: const AppTopBar(showBack: true),
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassCard(
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
                        'Sign in to your account',
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use your ICTU email and password to continue.',
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
                        onTap: _onLogin,
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
                        onPressed: _onGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                        label: const Text('Sign in with Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const SignupScreen(),
                            ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

