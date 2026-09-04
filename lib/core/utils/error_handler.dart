import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is PlatformException) {
      if (error.code == 'sign_in_failed' || error.message?.contains('10') == true) {
        return 'Google Sign-In requires SHA-1 registration in Firebase. Please sign in with Email or use Demo Access.';
      }
      if (error.code == 'sign_in_canceled' || error.code == '12501') {
        return 'Sign-in was cancelled.';
      }
      if (error.code == 'network_error' || error.code == '7') {
        return 'Network connection error during sign in.';
      }
      return error.message ?? 'Sign-in encountered a platform error.';
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

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Access denied. You do not have permission to perform this action.';
      }
      if (error.code == 'unavailable') {
        return 'The cloud service is temporarily unavailable. Local changes remain saved.';
      }
      return error.message ?? 'A database sync error occurred. Please try again.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please check your internet connection and try again.';
    }

    // Never leak raw exception strings or stack traces to the user
    debugPrint('Sanitized Internal App Error: $error');
    return 'An unexpected issue occurred. Please try again.';
  }
}
