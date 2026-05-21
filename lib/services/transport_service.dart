// lib/services/transport_service.dart
//
// Remplacement complet de TransportApiService (HTTP)
// par Firebase Firestore.
//
// Collections Firestore utilisées :
//   • "trajets"   — lignes avec arrêts, société, horaires
//   • "societes"  — sociétés régionales
//   • "destinations" — stations uniques
//
// Dépendances pubspec.yaml :
//   cloud_firestore: ^5.x.x
//   firebase_core:   ^3.x.x

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLES
// ─────────────────────────────────────────────────────────────────────────────

/// Un arrêt individuel dans un trajet
class TransportArret {
  final String arret;
  final String station;
  final String heureAller;
  final String heureRetour;
  final double prix;

  const TransportArret({
    required this.arret,
    required this.station,
    required this.heureAller,
    required this.heureRetour,
    required this.prix,
  });

  factory TransportArret.fromMap(Map<String, dynamic> map) {
    return TransportArret(
      arret:       map['arret']?.toString()        ?? '',
      station:     map['station']  as String?      ?? '',
      heureAller:  map['heureAller']  as String?   ?? '',
      heureRetour: map['heureRetour'] as String?   ?? '',
      prix:        (map['prix'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'arret':       arret,
    'station':     station,
    'heureAller':  heureAller,
    'heureRetour': heureRetour,
    'prix':        prix,
  };
}

/// Un trajet complet (= une ligne de bus)
class Trajet {
  final String id;           // Firestore document ID
  final String ligne;        // ex: "100"
  final String nom;          // ex: "TUNIS - GAFSA"
  final String route;        // ex: "GP1"
  final String societe;      // ex: "SRTK"
  final String depart;       // première station
  final String destination;  // dernière station
  final String heureAller;
  final String heureRetour;
  final double prix;
  final List<String> joursActifs;  // ["Lun", "Mar", ...]
  final List<TransportArret> arrets;

  const Trajet({
    required this.id,
    required this.ligne,
    required this.nom,
    required this.route,
    required this.societe,
    required this.depart,
    required this.destination,
    required this.heureAller,
    required this.heureRetour,
    required this.prix,
    required this.joursActifs,
    required this.arrets,
  });

  factory Trajet.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Trajet(
      id:          doc.id,
      ligne:       map['ligne']       as String? ?? '',
      nom:         map['nom']         as String? ?? '',
      route:       map['route']       as String? ?? '',
      societe:     map['societe']     as String? ?? '',
      depart:      map['depart']      as String? ?? '',
      destination: map['destination'] as String? ?? '',
      heureAller:  map['heureAller']  as String? ?? '',
      heureRetour: map['heureRetour'] as String? ?? '',
      prix:        (map['prix'] ?? 0).toDouble(),
      joursActifs: List<String>.from(map['joursActifs'] ?? []),
      arrets:      (map['arrets'] as List<dynamic>? ?? [])
          .map((a) => TransportArret.fromMap(a as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Départ extrait du nom si non renseigné
  String get departDisplay =>
      depart.isNotEmpty ? depart : (nom.contains(' - ') ? nom.split(' - ')[0].trim() : nom);

  /// Destination extraite du nom si non renseigné
  String get destinationDisplay =>
      destination.isNotEmpty ? destination : (nom.contains(' - ') ? nom.split(' - ')[1].trim() : nom);

  bool get lundi     => joursActifs.contains('Lun');
  bool get mardi     => joursActifs.contains('Mar');
  bool get mercredi  => joursActifs.contains('Mer');
  bool get jeudi     => joursActifs.contains('Jeu');
  bool get vendredi  => joursActifs.contains('Ven');
  bool get samedi    => joursActifs.contains('Sam');
  bool get dimanche  => joursActifs.contains('Dim');
}

/// Résultat paginé (conserve le même contrat que l'ancienne API HTTP)
class TransportApiResponse {
  final bool success;
  final int total;
  final int limit;
  final int offset;
  final int count;
  final List<Trajet> data;

  const TransportApiResponse({
    required this.success,
    required this.total,
    required this.limit,
    required this.offset,
    required this.count,
    required this.data,
  });
}

/// Une société régionale de transport
class Societe {
  final String id;
  final String nom;
  final String full;
  final int founded;
  final String couleur;
  final List<String> regions;
  final int nbLignes;
  final int nbBus;
  final String? website;
  final List<Map<String, dynamic>> lignes;

  const Societe({
    required this.id,
    required this.nom,
    required this.full,
    required this.founded,
    required this.couleur,
    required this.regions,
    required this.nbLignes,
    required this.nbBus,
    this.website,
    required this.lignes,
  });

  factory Societe.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Societe(
      id:       doc.id,
      nom:      map['nom']     as String? ?? '',
      full:     map['full']    as String? ?? '',
      founded:  (map['founded'] ?? 0) as int,
      couleur:  map['couleur'] as String? ?? '#6B7280',
      regions:  List<String>.from(map['regions'] ?? []),
      nbLignes: (map['nbLignes'] ?? 0) as int,
      nbBus:    (map['nbBus']    ?? 0) as int,
      website:  map['website']  as String?,
      lignes:   (map['lignes'] as List<dynamic>? ?? [])
          .map((l) => Map<String, dynamic>.from(l as Map))
          .toList(),
    );
  }
}

/// Une station / destination unique
class Station {
  final String id;
  final String nom;
  final bool actif;

  const Station({required this.id, required this.nom, required this.actif});

  factory Station.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Station(
      id:    doc.id,
      nom:   map['nom']   as String? ?? '',
      actif: map['actif'] as bool?   ?? true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

class TransportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _trajets      => _db.collection('trajets');
  static CollectionReference<Map<String, dynamic>> get _societes     => _db.collection('societes');
  static CollectionReference<Map<String, dynamic>> get _destinations => _db.collection('destinations');

  // ── Cache léger (évite des lectures répétées) ───────────────────────────
  static List<Trajet>?   _cachedTrajets;
  static List<Societe>?  _cachedSocietes;
  static List<Station>?  _cachedStations;

  static void clearCache() {
    _cachedTrajets  = null;
    _cachedSocietes = null;
    _cachedStations = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TRAJETS
  // ─────────────────────────────────────────────────────────────────────────

  /// Charge tous les trajets (avec cache).
  /// Le tri et le filtrage sont faits côté client pour éviter les index composites.
  static Future<List<Trajet>> _getAllTrajets() async {
    if (_cachedTrajets != null) return _cachedTrajets!;
    final snap = await _trajets.get();
    _cachedTrajets = snap.docs.map(Trajet.fromFirestore).toList()
      ..sort((a, b) => a.ligne.compareTo(b.ligne));
    return _cachedTrajets!;
  }

  /// Équivalent de [TransportApiService.fetchTransport]
  /// Filtre client-side : ligne, nom, station, route, jour, prixMin, prixMax, societe
  static Future<TransportApiResponse> fetchTransport({
    String? ligne,
    String? nom,
    String? station,
    String? route,
    String? jour,
    String? societe,
    double? prixMin,
    double? prixMax,
    int limit  = 100,
    int offset = 0,
  }) async {
    try {
      var all = await _getAllTrajets();

      // ── Filtres ──────────────────────────────────────────────────────────
      if (ligne != null && ligne.isNotEmpty) {
        all = all.where((t) => t.ligne == ligne).toList();
      }
      if (nom != null && nom.isNotEmpty) {
        final q = nom.toUpperCase();
        all = all.where((t) => t.nom.toUpperCase().contains(q)).toList();
      }
      if (station != null && station.isNotEmpty) {
        final q = station.toUpperCase();
        all = all.where((t) =>
          t.depart.toUpperCase().contains(q) ||
          t.destination.toUpperCase().contains(q) ||
          t.arrets.any((a) => a.station.toUpperCase().contains(q))
        ).toList();
      }
      if (route != null && route.isNotEmpty) {
        all = all.where((t) => t.route == route).toList();
      }
      if (jour != null && jour.isNotEmpty) {
        all = all.where((t) => t.joursActifs.contains(jour)).toList();
      }
      if (societe != null && societe.isNotEmpty) {
        all = all.where((t) => t.societe == societe).toList();
      }
      if (prixMin != null) {
        all = all.where((t) => t.prix >= prixMin).toList();
      }
      if (prixMax != null) {
        all = all.where((t) => t.prix <= prixMax).toList();
      }

      final total  = all.length;
      final paged  = all.skip(offset).take(limit).toList();

      return TransportApiResponse(
        success: true,
        total:   total,
        limit:   limit,
        offset:  offset,
        count:   paged.length,
        data:    paged,
      );
    } catch (e) {
      throw Exception('Erreur Firestore fetchTransport: $e');
    }
  }

  /// Récupère un trajet par son numéro de ligne
  static Future<Trajet?> fetchTrajetByLigne(String ligne) async {
    try {
      final all = await _getAllTrajets();
      return all.firstWhere(
        (t) => t.ligne == ligne,
        orElse: () => throw StateError('not found'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Équivalent de [TransportApiService.fetchLignes]
  /// Retourne la liste des lignes uniques avec nom et société
  static Future<List<Map<String, dynamic>>> fetchLignes() async {
    try {
      final all = await _getAllTrajets();
      return all.map((t) => {
        'ligne':       t.ligne,
        'nom':         t.nom,
        'depart':      t.departDisplay,
        'destination': t.destinationDisplay,
        'societe':     t.societe,
        'route':       t.route,
      }).toList();
    } catch (e) {
      throw Exception('Erreur Firestore fetchLignes: $e');
    }
  }

  /// Équivalent de [TransportApiService.fetchHoraires]
  /// Trouve les trajets qui passent par depart ET arrivee
  static Future<List<Map<String, dynamic>>> fetchHoraires({
    required String depart,
    required String arrivee,
    String? jour,
  }) async {
    try {
      final all = await _getAllTrajets();
      final dep = depart.toUpperCase();
      final arr = arrivee.toUpperCase();

      final results = <Map<String, dynamic>>[];

      for (final trajet in all) {
        if (jour != null && !trajet.joursActifs.contains(jour)) continue;

        // Cherche l'arrêt de départ et d'arrivée dans la liste des arrêts
        int depIndex = -1;
        int arrIndex = -1;
        for (int i = 0; i < trajet.arrets.length; i++) {
          final stationUp = trajet.arrets[i].station.toUpperCase();
          if (stationUp.contains(dep) && depIndex == -1) depIndex = i;
          if (stationUp.contains(arr))                   arrIndex = i;
        }

        // Le départ doit être avant l'arrivée dans le sens aller
        if (depIndex != -1 && arrIndex != -1 && depIndex < arrIndex) {
          final arretDep = trajet.arrets[depIndex];
          final arretArr = trajet.arrets[arrIndex];
          results.add({
            'trajetId':    trajet.id,
            'ligne':       trajet.ligne,
            'nom':         trajet.nom,
            'societe':     trajet.societe,
            'depart':      arretDep.station,
            'arrivee':     arretArr.station,
            'heureAller':  arretDep.heureAller,
            'heureRetour': arretArr.heureRetour,
            'prix':        arretArr.prix - arretDep.prix,
            'joursActifs': trajet.joursActifs,
          });
        }
      }

      return results;
    } catch (e) {
      throw Exception('Erreur Firestore fetchHoraires: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOCIÉTÉS
  // ─────────────────────────────────────────────────────────────────────────

  /// Charge toutes les sociétés (avec cache)
  static Future<List<Societe>> fetchSocietes() async {
    if (_cachedSocietes != null) return _cachedSocietes!;
    try {
      final snap = await _societes.get();
      _cachedSocietes = snap.docs.map(Societe.fromFirestore).toList()
        ..sort((a, b) => a.nom.compareTo(b.nom));
      return _cachedSocietes!;
    } catch (e) {
      throw Exception('Erreur Firestore fetchSocietes: $e');
    }
  }

  /// Récupère une société par son nom (ex: "SRTK")
  static Future<Societe?> fetchSocieteByNom(String nom) async {
    try {
      final all = await fetchSocietes();
      return all.firstWhere(
        (s) => s.nom == nom,
        orElse: () => throw StateError('not found'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream temps réel sur les sociétés
  static Stream<List<Societe>> watchSocietes() {
    return _societes.snapshots().map(
      (snap) => snap.docs.map(Societe.fromFirestore).toList()
        ..sort((a, b) => a.nom.compareTo(b.nom)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATIONS / DESTINATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Charge toutes les stations actives (avec cache)
  static Future<List<Station>> fetchStations({bool activeOnly = true}) async {
    if (_cachedStations != null) {
      return activeOnly
          ? _cachedStations!.where((s) => s.actif).toList()
          : _cachedStations!;
    }
    try {
      final snap = await _destinations.get();
      _cachedStations = snap.docs.map(Station.fromFirestore).toList()
        ..sort((a, b) => a.nom.compareTo(b.nom));
      return activeOnly
          ? _cachedStations!.where((s) => s.actif).toList()
          : _cachedStations!;
    } catch (e) {
      throw Exception('Erreur Firestore fetchStations: $e');
    }
  }

  /// Recherche de stations par nom (autocomplétion)
  static Future<List<Station>> searchStations(String query) async {
    if (query.trim().isEmpty) return fetchStations();
    final all = await fetchStations();
    final q   = query.toUpperCase();
    return all.where((s) => s.nom.toUpperCase().contains(q)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STREAMS TEMPS RÉEL (optionnel — pour Widgets avec StreamBuilder)
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream en temps réel sur les trajets filtrés par société
  static Stream<List<Trajet>> watchTrajetsBySociete(String societe) {
    return _trajets.snapshots().map((snap) {
      final list = snap.docs.map(Trajet.fromFirestore).toList();
      return list
          .where((t) => t.societe == societe)
          .toList()
        ..sort((a, b) => a.ligne.compareTo(b.ligne));
    });
  }

  /// Stream en temps réel sur tous les trajets
  static Stream<List<Trajet>> watchAllTrajets() {
    return _trajets.snapshots().map((snap) =>
      snap.docs.map(Trajet.fromFirestore).toList()
        ..sort((a, b) => a.ligne.compareTo(b.ligne))
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CRUD TRAJETS (admin / contrôleur)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String> addTrajet(Map<String, dynamic> data) async {
    clearCache();
    final ref = await _trajets.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateTrajet(String id, Map<String, dynamic> data) async {
    clearCache();
    await _trajets.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteTrajet(String id) async {
    clearCache();
    await _trajets.doc(id).delete();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS UTILITAIRES
  // ─────────────────────────────────────────────────────────────────────────

  /// Retourne les lignes uniques pour une société donnée
  static Future<List<Trajet>> fetchTrajetsBySociete(String societe) async {
    final all = await _getAllTrajets();
    return all.where((t) => t.societe == societe).toList();
  }

  /// Retourne les trajets actifs un jour donné (ex: "Lun")
  static Future<List<Trajet>> fetchTrajetsByJour(String jour) async {
    final all = await _getAllTrajets();
    return all.where((t) => t.joursActifs.contains(jour)).toList();
  }

  /// Retourne tous les noms de sociétés présents dans les trajets
  static Future<List<String>> fetchSocietesNoms() async {
    final all = await _getAllTrajets();
    return all.map((t) => t.societe).where((s) => s.isNotEmpty).toSet().toList()..sort();
  }
}