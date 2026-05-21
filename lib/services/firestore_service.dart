import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/trajet_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── COLLECTIONS ────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _trajets => _db.collection('trajets');
  CollectionReference get _tickets => _db.collection('tickets');

  // ─── USERS ──────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) =>
      _users.doc(user.id).set(user.toMap());

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(
        {...doc.data() as Map<String, dynamic>, 'id': uid});
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _users.doc(uid).update(data);

  // ─── TRAJETS ────────────────────────────────────────────────────────

  // No orderBy → no composite index needed → works on both web and mobile.
  // Sorting is done in Dart after the documents are received.
  Stream<List<TrajetModel>> trajetsStream() {
    return _trajets.snapshots().map((s) {
      final list = s.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return TrajetModel.fromMap({...data, 'id': d.id});
      }).toList();
      // Sort by heureDepart (HH:mm string sorts correctly)
      list.sort((a, b) => a.heureDepart.compareTo(b.heureDepart));
      return list;
    });
  }

  // No orderBy here either — same reason
  Stream<List<TrajetModel>> trajetsByControleur(String controleurId) {
    return _trajets
        .where('controleurId', isEqualTo: controleurId)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return TrajetModel.fromMap({...data, 'id': d.id});
      }).toList();
      list.sort((a, b) => a.heureDepart.compareTo(b.heureDepart));
      return list;
    });
  }

  Future<TrajetModel?> getTrajet(String id) async {
    final doc = await _trajets.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return TrajetModel.fromMap({...data, 'id': doc.id});
  }

  Future<void> createTrajet(TrajetModel trajet) =>
      _trajets.doc(trajet.id).set(trajet.toMap());

  Future<void> updateTrajet(String id, Map<String, dynamic> data) =>
      _trajets.doc(id).update(data);

  Future<void> demarrerTrajet(String id) =>
      _trajets.doc(id).update({'statut': 'en_cours'});

  Future<void> terminerTrajet(String id) =>
      _trajets.doc(id).update({'statut': 'termine'});

  // ─── TICKETS ────────────────────────────────────────────────────────

  // ticketsByClient: single-field where + orderBy on same field = no index needed
  Stream<List<TicketModel>> ticketsByClient(String clientId) {
    return _tickets
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return TicketModel.fromMap({...data, 'id': d.id});
      }).toList();
      // Sort by dateAchat descending in Dart
      list.sort((a, b) => b.dateAchat.compareTo(a.dateAchat));
      return list;
    });
  }

  Stream<List<TicketModel>> ticketsScannes() {
    return _tickets
        .where('scanne', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return TicketModel.fromMap({...data, 'id': d.id});
            }).toList());
  }

  Stream<List<TicketModel>> ticketsScannsByTrajet(String trajetId) {
    return _tickets
        .where('trajetId', isEqualTo: trajetId)
        .where('scanne', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return TicketModel.fromMap({...data, 'id': d.id});
            }).toList());
  }

  Future<TicketModel> acheterTicket({
    required String trajetId,
    required String clientId,
    required String clientNom,
    required double prix,
  }) async {
    const uuid = Uuid();
    final ticketId = uuid.v4();
    final now = DateTime.now();

    final ticket = TicketModel(
      id: ticketId,
      trajetId: trajetId,
      clientId: clientId,
      clientNom: clientNom,
      statut: 'valide',
      dateAchat: now.toIso8601String().split('T')[0],
      prix: prix,
      scanne: false,
    );

    final batch = _db.batch();
    batch.set(_tickets.doc(ticketId), ticket.toMap());
    batch.update(_trajets.doc(trajetId), {
      'placesRestantes': FieldValue.increment(-1),
    });
    await batch.commit();
    return ticket;
  }

  Future<String?> scannerTicket(String ticketId) async {
    try {
      final doc = await _tickets.doc(ticketId).get();
      if (!doc.exists) return 'Ticket introuvable ou invalide.';

      final data = doc.data() as Map<String, dynamic>;
      final statut = data['statut'] as String;

      if (statut == 'utilise') return 'Ce ticket a déjà été utilisé.';
      if (statut == 'expire') return 'Ce ticket est expiré.';

      await _tickets.doc(ticketId).update({
        'statut': 'utilise',
        'scanne': true,
        'dateScan': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Erreur lors de la validation : $e';
    }
  }

  Future<TicketModel?> getTicket(String id) async {
    final doc = await _tickets.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return TicketModel.fromMap({...data, 'id': doc.id});
  }


  Future<void> seedDemoTrajets(String controleurId) async {
    final existing = await _trajets.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    const uuid = Uuid();
    final now = Timestamp.now();

    final trajets = [
      TrajetModel(
        id: uuid.v4(), depart: 'Tunis Centre', destination: 'Sfax',
        region: 'Tunis', date: '2025-04-20', heureDepart: '08:00',
        heureArrivee: '11:30', prix: 25.0, statut: 'planifie',
        controleurId: controleurId, placesTotal: 50, placesRestantes: 32,
        societe: 'SNTRI',
      ),
      TrajetModel(
        id: uuid.v4(), depart: 'Sousse', destination: 'Monastir',
        region: 'Sousse', date: '2025-04-20', heureDepart: '09:30',
        heureArrivee: '10:00', prix: 5.0, statut: 'planifie',
        controleurId: controleurId, placesTotal: 30, placesRestantes: 15,
        societe:'STS', 
      ),
      TrajetModel(
        id: uuid.v4(), depart: 'Nabeul', destination: 'Hammamet',
        region: 'Nabeul', date: '2025-04-21', heureDepart: '14:00',
        heureArrivee: '14:45', prix: 3.5, statut: 'planifie',
        controleurId: controleurId, placesTotal: 25, placesRestantes: 20,
        societe:'SRTGN', 
      ),
      TrajetModel(
        id: uuid.v4(), depart: 'Bizerte', destination: 'Tunis Nord',
        region: 'Bizerte', date: '2025-04-21', heureDepart: '07:00',
        heureArrivee: '08:30', prix: 8.0, statut: 'planifie',
        controleurId: controleurId, placesTotal: 40, placesRestantes: 18,
        societe:'STB', 
      ),
      TrajetModel(
        id: uuid.v4(), depart: 'Gabès', destination: 'Médenine',
        region: 'Gabès', date: '2025-04-22', heureDepart: '10:00',
        heureArrivee: '11:15', prix: 7.0, statut: 'planifie',
        controleurId: controleurId, placesTotal: 35, placesRestantes: 22,
        societe:'STOREGAMES', 
      ),
    ];

    final batch = _db.batch();
    for (final t in trajets) {
      batch.set(_trajets.doc(t.id), {...t.toMap(), 'createdAt': now});
    }
    await batch.commit();
  }
}