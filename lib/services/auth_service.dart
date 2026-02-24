// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  UserModel? _userModel;

  User? get user => _user;
  UserModel? get userModel => _userModel;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _userModel = null;
    } else {
      _user = firebaseUser;
      await _loadUserData(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      } else {
        await _createUserInFirestore(_user!);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _createUserInFirestore(User user) async {
    final UserModel newUser = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? 'مستخدم',
      phone: null,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
    _userModel = newUser;
  }

  // ========== EMAIL/PASSWORD ==========
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        name: name,
        phone: phone,
        photoUrl: null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());

      await result.user!.updateDisplayName(name);

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return _getLocalizedString('unexpectedError');
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return _getLocalizedString('unexpectedError');
    }
  }

  // ========== GOOGLE SIGN-IN ==========
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return _getLocalizedString('googleSignInCancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return '${_getLocalizedString('googleSignInError')}: $e';
    }
  }

  // ========== APPLE SIGN-IN ==========
  Future<String?> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return _getLocalizedString('appleSignInNotAvailable');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.example.missingApp.service',
          redirectUri: Uri.parse(
            'https://missing-app-2026.firebaseapp.com/__/auth/handler',
          ),
        ),
      );

      final credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _auth.signInWithCredential(credential);

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return '${_getLocalizedString('appleSignInError')}: $e';
    }
  }

  // ========== LOGOUT ==========
  Future<void> signOut() async {
    print('🚪 [AuthService] بدء تسجيل الخروج');

    try {
      await _googleSignIn.signOut();
      print('✅ [AuthService] تم تسجيل الخروج من Google');
    } catch (e) {
      print('⚠️ [AuthService] خطأ في تسجيل الخروج من Google: $e');
    }

    await _auth.signOut();
    print('✅ [AuthService] تم تسجيل الخروج من Firebase');
  }

  // ========== RELOAD USER DATA ==========
  Future<void> reloadUser() async {
    if (_user != null) {
      await _loadUserData(_user!.uid);
    }
  }

  // ========== دالة مساعدة للحصول على النصوص المترجمة ==========
  String _getLocalizedString(String key) {
    // هذه دالة مساعدة، سيتم استبدالها بالنص الفعلي من التطبيق
    // عند استخدامها في الشاشات، سنمرر context
    return key;
  }

  // ========== ERROR HANDLER ==========
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return _getLocalizedString('weakPassword');
      case 'email-already-in-use':
        return _getLocalizedString('emailAlreadyInUse');
      case 'invalid-email':
        return _getLocalizedString('invalidEmail');
      case 'user-not-found':
        return _getLocalizedString('userNotFound');
      case 'wrong-password':
        return _getLocalizedString('wrongPassword');
      case 'account-exists-with-different-credential':
        return _getLocalizedString('accountExistsWithDifferentCredential');
      case 'invalid-credential':
        return _getLocalizedString('invalidCredential');
      default:
        return '${_getLocalizedString('error')}: ${e.message}';
    }
  }
}