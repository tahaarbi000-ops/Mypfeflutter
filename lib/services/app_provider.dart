import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/trajet_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  List<TrajetModel> _trajets = [];
  List<TicketModel> _tickets = [];
  String _regionFiltre = 'Toutes';
  bool _loading = false;

  StreamSubscription? _trajetsSub;
  StreamSubscription? _ticketsSub;
  StreamSubscription? _authSub;

  // ─── GETTERS ────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  List<TrajetModel> get trajets => _trajets;
  bool get loading => _loading;
  bool get isLoggedIn => _currentUser != null;
  bool get isClient => _currentUser?.role == 'client';
  bool get isControleur => _currentUser?.role == 'controleur';
  String get regionFiltre => _regionFiltre;

  static const List<String> regions = [
    'Toutes', 'Tunis', 'Ariana', 'Ben Arous', 'Manouba',
    'Nabeul', 'Zaghouan', 'Bizerte', 'Béja', 'Jendouba',
    'Le Kef', 'Siliana', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Sousse', 'Monastir', 'Mahdia', 'Sfax', 'Gafsa',
    'Tozeur', 'Kébili', 'Gabès', 'Médenine', 'Tataouine',
  ];

  AppProvider() {
    _listenToAuth();
  }

  void _listenToAuth() {
    _authSub = _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserById(firebaseUser.uid);
        if (_currentUser != null) _subscribeToData();
      } else {
        _currentUser = null;
        _cancelSubscriptions();
        _trajets = [];
        _tickets = [];
      }
      notifyListeners();
    });
  }

  void _subscribeToData() {
    _cancelSubscriptions();
    _trajetsSub = _firestoreService.trajetsStream().listen((data) {
      _trajets = data;
      notifyListeners();
    });
    if (isClient && _currentUser != null) {
      _ticketsSub = _firestoreService.ticketsByClient(_currentUser!.id).listen((data) {
        _tickets = data;
        notifyListeners();
      });
    }
    if (isControleur && _currentUser != null) {
      _firestoreService.seedDemoTrajets(_currentUser!.id);
    }
  }

  void _cancelSubscriptions() {
    _trajetsSub?.cancel();
    _ticketsSub?.cancel();
    _trajetsSub = null;
    _ticketsSub = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelSubscriptions();
    super.dispose();
  }

  // ─── COMPUTED ───────────────────────────────────────────────────────
  List<TrajetModel> get trajetsFiltres {
    final base = _trajets.where((t) => t.statut != 'termine').toList();
    if (_regionFiltre == 'Toutes') return base;
    return base.where((t) => t.region == _regionFiltre).toList();
  }

  List<TicketModel> get mesTickets => _tickets;

  List<TicketModel> get ticketsScannesToday =>
      _tickets.where((t) => t.scanne).toList();

  TrajetModel? get trajetActuel {
    if (_currentUser == null) return null;
    try {
      return _trajets.firstWhere(
        (t) => t.controleurId == _currentUser!.id && t.statut == 'en_cours',
      );
    } catch (_) {
      return null;
    }
  }

  TrajetModel? getTrajetById(String id) {
    try { return _trajets.firstWhere((t) => t.id == id); } catch (_) { return null; }
  }

  // ─── AUTH ────────────────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<String?> inscrire({
    required String nom, required String prenom, required String email,
    required String telephone, required String motDePasse, required String role,
  }) async {
    _setLoading(true);
    try {
      await _authService.signUp(
        nom: nom, prenom: prenom, email: email,
        telephone: telephone, password: motDePasse, role: role,
      );
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<void> logout() async => _authService.signOut();

  Future<String?> resetPassword(String email) async {
    try { await _authService.resetPassword(email); return null; }
    catch (e) { return e.toString(); }
  }

  // ─── PROFIL ──────────────────────────────────────────────────────────
  Future<String?> mettreAJourProfil({
    String? nom, String? prenom, String? telephone,
    String? motDePasse, File? photo,
  }) async {
    if (_currentUser == null) return 'Non connecté';
    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (nom != null) { updates['nom'] = nom; _currentUser!.nom = nom; }
      if (prenom != null) { updates['prenom'] = prenom; _currentUser!.prenom = prenom; }
      if (telephone != null) { updates['telephone'] = telephone; _currentUser!.telephone = telephone; }
      if (photo != null) {
        final url = await _storageService.uploadProfilePhoto(_currentUser!.id, photo);
        updates['photoUrl'] = url;
        _currentUser!.photoUrl = url;
      }
      if (updates.isNotEmpty) await _firestoreService.updateUser(_currentUser!.id, updates);
      if (motDePasse != null && motDePasse.isNotEmpty) {
        await _authService.updatePassword(motDePasse);
      }
      _setLoading(false);
      notifyListeners();
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<String?> uploadProfilePhoto() async {
    if (_currentUser == null) return 'Non connecté';
    try {
      final url = await _storageService.pickAndUploadProfilePhoto(_currentUser!.id);
      if (url != null) {
        _currentUser!.photoUrl = url;
        await _firestoreService.updateUser(_currentUser!.id, {'photoUrl': url});
        notifyListeners();
      }
      return null;
    } catch (e) { return e.toString(); }
  }

  // ─── FILTRAGE ────────────────────────────────────────────────────────
  void setRegionFiltre(String region) {
    _regionFiltre = region;
    notifyListeners();
  }

  // ─── TICKETS ─────────────────────────────────────────────────────────
  Future<String?> acheterTicket(String trajetId) async {
    if (_currentUser == null) return 'Non connecté';
    final trajet = getTrajetById(trajetId);
    if (trajet == null) return 'Trajet introuvable';
    if (trajet.placesRestantes <= 0) return 'Plus de places disponibles';
    try {
      await _firestoreService.acheterTicket(
        trajetId: trajetId,
        clientId: _currentUser!.id,
        clientNom: '${_currentUser!.prenom} ${_currentUser!.nom}',
        prix: trajet.prix,
      );
      return null;
    } catch (e) { return e.toString(); }
  }

  Future<String?> scannerTicket(String ticketId) =>
      _firestoreService.scannerTicket(ticketId);

  // ─── TRAJETS (contrôleur) ────────────────────────────────────────────
  Future<String?> demarrerTrajet(String trajetId) async {
    if (trajetActuel != null && trajetActuel!.id != trajetId) {
      return 'Un trajet est déjà en cours';
    }
    try {
      await _firestoreService.demarrerTrajet(trajetId);
      _ticketsSub?.cancel();
      _ticketsSub = _firestoreService.ticketsScannsByTrajet(trajetId).listen((data) {
        _tickets = data;
        notifyListeners();
      });
      return null;
    } catch (e) { return e.toString(); }
  }

  Future<String?> terminerTrajet(String trajetId) async {
    try { await _firestoreService.terminerTrajet(trajetId); return null; }
    catch (e) { return e.toString(); }
  }

  Future<String?> mettreAJourTrajet(String trajetId, {
    String? depart, String? destination,
    String? heureDepart, String? heureArrivee, double? prix,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (depart != null) updates['depart'] = depart;
      if (destination != null) updates['destination'] = destination;
      if (heureDepart != null) updates['heureDepart'] = heureDepart;
      if (heureArrivee != null) updates['heureArrivee'] = heureArrivee;
      if (prix != null) updates['prix'] = prix;
      await _firestoreService.updateTrajet(trajetId, updates);
      return null;
    } catch (e) { return e.toString(); }
  }

  void _setLoading(bool val) { _loading = val; notifyListeners(); }
}
