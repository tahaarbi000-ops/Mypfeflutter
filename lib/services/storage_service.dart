import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Sélectionne une image depuis la galerie et l'upload dans Firebase Storage
  /// Retourne l'URL de téléchargement ou null en cas d'annulation
  Future<String?> pickAndUploadProfilePhoto(String userId) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return null;

      return await uploadProfilePhoto(userId, File(picked.path));
    } catch (e) {
      throw 'Impossible de sélectionner la photo : $e';
    }
  }

  /// Upload direct d'un fichier
  Future<String> uploadProfilePhoto(String userId, File file) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw 'Erreur lors de l\'upload : $e';
    }
  }

  /// Supprime la photo de profil
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      await _storage.ref().child('profile_photos/$userId.jpg').delete();
    } catch (_) {
      // Fichier inexistant, on ignore
    }
  }

  /// Retourne l'URL de la photo de profil (ou null)
  Future<String?> getProfilePhotoUrl(String userId) async {
    try {
      return await _storage.ref().child('profile_photos/$userId.jpg').getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
