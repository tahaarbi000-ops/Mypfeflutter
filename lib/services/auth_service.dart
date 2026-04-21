import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream de l'utilisateur connecté
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // Connexion
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _getUserModel(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Inscription
  Future<UserModel> signUp({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
    required String role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName('$prenom $nom');

      final user = UserModel(
        id: cred.user!.uid,
        nom: nom,
        prenom: prenom,
        email: email.trim(),
        telephone: telephone,
        role: role,
        photoUrl: null,
        motDePasse: password,
      );

      await _db.collection('users').doc(user.id).set(user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Déconnexion
  Future<void> signOut() => _auth.signOut();

  // Récupérer le profil Firestore
  Future<UserModel?> _getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap({...doc.data()!, 'id': uid});
  }

  Future<UserModel?> getUserById(String uid) => _getUserModel(uid);

  // Mettre à jour le mot de passe
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // Réinitialiser mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Traduction des erreurs Firebase Auth
  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}
