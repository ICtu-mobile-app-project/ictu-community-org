import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/theme/app_text_styles.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/app_top_bar.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';
import 'package:ictu_community_org/core/widgets/glass_input.dart';
import 'package:ictu_community_org/core/widgets/primary_button.dart';
import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/auth/screens/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const String _faculty = 'Engineering & Technology';
  static const List<String> _programs = <String>[
    'BSc ICT',
    'BSc CS',
    'BSc SEN',
    'BSc CYS',
    'BSc ISN',
    'BSc Renewable Energy',
    'BSc JMC',
  ];
  static const String _schoolDomain = '@ictuniversity.edu.cm';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  UserRole _selectedRole = UserRole.student;
  String _selectedProgram = _programs.first;
  int _selectedYearLevel = 1;

  bool _isSubmitting = false;
  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _isSubmitting = false;
        _errorText = 'Please fill in all fields.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _isSubmitting = false;
        _errorText = 'Passwords do not match.';
      });
      return;
    }

    final String normalizedEmail = _emailController.text.trim().toLowerCase();
    if (!normalizedEmail.endsWith(_schoolDomain)) {
      setState(() {
        _isSubmitting = false;
        _errorText =
            'Please register with your ICT University email ($_schoolDomain).';
      });
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final AuthFlowResponse response = await authController.signUp(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      faculty: _faculty,
      program: _selectedProgram,
      yearLevel: _selectedYearLevel,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!response.isSuccess) {
      setState(() {
        _errorText = response.message ??
            'Signup failed. Please check your information and try again.';
      });
      return;
    }

    final String successMessage = response.requiresEmailVerification
        ? 'Account created. Check your email to verify before login.'
        : 'Account created successfully. You can now login.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _onGoogleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-up is coming soon.')),
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
                          width: 92,
                          height: 92,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create your account',
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register with your ICTU email to get started.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      GlassInput(
                        label: 'Full name',
                        controller: _nameController,
                        icon: Icons.person_outline,
                        placeholder: 'e.g. Jane Nfor',
                      ),
                      const SizedBox(height: 16),
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
                        placeholder: 'Create a password',
                        suffix: IconButton(
                          onPressed: () {
                            setState(() => _passwordObscured = !_passwordObscured);
                          },
                          icon: Icon(
                            _passwordObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassInput(
                        label: 'Confirm password',
                        controller: _confirmPasswordController,
                        icon: Icons.lock_outline,
                        obscureText: _confirmPasswordObscured,
                        placeholder: 'Re-enter your password',
                        suffix: IconButton(
                          onPressed: () {
                            setState(() => _confirmPasswordObscured =
                                !_confirmPasswordObscured);
                          },
                          icon: Icon(
                            _confirmPasswordObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _GlassDropdown<UserRole>(
                        label: 'Role',
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.student,
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.delegateRole,
                            child: Text('Delegate'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.lecturer,
                            child: Text('Lecturer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedRole = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _GlassDropdown<String>(
                        label: 'Program',
                        value: _selectedProgram,
                        items: _programs
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedProgram = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _GlassDropdown<int>(
                        label: 'Year level',
                        value: _selectedYearLevel,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Year 1')),
                          DropdownMenuItem(value: 2, child: Text('Year 2')),
                          DropdownMenuItem(value: 3, child: Text('Year 3')),
                          DropdownMenuItem(value: 4, child: Text('Year 4')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedYearLevel = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Create account',
                        onTap: _onSignup,
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
                        onPressed: _onGoogleSignUp,
                        icon: const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 26,
                        ),
                        label: const Text('Sign up with Google'),
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
                          textStyle: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryContainer,
                          textStyle: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        child: const Text('Already have an account? Login'),
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

class _GlassDropdown<T> extends StatelessWidget {
  const _GlassDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelSm),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.surfaceContainer,
          style: AppTextStyles.bodyMd,
          iconEnabledColor: Colors.white70,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.25),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryContainer),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
