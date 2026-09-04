class AppValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^\+?[0-9\s\-()]{7,18}$',
  );

  /// Validates required field
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Optional email (validates format only if entered)
  static String? validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates phone number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15 || !_phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number (7-15 digits)';
    }
    return null;
  }

  /// Optional phone
  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15 || !_phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validates price (must be positive > 0)
  static String? validatePrice(String? value, [String fieldName = 'Price']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than 0';
    }
    if (parsed > 100000000) {
      return '$fieldName exceeds allowable maximum';
    }
    return null;
  }

  /// Validates integer quantity (must be >= 1)
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1) {
      return 'Quantity must be at least 1';
    }
    if (parsed > 999999) {
      return 'Quantity is too large';
    }
    return null;
  }

  /// Validates discount against subtotal
  static String? validateDiscount(String? value, double subtotal) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid discount amount';
    }
    if (parsed < 0) {
      return 'Discount cannot be negative';
    }
    if (parsed > subtotal) {
      return 'Discount cannot exceed subtotal (${subtotal.toStringAsFixed(2)})';
    }
    return null;
  }

  /// Validates tax percentage (0% to 100%)
  static String? validateTaxRate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid tax percentage';
    }
    if (parsed < 0 || parsed > 100) {
      return 'Tax rate must be between 0% and 100%';
    }
    return null;
  }

  /// Validates password strength (min 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
