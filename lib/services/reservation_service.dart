// lib/services/reservation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── CRÉER ────────────────────────────────────────────────────────────────

  /// Crée une réservation dans Firestore.
  /// Retourne le ticketId (UUID) utilisé pour le QR code.
  Future<String> creerReservation({
    required String clientId,
    required String clientNom,
    required String trajetNom,
    required String ligne,
    required String depart,
    required String destination,
    required String heureAller,
    required String heureRetour,
    required double prix,
    required List<String> joursActifs,
    required DateTime dateVoyage,
  }) async {
    final ticketId = _uuid.v4();
    final now = DateTime.now();

    final data = {
      'id': ticketId,
      'clientId': clientId,
      'clientNom': clientNom,
      'trajetNom': trajetNom,
      'ligne': ligne,
      'depart': depart,
      'destination': destination,
      'heureAller': heureAller,
      'heureRetour': heureRetour,
      'prix': prix,
      'joursActifs': joursActifs,
      'statut': 'valide',
      'dateAchat': Timestamp.fromDate(now),
      'dateAchatStr': '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year}',
      'dateVoyage': Timestamp.fromDate(dateVoyage),
    };

    await _db.collection('reservations').doc(ticketId).set(data);
    return ticketId;
  }

  // ─── LIRE ─────────────────────────────────────────────────────────────────

  /// Stream des réservations d'un client — triées par date décroissante (Dart, pas orderBy)
  Stream<List<ReservationModel>> reservationsClient(String clientId) {
    return _db
        .collection('reservations')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) {
        return ReservationModel.fromMap({...d.data(), 'id': d.id});
      }).toList();
      // Tri côté Dart — évite le composite index mobile Firestore
      list.sort((a, b) => b.dateAchat.compareTo(a.dateAchat));
      return list;
    });
  }

  /// Récupère une réservation par son id
  Future<ReservationModel?> getReservation(String ticketId) async {
    final doc = await _db.collection('reservations').doc(ticketId).get();
    if (!doc.exists) return null;
    return ReservationModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  // ─── METTRE À JOUR ────────────────────────────────────────────────────────

  /// Marque un ticket comme utilisé (appelé par le contrôleur au scan)
  Future<void> utiliserTicket(String ticketId) async {
    await _db
        .collection('reservations')
        .doc(ticketId)
        .update({'statut': 'utilise'});
  }

  /// Annule une réservation
  Future<void> annulerReservation(String ticketId) async {
    await _db
        .collection('reservations')
        .doc(ticketId)
        .update({'statut': 'annule'});
  }
}
