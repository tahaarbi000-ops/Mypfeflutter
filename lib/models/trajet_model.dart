class TrajetModel {
  final String id;
  String depart;
  String destination;
  String region;
  String date; // may be empty if added from admin
  String heureDepart;
  String heureArrivee;
  double prix;
  String statut; // 'planifie', 'en_cours', 'termine', 'actif'
  String controleurId; // may be empty if not yet assigned
  int placesTotal;
  int placesRestantes;

  TrajetModel({
    required this.id,
    required this.depart,
    required this.destination,
    required this.region,
    required this.date,
    required this.heureDepart,
    required this.heureArrivee,
    required this.prix,
    required this.statut,
    required this.controleurId,
    required this.placesTotal,
    required this.placesRestantes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'depart': depart,
        'destination': destination,
        'region': region,
        'date': date,
        'heureDepart': heureDepart,
        'heureArrivee': heureArrivee,
        'prix': prix,
        'statut': statut,
        'controleurId': controleurId,
        'placesTotal': placesTotal,
        'placesRestantes': placesRestantes,
      };

  factory TrajetModel.fromMap(Map<String, dynamic> map) => TrajetModel(
        id: map['id'] as String? ?? '',
        depart: map['depart'] as String? ?? '',
        destination: map['destination'] as String? ?? '',
        region: map['region'] as String? ?? '',
        date: map['date'] as String? ?? '',
        heureDepart: map['heureDepart'] as String? ?? '',
        heureArrivee: map['heureArrivee'] as String? ?? '',
        prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
        statut: map['statut'] as String? ?? 'actif',
        controleurId: map['controleurId'] as String? ?? '',
        placesTotal: (map['placesTotal'] as num?)?.toInt() ?? 0,
        placesRestantes: (map['placesRestantes'] as num?)?.toInt() ?? 0,
      );
}

class TicketModel {
  final String id;
  final String trajetId;
  final String clientId;
  final String clientNom;
  String statut; // 'valide', 'utilise', 'expire'
  final String dateAchat;
  final double prix;
  bool scanne;

  TicketModel({
    required this.id,
    required this.trajetId,
    required this.clientId,
    required this.clientNom,
    required this.statut,
    required this.dateAchat,
    required this.prix,
    this.scanne = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'trajetId': trajetId,
        'clientId': clientId,
        'clientNom': clientNom,
        'statut': statut,
        'dateAchat': dateAchat,
        'prix': prix,
        'scanne': scanne,
      };

  factory TicketModel.fromMap(Map<String, dynamic> map) => TicketModel(
        id: map['id'] as String? ?? '',
        trajetId: map['trajetId'] as String? ?? '',
        clientId: map['clientId'] as String? ?? '',
        clientNom: map['clientNom'] as String? ?? '',
        statut: map['statut'] as String? ?? 'valide',
        dateAchat: map['dateAchat'] as String? ?? '',
        prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
        scanne: map['scanne'] as bool? ?? false,
      );
}
