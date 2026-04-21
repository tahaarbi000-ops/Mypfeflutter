import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../models/trajet_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class GererTrajetPage extends StatelessWidget {
  const GererTrajetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final mesTrajets = provider.trajets.where((t) => t.controleurId == user.id).toList()
      ..sort((a, b) {
        const order = {'en_cours': 0, 'planifie': 1, 'termine': 2};
        return (order[a.statut] ?? 3).compareTo(order[b.statut] ?? 3);
      });
    final trajetActuel = provider.trajetActuel;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Gérer mes trajets'), automaticallyImplyLeading: false),
      body: mesTrajets.isEmpty
          ? AppWidgets.emptyState('Aucun trajet assigné',
              icon: Icons.route, subtitle: 'Vos trajets apparaîtront ici.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (trajetActuel != null) ...[
                  _TrajetActuelCard(trajet: trajetActuel),
                  const SizedBox(height: 20),
                  const Text('Tous mes trajets',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                ],
                ...mesTrajets.map((t) => _TrajetListCard(
                    trajet: t, isActuel: t.id == trajetActuel?.id)),
              ],
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _TrajetActuelCard extends StatelessWidget {
  final TrajetModel trajet;
  const _TrajetActuelCard({required this.trajet});

  @override
  Widget build(BuildContext context) {
    final ticketCount = context.watch<AppProvider>().ticketsScannesToday
        .where((t) => t.trajetId == trajet.id).length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.success, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.circle, size: 10, color: AppTheme.success),
            const SizedBox(width: 6),
            const Text('Trajet en cours',
                style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$ticketCount passagers validés',
                  style: const TextStyle(
                      color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          Text('${trajet.depart} → ${trajet.destination}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${trajet.heureDepart} – ${trajet.heureArrivee}  •  ${trajet.date}',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showEditDialog(context, trajet),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _terminer(context, trajet),
                icon: const Icon(Icons.stop_circle, size: 16),
                label: const Text('Terminer'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _terminer(BuildContext context, TrajetModel trajet) async {
    final confirm = await AppWidgets.confirmDialog(context,
        title: 'Terminer le trajet',
        content: 'Terminer ${trajet.depart} → ${trajet.destination} ?',
        confirmLabel: 'Terminer',
        confirmColor: AppTheme.error);
    if (!confirm || !context.mounted) return;
    final error = await context.read<AppProvider>().terminerTrajet(trajet.id);
    if (context.mounted) {
      if (error != null) AppWidgets.showError(context, error);
      else AppWidgets.showSuccess(context, 'Trajet terminé.');
    }
  }

  void _showEditDialog(BuildContext context, TrajetModel trajet) {
    _openEditDialog(context, trajet);
  }
}

// ──────────────────────────────────────────────────────────────
class _TrajetListCard extends StatelessWidget {
  final TrajetModel trajet;
  final bool isActuel;
  const _TrajetListCard({required this.trajet, this.isActuel = false});

  Color get _color {
    switch (trajet.statut) {
      case 'en_cours': return AppTheme.success;
      case 'planifie': return AppTheme.accent;
      default: return AppTheme.textGrey;
    }
  }

  String get _label {
    switch (trajet.statut) {
      case 'en_cours': return 'En cours';
      case 'planifie': return 'Planifié';
      default: return 'Terminé';
    }
  }

  IconData get _icon {
    switch (trajet.statut) {
      case 'en_cours': return Icons.play_circle;
      case 'planifie': return Icons.schedule;
      default: return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _color.withOpacity(0.15),
          child: Icon(_icon, color: _color, size: 22),
        ),
        title: Text('${trajet.depart} → ${trajet.destination}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text('${trajet.date}  •  ${trajet.heureDepart}',
            style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_label,
              style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(children: [
                _info('Région', trajet.region),
                _info('Prix', '${trajet.prix.toStringAsFixed(2)} TND'),
                _info('Places', '${trajet.placesRestantes}/${trajet.placesTotal}'),
              ]),
              const SizedBox(height: 12),
              if (trajet.statut == 'planifie')
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => _openEditDialog(context, trajet),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _demarrer(context),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Démarrer'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                  )),
                ])
              else if (trajet.statut == 'termine')
                const Row(children: [
                  Icon(Icons.check_circle, color: AppTheme.textGrey, size: 16),
                  SizedBox(width: 6),
                  Text('Trajet terminé', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  void _demarrer(BuildContext context) async {
    final provider = context.read<AppProvider>();
    if (provider.trajetActuel != null) {
      AppWidgets.showError(context, 'Un trajet est déjà en cours !');
      return;
    }
    final confirm = await AppWidgets.confirmDialog(context,
        title: 'Démarrer le trajet',
        content: 'Démarrer ${trajet.depart} → ${trajet.destination} ?',
        confirmLabel: 'Démarrer',
        confirmColor: AppTheme.success);
    if (!confirm || !context.mounted) return;
    final error = await context.read<AppProvider>().demarrerTrajet(trajet.id);
    if (context.mounted) {
      if (error != null) AppWidgets.showError(context, error);
      else AppWidgets.showSuccess(context, 'Trajet démarré !');
    }
  }
}

// ──────────────────────────────────────────────────────────────
void _openEditDialog(BuildContext context, TrajetModel trajet) {
  final departCtrl = TextEditingController(text: trajet.depart);
  final destCtrl = TextEditingController(text: trajet.destination);
  final hdCtrl = TextEditingController(text: trajet.heureDepart);
  final haCtrl = TextEditingController(text: trajet.heureArrivee);
  final prixCtrl = TextEditingController(text: trajet.prix.toString());

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Modifier le trajet', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: departCtrl,
              decoration: const InputDecoration(labelText: 'Départ', prefixIcon: Icon(Icons.trip_origin))),
          const SizedBox(height: 10),
          TextField(controller: destCtrl,
              decoration: const InputDecoration(labelText: 'Destination', prefixIcon: Icon(Icons.flag))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: hdCtrl,
                decoration: const InputDecoration(labelText: 'Départ', prefixIcon: Icon(Icons.access_time)))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: haCtrl,
                decoration: const InputDecoration(labelText: 'Arrivée', prefixIcon: Icon(Icons.access_time_filled)))),
          ]),
          const SizedBox(height: 10),
          TextField(controller: prixCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix (TND)', prefixIcon: Icon(Icons.payments_outlined))),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final error = await context.read<AppProvider>().mettreAJourTrajet(
              trajet.id,
              depart: departCtrl.text,
              destination: destCtrl.text,
              heureDepart: hdCtrl.text,
              heureArrivee: haCtrl.text,
              prix: double.tryParse(prixCtrl.text),
            );
            if (context.mounted) {
              if (error != null) AppWidgets.showError(context, error);
              else AppWidgets.showSuccess(context, 'Trajet mis à jour !');
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}
