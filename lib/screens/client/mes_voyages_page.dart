import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/app_provider.dart';
import '../../models/trajet_model.dart';
import '../../utils/app_theme.dart';
import 'ticket_detail_page.dart';

class MesVoyagesPage extends StatelessWidget {
  const MesVoyagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tickets = provider.mesTickets;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mes Voyages'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('${tickets.length} billet${tickets.length > 1 ? 's' : ''}'),
              backgroundColor: Colors.white24,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aucun billet', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  const Text('Achetez votre premier billet depuis l\'accueil', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (_, i) {
                final ticket = tickets[i];
                final trajet = provider.getTrajetById(ticket.trajetId);
                return _TicketCard(ticket: ticket, trajet: trajet);
              },
            ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final TrajetModel? trajet;

  const _TicketCard({required this.ticket, this.trajet});

  Color get _statutColor {
    switch (ticket.statut) {
      case 'valide': return AppTheme.success;
      case 'utilise': return AppTheme.textGrey;
      case 'expire': return AppTheme.error;
      default: return AppTheme.textGrey;
    }
  }

  String get _statutLabel {
    switch (ticket.statut) {
      case 'valide': return 'Valide';
      case 'utilise': return 'Utilisé';
      case 'expire': return 'Expiré';
      default: return ticket.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: ticket))),
        child: Column(
        children: [
          // Header
          Container(
            color: AppTheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trajet != null ? '${trajet!.depart} → ${trajet!.destination}' : 'Trajet inconnu',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statutColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statutColor.withOpacity(0.5)),
                  ),
                  child: Text(_statutLabel, style: TextStyle(color: _statutColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Dashed divider
          Row(
            children: [
              Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppTheme.background, shape: BoxShape.circle)),
              Expanded(child: LayoutBuilder(builder: (_, c) => Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate((c.maxWidth / 8).floor(), (_) =>
                  Container(width: 4, height: 1, color: Colors.grey[300])),
              ))),
              Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppTheme.background, shape: BoxShape.circle)),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (trajet != null) ...[
                        _info('Date', trajet!.date),
                        _info('Départ', trajet!.heureDepart),
                        _info('Arrivée', trajet!.heureArrivee),
                        _info('Prix', '${ticket.prix.toStringAsFixed(2)} TND'),
                        _info('Acheté le', ticket.dateAchat),
                      ],
                      const SizedBox(height: 8),
                      Text('ID: ${ticket.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textGrey, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // QR Code
                GestureDetector(
                  onTap: () => _showQR(context),
                  child: Column(
                    children: [
                      ticket.statut == 'valide'
                          ? QrImageView(
                              data: ticket.id,
                              version: QrVersions.auto,
                              size: 110,
                              backgroundColor: Colors.white,
                            )
                          : Container(
                              width: 110,
                              height: 110,
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code, size: 40, color: Colors.grey[400]),
                                  Text(_statutLabel, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                ],
                              ),
                            ),
                      if (ticket.statut == 'valide')
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Appuyer pour agrandir', style: TextStyle(fontSize: 9, color: AppTheme.textGrey)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
    );
  }

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  void _showQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mon QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(trajet != null ? '${trajet!.depart} → ${trajet!.destination}' : '',
                  style: const TextStyle(color: AppTheme.textGrey)),
              const SizedBox(height: 20),
              QrImageView(
                data: ticket.id,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(ticket.id.substring(0, 8).toUpperCase(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 2, color: AppTheme.textGrey)),
              const SizedBox(height: 20),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            ],
          ),
        ),
      ),
    );
  }
}
