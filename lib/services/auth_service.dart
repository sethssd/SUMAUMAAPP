import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern (optional, but good for services)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<String> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AppConstants.roleSemCargo;
      }

      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()![AppConstants.fieldRole] ?? AppConstants.roleSemCargo;
      } else {
        return AppConstants.roleSemCargo;
      }
    } catch (e) {
      return AppConstants.statusErro;
    }
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 0. A versão 7 exigiu inicialização explícita
      await GoogleSignIn.instance.initialize();

      // 1. Força o usuário a escolher a conta do Google no celular (v7 usa authenticate)
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      // 2. Obtém os detalhes de autenticação do Google (v7 é síncrono e não tem access_token fácil)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 3. Loga no Firebase Auth
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User user = userCredential.user!;

      // 4. Salva no banco de dados (Firestore) se for a primeira vez
      final docRef = _firestore.collection(AppConstants.collectionUsers).doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'nome': user.displayName ?? '',
          'foto': user.photoURL ?? '',
          'role': AppConstants.roleUsuario, // Padrão é leigo.
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      // Ignorando warnings do print em production apenas para logs simples
      // ignore: avoid_print
      print("Erro no Google Sign-In: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
