import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw FirebaseAuthException(
          code: 'google-token-missing',
          message:
              'Google Sign-In did not return tokens. Check Android SHA-1/SHA-256 in Firebase project settings.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      return _firebaseAuth.signInWithCredential(credential);
    } on PlatformException catch (error) {
      throw FirebaseAuthException(
        code: error.code,
        message: error.message ??
            'Google sign-in failed. Verify SHA-1/SHA-256 and OAuth config in Firebase.',
      );
    }
  }

  Future<UserCredential> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-unsupported',
        message:
            'Apple Sign-In in Flutter is only configured for iOS/macOS in this app.',
      );
    }

    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-unavailable',
        message: 'Apple Sign-In is not available on this device.',
      );
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256OfString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
      nonce: nonce,
    );

    if (appleCredential.identityToken == null) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-failed',
        message: 'Apple Sign-In did not return an identity token.',
      );
    }

    final oauthCredential = AppleAuthProvider.credentialWithIDToken(
      appleCredential.identityToken!,
      rawNonce,
      AppleFullPersonName(
        givenName: appleCredential.givenName,
        familyName: appleCredential.familyName,
      ),
    );
    return _firebaseAuth.signInWithCredential(oauthCredential);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
