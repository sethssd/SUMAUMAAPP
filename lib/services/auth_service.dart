import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ── HELPERS ───────────────────────────────────────────────

  /// Garante que o usuário tenha um documento na coleção `users`.
  /// Deve ser chamado logo após qualquer método de login/cadastro social.
  Future<void> _ensureUserDocument(User user, {String? firstName, String? lastName}) async {
    final docRef = _firestore.collection(AppConstants.collectionUsers).doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      final nome = (firstName != null && lastName != null)
          ? '$firstName $lastName'.trim()
          : (user.displayName ?? user.email?.split('@').first ?? '');
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'nome': nome,
        'foto': user.photoURL ?? '',
        'role': AppConstants.roleUsuario,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── ROLE ──────────────────────────────────────────────────

  Future<String> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AppConstants.roleSemCargo;

      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()![AppConstants.fieldRole] ?? AppConstants.roleSemCargo;
      }
      return AppConstants.roleSemCargo;
    } catch (_) {
      return AppConstants.statusErro;
    }
  }

  String? getCurrentUserId() => _auth.currentUser?.uid;

  // ── EMAIL / SENHA ─────────────────────────────────────────

  /// Cria conta com e-mail e senha.
  /// Grava o documento em `users` com os nomes fornecidos e role "usuario".
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      final fullName = '$firstName $lastName'.trim();
      await user.updateDisplayName(fullName);
      await _ensureUserDocument(user, firstName: firstName, lastName: lastName);
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Erro no cadastro por e-mail: $e');
      return null;
    }
  }

  /// Login com e-mail e senha.
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Garante documento para contas criadas diretamente no Firebase Console
      await _ensureUserDocument(credential.user!);
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Erro no login por e-mail: $e');
      return null;
    }
  }

  // ── GOOGLE ────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _ensureUserDocument(userCredential.user!);
      return userCredential;
    } catch (e) {
      debugPrint('Erro no Google Sign-In: $e');
      return null;
    }
  }

  // ── APPLE ─────────────────────────────────────────────────

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Apple só fornece o nome na PRIMEIRA vez
      final firstName = appleCredential.givenName ?? '';
      final lastName = appleCredential.familyName ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        await user.updateDisplayName('$firstName $lastName'.trim());
      }

      await _ensureUserDocument(user, firstName: firstName, lastName: lastName);
      return userCredential;
    } catch (e) {
      debugPrint('Erro no Apple Sign-In: $e');
      return null;
    }
  }

  // ── FACEBOOK ──────────────────────────────────────────────

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        debugPrint('Facebook login cancelado ou falhou: ${result.status}');
        return null;
      }

      final facebookCredential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(facebookCredential);
      await _ensureUserDocument(userCredential.user!);
      return userCredential;
    } catch (e) {
      debugPrint('Erro no Facebook Sign-In: $e');
      return null;
    }
  }

  // ── SIGN OUT ──────────────────────────────────────────────

  Future<void> signOut() async {
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}
    try { await FacebookAuth.instance.logOut(); } catch (_) {}
    await _auth.signOut();
  }
}
