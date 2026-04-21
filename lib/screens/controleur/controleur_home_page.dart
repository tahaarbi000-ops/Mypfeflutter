import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../shared/contact_page.dart';
import '../shared/profil_page.dart';
import 'scanner_page.dart';
import 'gerer_trajet_page.dart';

class ControleurHomePage extends StatefulWidget {
  const ControleurHomePage({super.key});

  @override
  State<ControleurHomePage> createState() => _ControleurHomePageState();
}

class _ControleurHomePageState extends State<ControleurHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardTab(),
    ScannerPage(),
    GererTrajetPage(),
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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Tableau de bord'),
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: 'Scanner'),
          NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Trajet'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final trajetActuel = provider.trajetActuel;
    final ticketsScannes = provider.ticketsScannesToday;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.secondary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Contrôleur ${user.prenom}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const Text('Tableau de bord',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.badge,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(
                  children: [
                    _statCard('Tickets scannés', '${ticketsScannes.length}',
                        Icons.qr_code_scanner, AppTheme.success),
                    const SizedBox(width: 12),
                    _statCard(
                        'Trajets gérés',
                        '${provider.trajets.where((t) => t.controleurId == user.id).length}',
                        Icons.route,
                        AppTheme.accent),
                  ],
                ),
                const SizedBox(height: 20),
                // Trajet actuel
                if (trajetActuel != null) ...[
                  const Text('Trajet en cours',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(children: [
                                  Icon(Icons.circle,
                                      size: 8, color: AppTheme.success),
                                  SizedBox(width: 4),
                                  Text('En cours',
                                      style: TextStyle(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    const Text('De',
                                        style: TextStyle(
                                            color: AppTheme.textGrey,
                                            fontSize: 12)),
                                    Text(trajetActuel.depart,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Text(trajetActuel.heureDepart,
                                        style: const TextStyle(
                                            color: AppTheme.primary)),
                                  ])),
                              const Icon(Icons.arrow_forward,
                                  color: AppTheme.textGrey),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                    const Text('À',
                                        style: TextStyle(
                                            color: AppTheme.textGrey,
                                            fontSize: 12)),
                                    Text(trajetActuel.destination,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Text(trajetActuel.heureArrivee,
                                        style: const TextStyle(
                                            color: AppTheme.primary)),
                                  ])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Recent scans
                const Text('Derniers tickets scannés',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (ticketsScannes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Icon(Icons.qr_code, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('Aucun ticket scanné',
                            style: TextStyle(color: Colors.grey[400])),
                      ]),
                    ),
                  )
                else
                  ...ticketsScannes.take(5).map((t) {
                    final trajet = provider.getTrajetById(t.trajetId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.success,
                          child:
                              Icon(Icons.check, color: Colors.white, size: 18),
                        ),
                        title: Text(t.clientNom,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                            trajet != null
                                ? '${trajet.depart} → ${trajet.destination}'
                                : '—',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text('${t.prix.toStringAsFixed(2)} TND',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
