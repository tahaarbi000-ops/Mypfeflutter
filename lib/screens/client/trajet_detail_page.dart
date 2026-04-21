import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trajet_model.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class TrajetDetailPage extends StatelessWidget {
  final TrajetModel trajet;
  const TrajetDetailPage({super.key, required this.trajet});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dejaAchete = provider.mesTickets.any((t) => t.trajetId == trajet.id);
    final complet = trajet.placesRestantes == 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondary, Color(0xFF2A4A6B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppWidgets.statutBadge(trajet.statut),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stopInfo(trajet.depart, trajet.heureDepart, true),
                            Column(children: [
                              const Icon(Icons.directions_bus_rounded,
                                  color: Colors.white54, size: 28),
                              const SizedBox(height: 4),
                              Text(_durationLabel()),
                            ]),
                            _stopInfo(
                                trajet.destination, trajet.heureArrivee, false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Infos card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informations du trajet',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          AppWidgets.infoTile(
                              Icons.calendar_today, 'Date', trajet.date),
                          AppWidgets.infoTile(
                              Icons.location_on, 'Région', trajet.region,
                              iconColor: AppTheme.primary),
                          AppWidgets.infoTile(
                              Icons.event_seat,
                              'Places disponibles',
                              '${trajet.placesRestantes} / ${trajet.placesTotal}',
                              iconColor: trajet.placesRestantes < 5
                                  ? AppTheme.warning
                                  : AppTheme.success),
                          AppWidgets.infoTile(Icons.access_time,
                              'Heure de départ', trajet.heureDepart),
                          AppWidgets.infoTile(Icons.flag, 'Heure d\'arrivée',
                              trajet.heureArrivee),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Itinéraire visuel
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Itinéraire',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _ItineraireWidget(trajet: trajet),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Places bar
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Occupation',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text('${trajet.placesRestantes} places libres',
                                    style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 13)),
                              ]),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (trajet.placesTotal -
                                      trajet.placesRestantes) /
                                  trajet.placesTotal,
                              backgroundColor: Colors.grey[200],
                              color: trajet.placesRestantes < 5
                                  ? AppTheme.error
                                  : AppTheme.success,
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${trajet.placesTotal - trajet.placesRestantes} occupées',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textGrey)),
                                Text(
                                    '${((trajet.placesTotal - trajet.placesRestantes) / trajet.placesTotal * 100).round()}% rempli',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textGrey)),
                              ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Prix + bouton achat
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Prix du billet',
                                  style: TextStyle(
                                      fontSize: 16, color: AppTheme.textGrey)),
                              Text('${trajet.prix.toStringAsFixed(3)} TND',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary)),
                            ]),
                        const SizedBox(height: 16),
                        if (dejaAchete)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.success.withOpacity(0.3)),
                            ),
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: AppTheme.success),
                                  SizedBox(width: 8),
                                  Text('Billet déjà acheté',
                                      style: TextStyle(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w600)),
                                ]),
                          )
                        else if (complet)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.block, color: AppTheme.error),
                                  SizedBox(width: 8),
                                  Text('Complet — plus de places disponibles',
                                      style: TextStyle(
                                          color: AppTheme.error,
                                          fontWeight: FontWeight.w600)),
                                ]),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await AppWidgets.confirmDialog(
                                  context,
                                  title: 'Confirmer l\'achat',
                                  content:
                                      'Acheter un billet pour ${trajet.depart} → ${trajet.destination} au prix de ${trajet.prix.toStringAsFixed(3)} TND ?',
                                  confirmLabel: 'Acheter',
                                );
                                if (confirm && context.mounted) {
                                  final err =
                                      await provider.acheterTicket(trajet.id);
                                  if (!context.mounted) return;
                                  if (err != null) {
                                    AppWidgets.showError(context, err);
                                  } else {
                                    AppWidgets.showSuccess(context,
                                        'Billet acheté ! Retrouvez-le dans "Mes voyages".');
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              icon: const Icon(Icons.confirmation_number),
                              label: const Text('Acheter le billet'),
                              style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stopInfo(String lieu, String heure, bool isDepart) {
    return Column(
      crossAxisAlignment:
          isDepart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(isDepart ? 'Départ' : 'Arrivée',
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(lieu,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        Text(heure,
            style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _durationLabel() {
    try {
      final d = trajet.heureDepart.split(':');
      final a = trajet.heureArrivee.split(':');
      final depMin = int.parse(d[0]) * 60 + int.parse(d[1]);
      final arrMin = int.parse(a[0]) * 60 + int.parse(a[1]);
      final diff = arrMin - depMin;
      if (diff <= 0) return '';
      final h = diff ~/ 60;
      final m = diff % 60;
      return h > 0
          ? '${h}h${m > 0 ? m.toString().padLeft(2, '0') : ''}'
          : '${m}min';
    } catch (_) {
      return '';
    }
  }
}

class _ItineraireWidget extends StatelessWidget {
  final TrajetModel trajet;
  const _ItineraireWidget({required this.trajet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Timeline
        Column(children: [
          Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3), width: 3),
              )),
          Container(width: 2, height: 50, color: Colors.grey[300]),
          Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3), width: 3),
              )),
        ]),
        const SizedBox(width: 16),
        // Labels
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trajet.depart,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(trajet.heureDepart,
                  style:
                      const TextStyle(color: AppTheme.primary, fontSize: 13)),
            ]),
            const SizedBox(height: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trajet.destination,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(trajet.heureArrivee,
                  style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
            ]),
          ],
        )),
      ],
    );
  }
}
