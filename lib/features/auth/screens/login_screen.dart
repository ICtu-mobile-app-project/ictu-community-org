import 'package:flutter/material.dart';

import '../../navigation/screens/main_shell.dart';
import '../controllers/auth_controller.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    await _authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || !_authController.isLoggedIn.value) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
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
              Positioned(
                left: 272 * sx,
                top: 695 * sy,
                width: 193 * sx,
                height: 175 * sy,
                child: _CircleDecor(
                  color: isDark
                      ? const Color(0xFF600063).withValues(alpha: 0.43)
                      : const Color(0xFFF39200),
                ),
              ),
              Positioned(
                left: -54 * sx,
                top: 339 * sy,
                width: 183 * sx,
                height: 189 * sy,
                child: _CircleDecor(
                  color: const Color(0xFF010F46).withValues(alpha: 0.43),
                ),
              ),
              Positioned(
                left: 179 * sx,
                top: 72 * sy,
                width: 207 * sx,
                height: 206 * sy,
                child: _CircleDecor(
                  color: const Color(0x6EFFC94A).withValues(alpha: 0.43),
                ),
              ),
              if (!isDark)
                Positioned(
                  left: 291 * sx,
                  top: 183 * sy,
                  width: 95 * sx,
                  height: 88 * sy,
                  child: const _CircleDecor(color: Color(0xFFF39200)),
                ),
              Positioned.fill(
                child: Container(
                  color: isDark
                      ? const Color(0x42000000)
                      : const Color(0x42FFFFFF),
                ),
              ),
              Positioned(
                left: 42 * sx,
                top: 227 * sy,
                width: 344 * sx,
                child: Container(
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
                              onTap: _onLogin,
                              child: const Center(
                                child: Text(
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

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.controller,
    required this.label,
    required this.isDark,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final bool isDark;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Kode Mono',
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
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
