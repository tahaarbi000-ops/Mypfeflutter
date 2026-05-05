import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../services/transport_api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/trajet_model.dart';
import '../shared/contact_page.dart';
import '../shared/profil_page.dart';
import 'mes_voyages_page.dart';
import 'trajet_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _TrajetsTab(),
    MesVoyagesPage(),
    ContactPage(),
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number),
              label: 'Mes voyages'),
          NavigationDestination(
              icon: Icon(Icons.support_agent_outlined),
              selectedIcon: Icon(Icons.support_agent),
              label: 'Contact'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRAJETS TAB — now powered by the Transport API
// ─────────────────────────────────────────────────────────────────────────────

class _TrajetsTab extends StatefulWidget {
  const _TrajetsTab();

  @override
  State<_TrajetsTab> createState() => _TrajetsTabState();
}

class _TrajetsTabState extends State<_TrajetsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _jourFiltre; // e.g. 'lundi'
  double? _prixMax; // price filter
  bool _showFilters = false;

  List<TransportArret> _arrets = [];
  bool _loading = false;
  String? _error;

  // Days for filter chips
  static const _jours = [
    ('Tous', null),
    ('Lun', 'lundi'),
    ('Mar', 'mardi'),
    ('Mer', 'mercredi'),
    ('Jeu', 'jeudi'),
    ('Ven', 'vendredi'),
    ('Sam', 'samedi'),
    ('Dim', 'dimanche'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await TransportApiService.fetchTransport(
        nom: _searchQuery.isNotEmpty ? _searchQuery.toUpperCase() : null,
        jour: _jourFiltre,
        prixMax: _prixMax,
        limit: 200,
      );
      setState(() {
        _arrets = response.data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Group arrets by ligne (Nom) for display as "trajets"
  List<_TrajetSummary> get _trajetsSummary {
    final Map<String, _TrajetSummary> map = {};
    for (final a in _arrets) {
      if (!map.containsKey(a.nom)) {
        map[a.nom] = _TrajetSummary(
          nom: a.nom,
          ligne: a.ligne,
          route: a.route,
          depart: a.depart,
          destination: a.destination,
          heureAller: a.aller,
          heureRetour: a.retour,
          prix: a.prix,
          joursActifs: a.joursActifs,
          nbArrets: 0,
        );
      }
      map[a.nom] = map[a.nom]!.copyWith(nbArrets: map[a.nom]!.nbArrets + 1);
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final trajets = _trajetsSummary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: _showFilters ? 260 : 190,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.secondary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour, ${user.prenom} ',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            const Text('Où allez-vous ?',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Filter toggle button
                        IconButton(
                          onPressed: () =>
                              setState(() => _showFilters = !_showFilters),
                          icon: Icon(
                            _showFilters
                                ? Icons.filter_list_off
                                : Icons.filter_list,
                            color: Colors.white,
                          ),
                          tooltip: 'Filtres',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search bar
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        // debounce: fetch after user stops typing
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_searchQuery == v) _fetchData();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Ex: TUNIS, SFAX, GAFSA...',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                  _fetchData();
                                },
                              )
                            : null,
                      ),
                    ),

                    // ── Filters (collapsible) ──────────────────
                    if (_showFilters) ...[
                      const SizedBox(height: 10),
                      // Day filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _jours.map((entry) {
                            final (label, value) = entry;
                            final selected = _jourFiltre == value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? AppTheme.primary
                                          : Colors.white,
                                    )),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() => _jourFiltre = value);
                                  _fetchData();
                                },
                                selectedColor: Colors.white,
                                backgroundColor: Colors.white24,
                                checkmarkColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Price filter
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          const Text('Prix max:',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 8),
                          ...[null, 5.0, 10.0, 20.0, 50.0].map((v) {
                            final selected = _prixMax == v;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _prixMax = v);
                                  _fetchData();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    v == null ? 'Tous' : '${v.toInt()} TND',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? AppTheme.primary
                                          : Colors.white,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildContent(trajets),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<_TrajetSummary> trajets) {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Impossible de charger les trajets',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (trajets.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Aucun trajet pour "$_searchQuery"'
                    : 'Aucun trajet disponible',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Total found badge
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${trajets.length} trajet${trajets.length > 1 ? 's' : ''} trouvé${trajets.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _ApiTrajetCard(trajet: trajets[i]),
            childCount: trajets.length,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class for grouped trajet summary
// ─────────────────────────────────────────────────────────────────────────────

class _TrajetSummary {
  final String nom;
  final String ligne;
  final String route;
  final String depart;
  final String destination;
  final String heureAller;
  final String heureRetour;
  final double prix;
  final List<String> joursActifs;
  final int nbArrets;

  const _TrajetSummary({
    required this.nom,
    required this.ligne,
    required this.route,
    required this.depart,
    required this.destination,
    required this.heureAller,
    required this.heureRetour,
    required this.prix,
    required this.joursActifs,
    required this.nbArrets,
  });

  _TrajetSummary copyWith({int? nbArrets}) => _TrajetSummary(
        nom: nom,
        ligne: ligne,
        route: route,
        depart: depart,
        destination: destination,
        heureAller: heureAller,
        heureRetour: heureRetour,
        prix: prix,
        joursActifs: joursActifs,
        nbArrets: nbArrets ?? this.nbArrets,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card for API trajet
// ─────────────────────────────────────────────────────────────────────────────

class _ApiTrajetCard extends StatelessWidget {
  final _TrajetSummary trajet;
  const _ApiTrajetCard({required this.trajet});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: navigate to detail page if needed
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => TransportDetailPage(trajet: trajet)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Header row ──────────────────────────────────
              Row(
                children: [
                  // Ligne badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Ligne ${trajet.ligne}',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Route badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trajet.route,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ),
                  const Spacer(),
                  // Nb arrêts
                  Text(
                    '${trajet.nbArrets} arrêts',
                    style:
                        const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Route row ────────────────────────────────────
              Row(
                children: [
                  // Depart
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Départ',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey)),
                        Text(trajet.depart,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                        Text(trajet.heureAller,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  // Arrow
                  const Column(
                    children: [
                      Icon(Icons.arrow_forward,
                          color: AppTheme.textGrey, size: 20),
                    ],
                  ),
                  // Destination
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Arrivée',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey)),
                        Text(trajet.destination,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                        Text(trajet.heureRetour,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Footer row ───────────────────────────────────
              Row(
                children: [
                  // Jours actifs
                  Wrap(
                    spacing: 4,
                    children: trajet.joursActifs
                        .map((j) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(j,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                  const Spacer(),
                  // Prix
                  Text(
                    '${trajet.prix.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keep original _TrajetCard for Firestore-based trajets (Mes Voyages etc.)
// ─────────────────────────────────────────────────────────────────────────────

class TrajetCard extends StatelessWidget {
  final TrajetModel trajet;
  const TrajetCard({super.key, required this.trajet});

  Color get _statutColor {
    switch (trajet.statut) {
      case 'en_cours':
        return AppTheme.success;
      case 'planifie':
        return AppTheme.accent;
      default:
        return AppTheme.textGrey;
    }
  }

  String get _statutLabel {
    switch (trajet.statut) {
      case 'en_cours':
        return 'En cours';
      case 'planifie':
        return 'Planifié';
      case 'actif':
        return 'Disponible';
      default:
        return 'Terminé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TrajetDetailPage(trajet: trajet))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statutLabel,
                        style: TextStyle(
                            color: _statutColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.location_on,
                          size: 12, color: AppTheme.textGrey),
                      const SizedBox(width: 2),
                      Text(trajet.region ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textGrey)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Départ',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey)),
                        Text(trajet.depart,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                        Text(trajet.heureDepart ?? '—',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.arrow_forward,
                          color: AppTheme.textGrey, size: 20),
                      Text(trajet.date ?? '',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textGrey)),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Arrivée',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey)),
                        Text(trajet.destination,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                        Text(trajet.heureArrivee ?? '—',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event_seat, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${trajet.placesRestantes} places',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const Spacer(),
                  Text('${trajet.prix.toStringAsFixed(2)} TND',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
