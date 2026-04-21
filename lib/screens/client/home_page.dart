import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: 'Mes voyages'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'Contact'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _TrajetsTab extends StatefulWidget {
  const _TrajetsTab();

  @override
  State<_TrajetsTab> createState() => _TrajetsTabState();
}

class _TrajetsTabState extends State<_TrajetsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    var trajets = provider.trajetsFiltres
        .where((t) => t.statut != 'termine')
        .where((t) => _searchQuery.isEmpty ||
            t.depart.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.destination.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.secondary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour, ${user.prenom} 👋', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const Text('Où allez-vous ?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Icon(Icons.directions_bus_rounded, color: Colors.white54, size: 40),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un trajet...',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Region filter
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: AppProvider.regions.map((region) {
                    final selected = provider.regionFiltre == region;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(region),
                        selected: selected,
                        onSelected: (_) => provider.setRegionFiltre(region),
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: selected ? AppTheme.primary : AppTheme.textGrey,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Trajets list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: trajets.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Aucun trajet disponible', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _TrajetCard(trajet: trajets[i]),
                      childCount: trajets.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrajetCard extends StatelessWidget {
  final TrajetModel trajet;
  const _TrajetCard({required this.trajet});

  Color get _statutColor {
    switch (trajet.statut) {
      case 'en_cours': return AppTheme.success;
      case 'planifie': return AppTheme.accent;
      default: return AppTheme.textGrey;
    }
  }

  String get _statutLabel {
    switch (trajet.statut) {
      case 'en_cours': return 'En cours';
      case 'planifie': return 'Planifié';
      default: return 'Terminé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrajetDetailPage(trajet: trajet))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statutLabel, style: TextStyle(color: _statutColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.location_on, size: 12, color: AppTheme.textGrey),
                      const SizedBox(width: 2),
                      Text(trajet.region, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
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
                        const Text('Départ', style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                        Text(trajet.depart, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        Text(trajet.heureDepart, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.arrow_forward, color: AppTheme.textGrey, size: 20),
                      Text(trajet.date, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Arrivée', style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                        Text(trajet.destination, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        Text(trajet.heureArrivee, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500)),
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
                  Text('${trajet.placesRestantes} places', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const Spacer(),
                  Text('${trajet.prix.toStringAsFixed(2)} TND', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final provider = context.read<AppProvider>();
    final dejaAchete = provider.mesTickets.any((t) => t.trajetId == trajet.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('${trajet.depart} → ${trajet.destination}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoRow(Icons.calendar_today, 'Date', trajet.date),
            _infoRow(Icons.access_time, 'Départ', trajet.heureDepart),
            _infoRow(Icons.flag, 'Arrivée', trajet.heureArrivee),
            _infoRow(Icons.event_seat, 'Places restantes', '${trajet.placesRestantes}/${trajet.placesTotal}'),
            _infoRow(Icons.location_on, 'Région', trajet.region),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prix du billet', style: TextStyle(fontSize: 16)),
                Text('${trajet.prix.toStringAsFixed(2)} TND', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 20),
            if (dejaAchete)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success),
                    SizedBox(width: 8),
                    Text('Billet déjà acheté', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else if (trajet.placesRestantes > 0)
              ElevatedButton.icon(
                onPressed: () {
                  provider.acheterTicket(trajet.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Billet acheté avec succès !'), backgroundColor: AppTheme.success),
                  );
                },
                icon: const Icon(Icons.confirmation_number),
                label: const Text('Acheter le billet'),
              )
            else
              const Text('Complet', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textGrey),
          const SizedBox(width: 10),
          Text('$label : ', style: const TextStyle(color: AppTheme.textGrey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
