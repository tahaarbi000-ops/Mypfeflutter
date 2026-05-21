// lib/pages/client/ticket_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/app_theme.dart';

class TicketPage extends StatelessWidget {
  final String ticketId;
  final String depart;
  final String destination;
  final String ligne;
  final String heureAller;
  final double prix;
  final List<String> joursActifs;
  final DateTime dateVoyage; // ← nouveau

  const TicketPage({
    super.key,
    required this.ticketId,
    required this.depart,
    required this.destination,
    required this.ligne,
    required this.heureAller,
    required this.prix,
    required this.joursActifs,
    required this.dateVoyage, // ← nouveau
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatee =
        DateFormat('EEEE d MMMM yyyy', 'fr').format(dateVoyage); // ← formatage

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Mon Ticket'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Icône succès ──────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 48, color: AppTheme.success),
            ),
            const SizedBox(height: 14),

            const Text(
              'Réservation confirmée !',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Présentez ce QR code au contrôleur',
              style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 32),

            // ── Carte ticket ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── En-tête coloré ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        // Badge ligne
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Ligne $ligne',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Date du voyage ──────────────────────────── ← nouveau
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              dateFormatee,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Départ ─→ Destination
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Départ',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11)),
                                  Text(depart,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text(heureAller,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white60, size: 22),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Arrivée',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11)),
                                  Text(destination,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Séparateur en pointillés ────────────────────────
                  _DashedDivider(),

                  // ── QR code ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 24),
                    child: Column(
                      children: [
                        QrImageView(
                          data: ticketId,
                          version: QrVersions.auto,
                          size: 190,
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

                        // Référence courte
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticketId.substring(0, 8).toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15,
                              letterSpacing: 3,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Séparateur en pointillés ────────────────────────
                  _DashedDivider(),

                  // ── Infos bas de ticket ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Date voyage ← nouveau
                        _InfoRow(
                          label: 'Date du voyage',
                          value: DateFormat('dd/MM/yyyy').format(dateVoyage),
                        ),
                        const SizedBox(height: 10),

                        // Prix
                        _InfoRow(
                          label: 'Prix payé',
                          value: '${prix.toStringAsFixed(2)} TND',
                          valueStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 10),

                        // Jours valides
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jours valides',
                                style: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 13)),
                            Wrap(
                              spacing: 4,
                              children: joursActifs
                                  .map((j) => Text(
                                        j,
                                        style: const TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Badge statut
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 16, color: AppTheme.success),
                              SizedBox(width: 6),
                              Text(
                                'TICKET VALIDE',
                                style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5),
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
            const SizedBox(height: 32),

            // ── Bouton retour accueil ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  "Retour à l'accueil",
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets helpers ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
        Text(value,
            style: valueStyle ??
                const TextStyle(color: AppTheme.textDark, fontSize: 14)),
      ],
    );
  }
}

/// Séparateur en pointillés avec encoches sur les côtés (effet ticket de bus)
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final count = (constraints.maxWidth / 10).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  count,
                  (_) => Container(
                      width: 5, height: 1, color: Colors.grey[300]),
                ),
              );
            },
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
        ),
      ],
    );
  }
}