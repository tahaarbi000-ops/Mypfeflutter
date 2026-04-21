import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/trajet_model.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class TicketDetailPage extends StatelessWidget {
  final TicketModel ticket;
  const TicketDetailPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final trajet = context.read<AppProvider>().getTrajetById(ticket.trajetId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mon billet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => AppWidgets.showSuccess(context, 'Partage non disponible en démo'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Billet stylisé
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header coloré
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.secondary, Color(0xFF2A4A6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Row(children: [
                            Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('TunisTransport', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                          AppWidgets.statutBadge(ticket.statut),
                        ]),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stopCol(trajet?.depart ?? '—', trajet?.heureDepart ?? '—', true),
                            const Column(children: [
                              Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 28),
                              SizedBox(height: 4),
                              Text('Billet', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ]),
                            _stopCol(trajet?.destination ?? '—', trajet?.heureArrivee ?? '—', false),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Séparateur billet
                  AppWidgets.ticketDivider(),
                  // Corps du billet
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Infos passager
                        Row(children: [
                          AppWidgets.avatar(
                            ticket.clientNom.split(' ').first,
                            ticket.clientNom.split(' ').last,
                            radius: 22,
                          ),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Passager', style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                            Text(ticket.clientNom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ]),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _infoCol('Date', trajet?.date ?? ticket.dateAchat)),
                          Expanded(child: _infoCol('Prix', '${ticket.prix.toStringAsFixed(3)} TND')),
                          Expanded(child: _infoCol('Acheté le', ticket.dateAchat)),
                        ]),
                        const SizedBox(height: 20),
                        // QR Code centré
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              if (ticket.statut == 'valide')
                                QrImageView(
                                  data: ticket.id,
                                  version: QrVersions.auto,
                                  size: 200,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.secondary),
                                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.secondary),
                                )
                              else
                                SizedBox(
                                  width: 200, height: 200,
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.qr_code, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 12),
                                    Text(
                                      ticket.statut == 'utilise' ? 'Ticket déjà utilisé' : 'Ticket expiré',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                    ),
                                  ]),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                ticket.id.toUpperCase().replaceRange(8, null, '...'),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  letterSpacing: 2,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                              if (ticket.statut == 'valide') ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Présentez ce QR code au contrôleur',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Infos complémentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Conditions d\'utilisation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _conditionItem(Icons.info_outline, 'Ce billet est strictement personnel et non transférable.'),
                    _conditionItem(Icons.qr_code, 'Le QR code est unique et ne peut être scanné qu\'une seule fois.'),
                    _conditionItem(Icons.schedule, 'Présentez-vous 10 minutes avant le départ.'),
                    _conditionItem(Icons.cancel_outlined, 'Annulation possible jusqu\'à 2h avant le départ.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stopCol(String lieu, String heure, bool isDepart) {
    return Column(
      crossAxisAlignment: isDepart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(isDepart ? 'DÉPART' : 'ARRIVÉE', style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(lieu, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(heure, style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _conditionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppTheme.textGrey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey, height: 1.4))),
      ]),
    );
  }
}
