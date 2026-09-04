import 'package:flutter_test/flutter_test.dart';
import 'package:inka/core/utils/validators.dart';
import 'package:inka/core/utils/error_handler.dart';

void main() {
  group('AppValidators Tests', () {
    test('Email validation checks correctly', () {
      expect(AppValidators.validateEmail(null), 'Email address is required');
      expect(AppValidators.validateEmail(''), 'Email address is required');
      expect(AppValidators.validateEmail('invalid-email'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('user@'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('user@example.com'), isNull);
    });

    test('Phone validation checks 7-15 digits correctly', () {
      expect(AppValidators.validatePhone(null), 'Phone number is required');
      expect(AppValidators.validatePhone('123'), 'Please enter a valid phone number (7-15 digits)');
      expect(AppValidators.validatePhone('+1 234 567 8900'), isNull);
      expect(AppValidators.validatePhone('9876543210'), isNull);
    });

    test('Price validation checks positive bounds', () {
      expect(AppValidators.validatePrice(null), 'Price is required');
      expect(AppValidators.validatePrice('0'), 'Price must be greater than 0');
      expect(AppValidators.validatePrice('-25.5'), 'Price must be greater than 0');
      expect(AppValidators.validatePrice('abc'), 'Please enter a valid number');
      expect(AppValidators.validatePrice('49.99'), isNull);
    });

    test('Quantity validation requires >= 1', () {
      expect(AppValidators.validateQuantity(null), 'Quantity is required');
      expect(AppValidators.validateQuantity('0'), 'Quantity must be at least 1');
      expect(AppValidators.validateQuantity('-1'), 'Quantity must be at least 1');
      expect(AppValidators.validateQuantity('5'), isNull);
    });

    test('Discount validation clamps against subtotal', () {
      expect(AppValidators.validateDiscount('-5', 100.0), 'Discount cannot be negative');
      expect(AppValidators.validateDiscount('150', 100.0), 'Discount cannot exceed subtotal (100.00)');
      expect(AppValidators.validateDiscount('50', 100.0), isNull);
      expect(AppValidators.validateDiscount('', 100.0), isNull);
    });

    test('Tax rate validation limits to 0-100%', () {
      expect(AppValidators.validateTaxRate('-1'), 'Tax rate must be between 0% and 100%');
      expect(AppValidators.validateTaxRate('101'), 'Tax rate must be between 0% and 100%');
      expect(AppValidators.validateTaxRate('18'), isNull);
    });
  });

  group('ErrorHandler Stack Masking Tests', () {
    test('Does not leak raw internal exception string or stack trace', () {
      final genericException = Exception('Internal database connection pool timeout at line 429');
      final message = ErrorHandler.getErrorMessage(genericException);
      expect(message, 'An unexpected issue occurred. Please try again.');
      expect(message.contains('line 429'), isFalse);
    });
  });
}
