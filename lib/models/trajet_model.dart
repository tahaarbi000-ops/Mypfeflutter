class TrajetModel {
  final String id;
  String depart;
  String destination;
  String region;
  String date;
  String heureDepart;
  String heureArrivee;
  double prix;
  String statut; // 'planifie', 'en_cours', 'termine'
  String controleurId;
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
    id: map['id'],
    depart: map['depart'],
    destination: map['destination'],
    region: map['region'],
    date: map['date'],
    heureDepart: map['heureDepart'],
    heureArrivee: map['heureArrivee'],
    prix: (map['prix'] as num).toDouble(),
    statut: map['statut'],
    controleurId: map['controleurId'],
    placesTotal: map['placesTotal'],
    placesRestantes: map['placesRestantes'],
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
    id: map['id'],
    trajetId: map['trajetId'],
    clientId: map['clientId'],
    clientNom: map['clientNom'],
    statut: map['statut'],
    dateAchat: map['dateAchat'],
    prix: (map['prix'] as num).toDouble(),
    scanne: map['scanne'] ?? false,
  );
}
