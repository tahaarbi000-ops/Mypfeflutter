

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../services/transport_service.dart';
import '../../utils/app_theme.dart';
import '../../models/trajet_model.dart';
import '../shared/contact_page.dart';
import '../shared/profil_page.dart';
import 'mes_voyages_page.dart';
import 'trajet_detail_page.dart';
import 'reservation_bottom_sheet.dart';

// Couleurs par société — cohérent avec le dashboard React
const _societeColors = {
  'SRTK': Color(0xFF0694A2),
  'SRTTG': Color(0xFFE3A008),
  'SRTGB': Color(0xFF057A55),
  'SRTSO': Color(0xFF7E3AF2),
  'SRTS': Color(0xFFE02424),
  'SRTNM': Color(0xFFC27803),
  'Transtu': Color(0xFF1A56DB),
};

Color _colorForSociete(String? societe) =>
    _societeColors[societe] ?? AppTheme.primary;

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
// ONGLET TRAJETS — alimenté par Firebase TransportService
// ─────────────────────────────────────────────────────────────────────────────

class _TrajetsTab extends StatefulWidget {
  const _TrajetsTab();

  @override
  State<_TrajetsTab> createState() => _TrajetsTabState();
}

class _TrajetsTabState extends State<_TrajetsTab> {
  final _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String?
      _jourFiltre; // valeurs : 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
  double? _prixMax;
  String? _societeFiltre;
  bool _showFilters = false;

  // ── CORRIGÉ : List<Trajet> au lieu de List<TransportArret> ───────────────
  List<Trajet> _trajets = [];
  List<String> _societesDisponibles = [];
  bool _loading = false;
  String? _error;

  // ── CORRIGÉ : valeurs = codes Firestore ('Lun', 'Mar'…) ─────────────────
  static const _jours = [
    ('Tous', null),
    ('Lun', 'Lun'),
    ('Mar', 'Mar'),
    ('Mer', 'Mer'),
    ('Jeu', 'Jeu'),
    ('Ven', 'Ven'),
    ('Sam', 'Sam'),
    ('Dim', 'Dim'),
  ];

  static const _prixOptions = [null, 5.0, 10.0, 20.0, 50.0];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchSocietes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Charger les noms de sociétés pour le filtre ──────────────────────────
  Future<void> _fetchSocietes() async {
    try {
      final noms = await TransportService.fetchSocietesNoms();
      if (mounted) setState(() => _societesDisponibles = noms);
    } catch (_) {}
  }

  // ── Charger les trajets depuis Firestore ─────────────────────────────────
  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // CORRIGÉ : response.data est maintenant List<Trajet>
      final response = await TransportService.fetchTransport(
        nom: _searchQuery.isNotEmpty ? _searchQuery.toUpperCase() : null,
        jour: _jourFiltre,
        prixMax: _prixMax,
        societe: _societeFiltre,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          // CORRIGÉ : plus de regroupement nécessaire — Trajet est déjà groupé
          _trajets = response.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Debounce sur la recherche ────────────────────────────────────────────
  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value && mounted) _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: _showFilters ? 290 : 190,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.secondary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Titre + bouton filtres ────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, ${user.prenom} 👋',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const Text(
                              'Où allez-vous ?',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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

