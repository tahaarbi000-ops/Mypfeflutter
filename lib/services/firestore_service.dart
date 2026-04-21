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
    return UserModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': uid});
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _users.doc(uid).update(data);

  // ─── TRAJETS ────────────────────────────────────────────────────────

  Stream<List<TrajetModel>> trajetsStream() {
    return _trajets
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return TrajetModel.fromMap({...data, 'id': d.id});
            }).toList());
  }

  Stream<List<TrajetModel>> trajetsByControleur(String controleurId) {
    return _trajets
        .where('controleurId', isEqualTo: controleurId)
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return TrajetModel.fromMap({...data, 'id': d.id});
            }).toList());
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

  Stream<List<TicketModel>> ticketsByClient(String clientId) {
    return _tickets
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateAchat', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return TicketModel.fromMap({...data, 'id': d.id});
            }).toList());
  }

  Stream<List<TicketModel>> ticketsScannes() {
    return _tickets
        .where('scanne', isEqualTo: true)
        .orderBy('dateScan', descending: true)
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
    // Créer le ticket
    batch.set(_tickets.doc(ticketId), ticket.toMap());
    // Décrémenter les places
    batch.update(_trajets.doc(trajetId), {
      'placesRestantes': FieldValue.increment(-1),
    });
    await batch.commit();
    return ticket;
  }

  /// Retourne null si succès, sinon le message d'erreur
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
      return null; // succès
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

  // ─── SEED DATA (données de démo) ────────────────────────────────────

  Future<void> seedDemoTrajets(String controleurId) async {
    final existing = await _trajets.limit(1).get();
    if (existing.docs.isNotEmpty) return; // Déjà seeded

    const uuid = Uuid();
    final trajets = [
      TrajetModel(
        id: uuid.v4(),
        depart: 'Tunis Centre',
        destination: 'Sfax',
        region: 'Tunis',
        date: '2025-04-20',
        heureDepart: '08:00',
        heureArrivee: '11:30',
        prix: 25.0,
        statut: 'planifie',
        controleurId: controleurId,
        placesTotal: 50,
        placesRestantes: 32,
      ),
      TrajetModel(
        id: uuid.v4(),
        depart: 'Sousse',
        destination: 'Monastir',
        region: 'Sousse',
        date: '2025-04-20',
        heureDepart: '09:30',
        heureArrivee: '10:00',
        prix: 5.0,
        statut: 'planifie',
        controleurId: controleurId,
        placesTotal: 30,
        placesRestantes: 15,
      ),
      TrajetModel(
        id: uuid.v4(),
        depart: 'Nabeul',
        destination: 'Hammamet',
        region: 'Nabeul',
        date: '2025-04-21',
        heureDepart: '14:00',
        heureArrivee: '14:45',
        prix: 3.5,
        statut: 'planifie',
        controleurId: controleurId,
        placesTotal: 25,
        placesRestantes: 20,
      ),
      TrajetModel(
        id: uuid.v4(),
        depart: 'Bizerte',
        destination: 'Tunis Nord',
        region: 'Bizerte',
        date: '2025-04-21',
        heureDepart: '07:00',
        heureArrivee: '08:30',
        prix: 8.0,
        statut: 'planifie',
        controleurId: controleurId,
        placesTotal: 40,
        placesRestantes: 18,
      ),
      TrajetModel(
        id: uuid.v4(),
        depart: 'Gabès',
        destination: 'Médenine',
        region: 'Gabès',
        date: '2025-04-22',
        heureDepart: '10:00',
        heureArrivee: '11:15',
        prix: 7.0,
        statut: 'planifie',
        controleurId: controleurId,
        placesTotal: 35,
        placesRestantes: 22,
      ),
    ];

    final batch = _db.batch();
    for (final t in trajets) {
      batch.set(_trajets.doc(t.id), t.toMap());
    }
    await batch.commit();
  }
}
