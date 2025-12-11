class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? validateSignupPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 10) return 'Must be at least 10 characters';
    if (!value.contains(RegExp(r'[A-Za-z]'))) return 'Must contain at least one letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain at least one number';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Must contain at least one symbol';
    return null;
  }
}