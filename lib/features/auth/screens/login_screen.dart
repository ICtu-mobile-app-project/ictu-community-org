import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/auth/screens/signup_screen.dart';
import 'package:ictu_community_org/features/home/screens/lecturer_dashboard_screen.dart';
import 'package:ictu_community_org/features/navigation/screens/main_shell.dart';

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double sx = constraints.maxWidth / 425;
          final double sy = constraints.maxHeight / 884;

          return Stack(
            children: [
              Container(color: isDark ? const Color(0xFF000205) : Colors.white),
              _MovingCircle(
                color: isDark
                    ? const Color(0xFF600063).withValues(alpha: 0.43)
                    : const Color(0xFFF39200),
                size: Size(193 * sx, 175 * sy),
              ),
              _MovingCircle(
                color: const Color(0xFF010F46).withValues(alpha: 0.43),
                size: Size(183 * sx, 189 * sy),
              ),
              _MovingCircle(
                color: const Color(0x6EFFC94A).withValues(alpha: 0.43),
                size: Size(207 * sx, 206 * sy),
              ),
              if (!isDark)
                _MovingCircle(
                  color: const Color(0xFFF39200),
                  size: Size(95 * sx, 88 * sy),
                ),
              Positioned.fill(
                child: Container(
                  color: isDark
                      ? const Color(0x42000000)
                      : const Color(0x42FFFFFF),
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 42 * sx),
                  child: Column(
                    children: [
                      SizedBox(height: 170 * sy),
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          34 * sx,
                          18 * sy,
                          34 * sx,
                          26 * sy,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          gradient: const LinearGradient(
                            begin: Alignment(-0.95, -0.95),
                            end: Alignment(1, 1),
                            colors: [Color(0x33D9D9D9), Color(0x334F4E4E)],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/Logo.png',
                              width: 136 * sx,
                              height: 152 * sy,
                            ),
                            const SizedBox(height: 8),
                            const _GradientText(
                              'ICTU COMMUNITY',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const _GradientText(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 30 * sy),
                            _LabeledInput(
                              label: 'Email Address',
                              isDark: isDark,
                              controller: _emailController,
                            ),
                            SizedBox(height: 14 * sy),
                            _LabeledInput(
                              label: 'Password',
                              isDark: isDark,
                              controller: _passwordController,
                              obscureText: true,
                              showVisibilityToggle: true,
                            ),
                            SizedBox(height: 18 * sy),
                            SizedBox(
                              width: 222 * sx,
                              height: 37 * sy,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(54),
                                  gradient: const LinearGradient(
                                    colors: [Color(0x91D49100), Color(0x9114154C)],
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(54),
                                    onTap: _isSubmitting ? null : _onLogin,
                                    child: Center(
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 32,
                                                height: 1,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 6.4,
                                                    offset: Offset(0, 4),
                                                    color: Color(0x40000000),
                                                  ),
                                                  Shadow(
                                                    blurRadius: 4,
                                                    offset: Offset(0, 4),
                                                    color: Color(0x40000000),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_errorText != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 10),
                            _GoogleAuthButton(
                              label: 'Sign in with Google',
                              onTap: _onGoogleSignIn,
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
                              child: Text(
                                'Need an account? Sign Up',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFA6FFB6)
                                      : const Color(0xFF334155),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 50 * sy),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 51 * sy,
                left: 14 * sx,
                child: Container(
                  width: 42 * sx,
                  height: 41 * sy,
                  decoration: const BoxDecoration(
                    color: Color(0x6ED9D9D9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10 * sy,
                child: Center(
                  child: Container(
                    width: 128 * sx,
                    height: 6 * sy,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LabeledInput extends StatefulWidget {
  const _LabeledInput({
    required this.controller,
    required this.label,
    required this.isDark,
    this.obscureText = false,
    this.showVisibilityToggle = false,
  });

  final TextEditingController controller;
  final String label;
  final bool isDark;
  final bool obscureText;
  final bool showVisibilityToggle;

  @override
  State<_LabeledInput> createState() => _LabeledInputState();
}

class _LabeledInputState extends State<_LabeledInput> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            color: widget.isDark ? Colors.white : Colors.black,
            fontFamily: 'Kode Mono',
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: TextField(
            controller: widget.controller,
            obscureText: _obscured,
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: const Color(0x82D9D9D9),
              suffixIcon: widget.showVisibilityToggle
                  ? IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscured = !_obscured;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFF59E0B),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleAuthButton extends StatelessWidget {
  const _GoogleAuthButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _CircleDecor extends StatelessWidget {
  const _CircleDecor({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MovingCircle extends StatefulWidget {
  const _MovingCircle({required this.color, required this.size});
  final Color color;
  final Size size;

  @override
  State<_MovingCircle> createState() => _MovingCircleState();
}

class _MovingCircleState extends State<_MovingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  late Alignment _startAlignment;
  late Alignment _endAlignment;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pickNewOffsets();
          _controller.forward(from: 0);
        }
      });

    _startAlignment = _randomAlignment();
    _endAlignment = _randomAlignment();
    _animation =
        AlignmentTween(begin: _startAlignment, end: _endAlignment).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  Alignment _randomAlignment() {
    return Alignment(
      _random.nextDouble() * 2 - 1,
      _random.nextDouble() * 2 - 1,
    );
  }

  void _pickNewOffsets() {
    if (mounted) {
      setState(() {
        _startAlignment = _endAlignment;
        _endAlignment = _randomAlignment();
        _animation =
            AlignmentTween(begin: _startAlignment, end: _endAlignment).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Align(
            alignment: _animation.value,
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: child,
            ),
          );
        },
        child: _CircleDecor(color: widget.color),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) => const LinearGradient(
        colors: [Color(0xFFA6FFB6), Color(0xFF636999)],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}


