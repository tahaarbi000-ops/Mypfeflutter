import 'dart:convert';
import 'package:http/http.dart' as http;

class TransportArret {
  final int id;
  final String arret;
  final String route;
  final String ligne;
  final String nom;
  final String station;
  final String aller;
  final String retour;
  final bool lundi;
  final bool mardi;
  final bool mercredi;
  final bool jeudi;
  final bool vendredi;
  final bool samedi;
  final bool dimanche;
  final double prix;

  TransportArret({
    required this.id,
    required this.arret,
    required this.route,
    required this.ligne,
    required this.nom,
    required this.station,
    required this.aller,
    required this.retour,
    required this.lundi,
    required this.mardi,
    required this.mercredi,
    required this.jeudi,
    required this.vendredi,
    required this.samedi,
    required this.dimanche,
    required this.prix,
  });

  factory TransportArret.fromJson(Map<String, dynamic> json) {
    return TransportArret(
      id: json['_id'] ?? 0,
      arret: json['Arret']?.toString() ?? '',
      route: json['Route'] ?? '',
      ligne: json['Ligne'] ?? '',
      nom: json['Nom'] ?? '',
      station: json['Station'] ?? '',
      aller: json['Aller'] ?? '',
      retour: json['Retour'] ?? '',
      lundi: json['Lundi'] == '*',
      mardi: json['Mardi'] == '*',
      mercredi: json['Mercredi'] == '*',
      jeudi: json['Jeudi'] == '*',
      vendredi: json['vendredi'] == '*',
      samedi: json['samedi'] == '*',
      dimanche: json['Dimanche'] == '*',
      prix: (json['prix'] ?? 0).toDouble(),
    );
  }

  /// Depart city extracted from Nom (e.g. "TUNIS - GAFSA" → "TUNIS")
  String get depart => nom.contains(' - ') ? nom.split(' - ')[0].trim() : nom;

  /// Destination city extracted from Nom (e.g. "TUNIS - GAFSA" → "GAFSA")
  String get destination =>
      nom.contains(' - ') ? nom.split(' - ')[1].trim() : nom;

  List<String> get joursActifs {
    final jours = <String>[];
    if (lundi) jours.add('Lun');
    if (mardi) jours.add('Mar');
    if (mercredi) jours.add('Mer');
    if (jeudi) jours.add('Jeu');
    if (vendredi) jours.add('Ven');
    if (samedi) jours.add('Sam');
    if (dimanche) jours.add('Dim');
    return jours;
  }
}

class TransportApiResponse {
  final bool success;
  final int total;
  final int limit;
  final int offset;
  final int count;
  final List<TransportArret> data;

  TransportApiResponse({
    required this.success,
    required this.total,
    required this.limit,
    required this.offset,
    required this.count,
    required this.data,
  });

  factory TransportApiResponse.fromJson(Map<String, dynamic> json) {
    return TransportApiResponse(
      success: json['success'] ?? false,
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      offset: json['offset'] ?? 0,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => TransportArret.fromJson(e))
          .toList(),
    );
  }
}

class TransportApiService {
  static const String _baseUrl = 'https://transport-api-psi.vercel.app/api';

  /// Fetch transport stops with optional filters
  static Future<TransportApiResponse> fetchTransport({
    String? ligne,
    String? nom,
    String? station,
    String? route,
    String? jour,
    double? prixMin,
    double? prixMax,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (ligne != null) params['ligne'] = ligne;
    if (nom != null) params['nom'] = nom;
    if (station != null) params['station'] = station;
    if (route != null) params['route'] = route;
    if (jour != null) params['jour'] = jour;
    if (prixMin != null) params['prix_min'] = prixMin.toString();
    if (prixMax != null) params['prix_max'] = prixMax.toString();

    final uri = Uri.parse('$_baseUrl/transport').replace(queryParameters: params);

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      return TransportApiResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur API: ${response.statusCode}');
    }
  }

  /// Fetch all unique lines
  static Future<List<dynamic>> fetchLignes() async {
    final uri = Uri.parse('$_baseUrl/lignes');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as List<dynamic>;
    }
    throw Exception('Erreur API lignes: ${response.statusCode}');
  }

  /// Fetch horaires between two stations
  static Future<List<dynamic>> fetchHoraires({
    required String depart,
    required String arrivee,
    String? jour,
  }) async {
    final params = <String, String>{'depart': depart, 'arrivee': arrivee};
    if (jour != null) params['jour'] = jour;
    final uri =
        Uri.parse('$_baseUrl/horaires').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as List<dynamic>;
    }
    throw Exception('Erreur API horaires: ${response.statusCode}');
  }
}