                    // ── Barre de recherche ────────────────────────────
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.black87),
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

                    // ── Filtres collapsibles ──────────────────────────
                    if (_showFilters) ...[
                      const SizedBox(height: 10),

                      // Filtre jours — CORRIGÉ : valeurs 'Lun', 'Mar'…
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
                                            : Colors.white)),
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

                      // Filtre prix max
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            const Text('Prix max :',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 8),
                            ..._prixOptions.map((v) {
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
                                      v == null ? 'Tous' : '≤ ${v.toInt()} TND',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: selected
                                              ? AppTheme.primary
                                              : Colors.white,
                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.normal),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      // ── Filtre société — NOUVEAU ──────────────────
                      if (_societesDisponibles.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Icon(Icons.business,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              const Text('Société :',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              const SizedBox(width: 8),
                              // Option "Toutes"
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _societeFiltre = null);
                                    _fetchData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _societeFiltre == null
                                          ? Colors.white
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('Toutes',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _societeFiltre == null
                                                ? AppTheme.primary
                                                : Colors.white,
                                            fontWeight: _societeFiltre == null
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                  ),
                                ),
                              ),
                              ..._societesDisponibles.map((s) {
                                final selected = _societeFiltre == s;
                                final color = _colorForSociete(s);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _societeFiltre = s);
                                      _fetchData();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            selected ? color : Colors.white24,
                                        borderRadius: BorderRadius.circular(12),
                                        border: selected
                                            ? null
                                            : Border.all(color: Colors.white30),
                                      ),
                                      child: Text(s,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: selected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Contenu principal ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── Builder principal ────────────────────────────────────────────────────
  Widget _buildContent() {
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
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
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

    if (_trajets.isEmpty) {
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
              if (_societeFiltre != null) ...[
                const SizedBox(height: 8),
                Text('Société : $_societeFiltre',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        // Compteur + badge société active
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
                    '${_trajets.length} trajet${_trajets.length > 1 ? 's' : ''} '
                    'trouvé${_trajets.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (_societeFiltre != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _colorForSociete(_societeFiltre).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _societeFiltre!,
                      style: TextStyle(
                          color: _colorForSociete(_societeFiltre),
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // CORRIGÉ : SliverList sur List<Trajet> directement
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _TrajetCard(trajet: _trajets[i]),
            childCount: _trajets.length,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte trajet Firestore — reçoit un Trajet (plus _TrajetSummary)
// ─────────────────────────────────────────────────────────────────────────────

class _TrajetCard extends StatelessWidget {
  // CORRIGÉ : Trajet au lieu de _TrajetSummary
  final Trajet trajet;
  const _TrajetCard({required this.trajet});

  @override
  Widget build(BuildContext context) {
    final societeColor = _colorForSociete(trajet.societe);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ReservationBottomSheet.show(
          context,
          trajetNom: trajet.nom,
          ligne: trajet.ligne,
          depart: trajet.departDisplay, // CORRIGÉ : getter sécurisé
          destination: trajet.destinationDisplay, // CORRIGÉ : getter sécurisé
          heureAller: trajet.heureAller, // CORRIGÉ : heureAller
          heureRetour: trajet.heureRetour, // CORRIGÉ : heureRetour
          prix: trajet.prix,
          joursActifs: trajet.joursActifs,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ligne + Route + Société + Nb arrêts ──────────────────
              Row(
                children: [
                  // Badge ligne
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
                  const SizedBox(width: 6),

                  // Badge route
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
                  const SizedBox(width: 6),

                  // Badge société — NOUVEAU
                  if (trajet.societe.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: societeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: societeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        trajet.societe,
                        style: TextStyle(
                            fontSize: 10,
                            color: societeColor,
                            fontWeight: FontWeight.w700),
                      ),
                    ),

                  const Spacer(),

                  // CORRIGÉ : arrets.length au lieu de nbArrets
                  Text(
                    '${trajet.arrets.length} arrêts',
                    style:
                        const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Départ → Destination ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Départ',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey)),
                        Text(
                          // CORRIGÉ : departDisplay (getter sécurisé)
                          trajet.departDisplay,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark),
                        ),
                        Text(
                          // CORRIGÉ : heureAller (plus .aller)
                          trajet.heureAller.isNotEmpty
                              ? trajet.heureAller
                              : '—',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    children: [
                      Icon(Icons.arrow_forward,
                          color: AppTheme.textGrey, size: 20),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Retour',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textGrey)),
                        Text(
                          // CORRIGÉ : destinationDisplay (getter sécurisé)
                          trajet.destinationDisplay,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark),
                        ),
                        Text(
                          // CORRIGÉ : heureRetour (plus .retour)
                          trajet.heureRetour.isNotEmpty
                              ? trajet.heureRetour
                              : '—',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Jours actifs + Prix ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: trajet.joursActifs.map((j) {
                        return Container(
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
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
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
// TrajetCard Firestore — utilisée dans MesVoyagesPage etc. (inchangée)
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
                        const Text('Retour',
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
