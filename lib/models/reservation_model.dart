// lib/models/reservation_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String clientId;
  final String clientNom;
  final String trajetNom;
  final String ligne;
  final String depart;
  final String destination;
  final String heureAller;
  final String heureRetour;
  final double prix;
  final List<String> joursActifs;
  final String statut; // valide | utilise | annule
  final DateTime dateAchat;
  final String dateAchatStr;

  const ReservationModel({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.trajetNom,
    required this.ligne,
    required this.depart,
    required this.destination,
    required this.heureAller,
    required this.heureRetour,
    required this.prix,
    required this.joursActifs,
    required this.statut,
    required this.dateAchat,
    required this.dateAchatStr,
  });

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    // dateAchat peut être un Timestamp Firestore ou une String
    DateTime dateAchat;
    final raw = map['dateAchat'];
    if (raw is Timestamp) {
      dateAchat = raw.toDate();
    } else {
      dateAchat = DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    }

    return ReservationModel(
      id:           map['id'] as String? ?? '',
      clientId:     map['clientId'] as String? ?? '',
      clientNom:    map['clientNom'] as String? ?? '',
      trajetNom:    map['trajetNom'] as String? ?? '',
      ligne:        map['ligne'] as String? ?? '',
      depart:       map['depart'] as String? ?? '',
      destination:  map['destination'] as String? ?? '',
      heureAller:   map['heureAller'] as String? ?? '',
      heureRetour:  map['heureRetour'] as String? ?? '',
      prix:         (map['prix'] as num?)?.toDouble() ?? 0.0,
      joursActifs:  List<String>.from(map['joursActifs'] as List? ?? []),
      statut:       map['statut'] as String? ?? 'valide',
      dateAchat:    dateAchat,
      dateAchatStr: map['dateAchatStr'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id':           id,
    'clientId':     clientId,
    'clientNom':    clientNom,
    'trajetNom':    trajetNom,
    'ligne':        ligne,
    'depart':       depart,
    'destination':  destination,
    'heureAller':   heureAller,
    'heureRetour':  heureRetour,
    'prix':         prix,
    'joursActifs':  joursActifs,
    'statut':       statut,
    'dateAchat':    Timestamp.fromDate(dateAchat),
    'dateAchatStr': dateAchatStr,
  };
}