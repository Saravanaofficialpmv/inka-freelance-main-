import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'Invalid email or password. Please try again or create an account.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'weak-password':
          return 'The password provided is too weak.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    return error.toString();
  }
}
