class UserModel {
  final String id;
  String nom;
  String prenom;
  String email;
  String telephone;
  String role; // 'client' or 'controleur'
  String? photoUrl;
  String motDePasse;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.motDePasse,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'telephone': telephone,
    'role': role,
    'motDePasse': motDePasse,
    'photoUrl': photoUrl,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    nom: map['nom'],
    prenom: map['prenom'],
    email: map['email'],
    telephone: map['telephone'],
    role: map['role'],
    motDePasse: map['motDePasse'],
    photoUrl: map['photoUrl'],
  );
}
