import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
