import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart' show PlatformException;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );
        return userCredential.user;
      } else {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return (await _auth.signInWithCredential(credential)).user;
      }
    } on PlatformException catch (error) {
      debugPrint('Google sign-in failed: ${error.code} ${error.message}');
      rethrow;
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase Google sign-in failed: ${error.code} ${error.message}',
      );
      rethrow;
    }
  }

  // EMAIL/PASSWORD REGISTER
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  // EMAIL/PASSWORD LOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // FORGOT PASSWORD (NEW)
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to send reset email.";
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();
}
