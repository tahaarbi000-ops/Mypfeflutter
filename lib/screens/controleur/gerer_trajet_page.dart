import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../models/trajet_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class GererTrajetPage extends StatefulWidget {
  const GererTrajetPage({super.key});

  @override
  State<GererTrajetPage> createState() => _GererTrajetPageState();
}

class _GererTrajetPageState extends State<GererTrajetPage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static int? _toMinutes(String heure) {
    try {
      heure = heure.trim();
      final reg12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
      final match12 = reg12.firstMatch(heure);
      if (match12 != null) {
        int h = int.parse(match12.group(1)!);
        final int m = int.parse(match12.group(2)!);
        final bool isPM = match12.group(3)!.toUpperCase() == 'PM';
        if (h == 12) h = isPM ? 12 : 0;
        else if (isPM) h += 12;
        return h * 60 + m;
      }
      final parts = heure.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _tempsAvantDepart(TrajetModel t) {
    if (t.statut == 'en_cours' || t.statut == 'termine') return '';
    final depart = _toMinutes(t.heureDepart);
    if (depart == null) return '';
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final diff = depart - nowMinutes;

    if (diff > 60) {
      final h = diff ~/ 60;
      final m = diff % 60;
      return m > 0 ? 'Dans ${h}h${m.toString().padLeft(2, '0')}' : 'Dans ${h}h';
    } else if (diff > 0) {
      return '🟢 Départ dans $diff min';
    } else if (diff == 0) {
      return '🟢 Départ maintenant';
    } else {
      return '🔴 En retard de ${-diff} min';
    }
  }

  static bool _peutDemarrer(TrajetModel t) {
    return t.statut == 'planifie' || t.statut == 'actif';
  }

  static bool _peutTerminer(TrajetModel t) {
    return t.statut == 'en_cours';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final societeUser = user.societe ?? '';

    final mesTrajets = provider.trajets.where((t) {
      if (societeUser.isEmpty) return t.controleurId == user.id;
      return t.societe == societeUser;
    }).toList()
      ..sort((a, b) {
        const order = {'en_cours': 0, 'planifie': 1, 'actif': 2, 'termine': 3};
        return (order[a.statut] ?? 4).compareTo(order[b.statut] ?? 4);
      });

    final trajetActuel = provider.trajetActuel;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes trajets'),
            if (societeUser.isNotEmpty)
              Text(societeUser,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textGrey)),
          ],
        ),
      ),
      body: mesTrajets.isEmpty
          ? AppWidgets.emptyState(
              societeUser.isNotEmpty
                  ? 'Aucun trajet pour $societeUser'
                  : 'Aucun trajet assigné',
              icon: Icons.route,
              subtitle: societeUser.isNotEmpty
                  ? 'Les trajets de votre société apparaîtront ici.'
                  : 'Vos trajets apparaîtront ici.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Badge société ──
                if (societeUser.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.business,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(societeUser,
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const Spacer(),
                      Text(
                        '${mesTrajets.length} trajet${mesTrajets.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Trajet en cours card ──
                if (trajetActuel != null) ...[
                  _TrajetActuelCard(trajet: trajetActuel),
                  const SizedBox(height: 20),
                ],

                const Text('Tous les trajets',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                ...mesTrajets.map((t) => _TrajetCard(
                      trajet: t,
                      isActuel: t.id == trajetActuel?.id,
                      peutDemarrer: _peutDemarrer(t),
                      peutTerminer: _peutTerminer(t),
                      tempsAvant: _tempsAvantDepart(t),
                    )),
              ],
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Trajet EN COURS — big highlighted card
// ══════════════════════════════════════════════════════════════
class _TrajetActuelCard extends StatelessWidget {
  final TrajetModel trajet;
  const _TrajetActuelCard({required this.trajet});

  @override
  Widget build(BuildContext context) {
    final ticketCount = context
        .watch<AppProvider>()
        .ticketsScannesToday
        .where((t) => t.trajetId == trajet.id)
        .length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withOpacity(0.15),
            AppTheme.success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: AppTheme.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text('TRAJET EN COURS',
              style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.people, size: 13, color: AppTheme.success),
              const SizedBox(width: 4),
              Text('$ticketCount validés',
                  style: const TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),

        // ── Route ──
        Row(children: [
          const Icon(Icons.trip_origin, size: 14, color: AppTheme.success),
          const SizedBox(width: 6),
          Text(trajet.depart,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward,
                size: 16, color: AppTheme.textGrey),
          ),
          const Icon(Icons.flag, size: 14, color: AppTheme.error),
          const SizedBox(width: 6),
          Text(trajet.destination,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        Text(
            '${trajet.heureDepart} → ${trajet.heureArrivee}  •  ${trajet.date}',
            style:
                const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
        if (trajet.societe.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(trajet.societe,
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 14),

        // ── Stats ──
        Row(children: [
          _stat(Icons.event_seat,
              '${trajet.placesRestantes}/${trajet.placesTotal}', 'places'),
          const SizedBox(width: 8),
          _stat(Icons.payments_outlined,
              '${trajet.prix.toStringAsFixed(2)}', 'TND'),
          const SizedBox(width: 8),
          _stat(Icons.map_outlined, trajet.region, 'région'),
        ]),
        const SizedBox(height: 16),

        // ── Terminer uniquement ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _terminer(context, trajet),
            icon: const Icon(Icons.stop_circle_outlined, size: 20),
            label: const Text('Terminer le trajet'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 12, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textGrey)),
          ]),
        ),
      );

  void _terminer(BuildContext context, TrajetModel trajet) async {
    final confirm = await AppWidgets.confirmDialog(context,
        title: 'Terminer le trajet',
        content:
            'Terminer ${trajet.depart} → ${trajet.destination} ?',
        confirmLabel: 'Terminer',
        confirmColor: AppTheme.error);
    if (!confirm || !context.mounted) return;
    final error =
        await context.read<AppProvider>().terminerTrajet(trajet.id);
    if (context.mounted) {
      if (error != null) AppWidgets.showError(context, error);
      else AppWidgets.showSuccess(context, 'Trajet terminé.');
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  Card pour TOUS les trajets
// ══════════════════════════════════════════════════════════════
class _TrajetCard extends StatelessWidget {
  final TrajetModel trajet;
  final bool isActuel;
  final bool peutDemarrer;
  final bool peutTerminer;
  final String tempsAvant;

  const _TrajetCard({
    required this.trajet,
    required this.isActuel,
    required this.peutDemarrer,
    required this.peutTerminer,
    required this.tempsAvant,
  });

  Color get _statusColor {
    switch (trajet.statut) {
      case 'en_cours': return AppTheme.success;
      case 'planifie':
      case 'actif':    return AppTheme.accent;
      default:         return AppTheme.textGrey;
    }
  }

  String get _statusLabel {
    switch (trajet.statut) {
      case 'en_cours': return 'En cours';
      case 'planifie': return 'Planifié';
      case 'actif':    return 'Actif';
      default:         return 'Terminé';
    }
  }

  IconData get _statusIcon {
    switch (trajet.statut) {
      case 'en_cours': return Icons.play_circle_filled;
      case 'planifie':
      case 'actif':    return Icons.schedule;
      default:         return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActuel ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isActuel
            ? const BorderSide(color: AppTheme.success, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Top row ──
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _statusColor.withOpacity(0.12),
              child: Icon(_statusIcon, color: _statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trajet.depart} → ${trajet.destination}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 11, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(trajet.date,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textGrey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 11, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(trajet.heureDepart,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textGrey)),
                    ]),
                    if (tempsAvant.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(tempsAvant,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textGrey)),
                    ],
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Info chips ──
          Row(children: [
            _chip(Icons.map_outlined,
                trajet.region.isNotEmpty ? trajet.region : '—',
                AppTheme.primary),
            const SizedBox(width: 6),
            _chip(Icons.payments_outlined,
                '${trajet.prix.toStringAsFixed(2)} TND', AppTheme.accent),
            const SizedBox(width: 6),
            _chip(Icons.event_seat,
                '${trajet.placesRestantes}/${trajet.placesTotal}',
                AppTheme.success),
          ]),

          const SizedBox(height: 14),

          // ══ BOUTONS ══
          if (peutDemarrer) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _demarrer(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Démarrer le trajet'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ] else if (peutTerminer) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _terminer(context),
                icon: const Icon(Icons.stop_circle_outlined, size: 22),
                label: const Text('Terminer le trajet'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.textGrey.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppTheme.textGrey, size: 16),
                    SizedBox(width: 6),
                    Text('Trajet terminé',
                        style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      );

  void _demarrer(BuildContext context) async {
    final provider = context.read<AppProvider>();
    if (provider.trajetActuel != null) {
      AppWidgets.showError(context, 'Un trajet est déjà en cours !');
      return;
    }
    final confirm = await AppWidgets.confirmDialog(context,
        title: 'Démarrer le trajet',
        content:
            'Démarrer ${trajet.depart} → ${trajet.destination} ?',
        confirmLabel: 'Démarrer',
        confirmColor: AppTheme.success);
    if (!confirm || !context.mounted) return;
    final error =
        await context.read<AppProvider>().demarrerTrajet(trajet.id);
    if (context.mounted) {
      if (error != null) AppWidgets.showError(context, error);
      else AppWidgets.showSuccess(context, 'Trajet démarré !');
    }
  }

  void _terminer(BuildContext context) async {
    final confirm = await AppWidgets.confirmDialog(context,
        title: 'Terminer le trajet',
        content:
            'Terminer ${trajet.depart} → ${trajet.destination} ?',
        confirmLabel: 'Terminer',
        confirmColor: AppTheme.error);
    if (!confirm || !context.mounted) return;
    final error =
        await context.read<AppProvider>().terminerTrajet(trajet.id);
    if (context.mounted) {
      if (error != null) AppWidgets.showError(context, error);
      else AppWidgets.showSuccess(context, 'Trajet terminé.');
    }
  }
}