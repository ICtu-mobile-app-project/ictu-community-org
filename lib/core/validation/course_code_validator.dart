class CourseCodeValidator {
  static final RegExp _codePattern = RegExp(r'^[A-Z]{3}\d{4}$');

  static String formatTyped(String input) {
    final String cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final String normalized = cleaned.toUpperCase();
    if (normalized.length <= 7) {
      return normalized;
    }
    return normalized.substring(0, 7);
  }

  static bool isValid(String value) {
    return _codePattern.hasMatch(value.trim().toUpperCase());
  }

  static String? validate(String? value) {
    final String code = (value ?? '').trim().toUpperCase();
    if (code.isEmpty) {
      return 'Course code is required';
    }
    if (!isValid(code)) {
      return 'Use format XXX#### (e.g., CSC3141)';
    }
    return null;
  }
}
