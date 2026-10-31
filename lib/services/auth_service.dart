import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'An unknown error occurred. Please try again.';
    }
  }

  // Register with email and password
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'An unknown error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('SignOut Error: $e');
    }
  }

  // Password Reset
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      debugPrint('ResetPassword Error: $e');
      return 'Failed to send password reset email: $e';
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'user-disabled':
        return 'This user has been disabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please likely bad formatting.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
