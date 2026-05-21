// lib/pages/client/mes_voyages_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/app_provider.dart';
import '../../services/reservation_service.dart';
import '../../models/reservation_model.dart';
import '../../utils/app_theme.dart';

class MesVoyagesPage extends StatelessWidget {
  const MesVoyagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        title: const Text('Mes Voyages'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<ReservationModel>>(
        stream: ReservationService().reservationsClient(user.id),
        builder: (context, snapshot) {
          // ── Chargement ───────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Erreur ───────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            );
          }

          final reservations = snapshot.data ?? [];

          // ── Vide ─────────────────────────────────────────────────────
          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aucun billet',
                      style: TextStyle(
                          fontSize: 18, color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  const Text(
                    "Achetez votre premier billet depuis l'accueil",
                    style:
                        TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // ── Liste ─────────────────────────────────────────────────────
          return Column(
            children: [
              // Badge compteur
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: AppTheme.secondary.withOpacity(0.08),
                child: Text(
                  '${reservations.length} billet${reservations.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservations.length,
                  itemBuilder: (_, i) =>
                      _ReservationCard(reservation: reservations[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte réservation
// ─────────────────────────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  Color get _statutColor {
    switch (reservation.statut) {
      case 'valide':
        return AppTheme.success;
      case 'utilise':
        return AppTheme.textGrey;
      case 'annule':
        return Colors.red;
      default:
        return AppTheme.textGrey;
    }
  }

  String get _statutLabel {
    switch (reservation.statut) {
      case 'valide':
        return 'Valide';
      case 'utilise':
        return 'Utilisé';
      case 'annule':
        return 'Annulé';
      default:
        return reservation.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── En-tête coloré ────────────────────────────────────────────
          Container(
            color: AppTheme.secondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.directions_bus,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${reservation.depart} → ${reservation.destination}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statutColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _statutColor.withOpacity(0.6)),
                  ),
                  child: Text(
                    _statutLabel,
                    style: TextStyle(
                        color: _statutColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Séparateur en pointillés ──────────────────────────────────
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      (c.maxWidth / 8).floor(),
                      (_) => Container(
                          width: 4, height: 1, color: Colors.grey[300]),
                    ),
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle),
              ),
            ],
          ),

          // ── Corps ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Infos textuelles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _info('Ligne', reservation.ligne),
                      _info('Départ', reservation.heureAller),
                      _info('Arrivée', reservation.heureRetour),
                      _info('Prix',
                          '${reservation.prix.toStringAsFixed(2)} TND'),
                      _info('Acheté le', reservation.dateAchatStr),
                      const SizedBox(height: 8),
                      // Jours actifs
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: reservation.joursActifs
                            .map((j) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.success.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(j,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w600)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      // Référence courte
                      Text(
                        'Réf: ${reservation.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textGrey,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // QR code
                GestureDetector(
                  onTap: () => _showQR(context),
                  child: Column(
                    children: [
                      reservation.statut == 'valide'
                          ? QrImageView(
                              data: reservation.id,
                              version: QrVersions.auto,
                              size: 110,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppTheme.primary,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape:
                                    QrDataModuleShape.square,
                                color: AppTheme.textDark,
                              ),
                            )
                          : Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code,
                                      size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 4),
                                  Text(_statutLabel,
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                      if (reservation.statut == 'valide')
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Appuyer pour agrandir',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textGrey)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textGrey)),
            Flexible(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  void _showQR(BuildContext context) {
    if (reservation.statut != 'valide') return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mon QR Code',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '${reservation.depart} → ${reservation.destination}',
                style:
                    const TextStyle(color: AppTheme.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: reservation.id,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reservation.id.substring(0, 8).toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    letterSpacing: 2,
                    color: AppTheme.textGrey),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}