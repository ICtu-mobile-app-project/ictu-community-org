import 'package:flutter/foundation.dart';

class AuthController {
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  Future<void> signIn({required String email, required String password}) async {
    // Placeholder auth logic for UI workflow.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    isLoggedIn.value = email.isNotEmpty && password.isNotEmpty;
  }

  void dispose() {
    isLoggedIn.dispose();
  }
}
