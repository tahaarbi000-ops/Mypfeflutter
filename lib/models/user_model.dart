class UserModel {
  final String id;
  String nom;
  String prenom;
  String email;
  String telephone;
  String role; // 'client' or 'controleur'
  String? photoUrl;
  String? societe;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    this.photoUrl,
    this.societe,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'role': role,
        'photoUrl': photoUrl,
        'societe': societe,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String? ?? '',
        nom: map['nom'] as String? ?? '',
        prenom: map['prenom'] as String? ?? '',
        email: map['email'] as String? ?? '',
        telephone: map['telephone'] as String? ?? '',
        role: map['role'] as String? ?? 'client',
        photoUrl: map['photoUrl'] as String?,
        societe: map['societe'] as String?,
      );
}
