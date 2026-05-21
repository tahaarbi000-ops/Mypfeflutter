// lib/pages/client/reservation_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../services/reservation_service.dart';
import '../../utils/app_theme.dart';
import './ticket_detail_page.dart';

class ReservationBottomSheet extends StatefulWidget {
  final String trajetNom;
  final String ligne;
  final String depart;
  final String destination;
  final String heureAller;
  final String heureRetour;
  final double prix;
  final List<String> joursActifs;

  const ReservationBottomSheet({
    super.key,
    required this.trajetNom,
    required this.ligne,
    required this.depart,
    required this.destination,
    required this.heureAller,
    required this.heureRetour,
    required this.prix,
    required this.joursActifs,
  });

  static Future<void> show(
    BuildContext context, {
    required String trajetNom,
    required String ligne,
    required String depart,
    required String destination,
    required String heureAller,
    required String heureRetour,
    required double prix,
    required List<String> joursActifs,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReservationBottomSheet(
        trajetNom:   trajetNom,
        ligne:       ligne,
        depart:      depart,
        destination: destination,
        heureAller:  heureAller,
        heureRetour: heureRetour,
        prix:        prix,
        joursActifs: joursActifs,
      ),
    );
  }

  @override
  State<ReservationBottomSheet> createState() =>
      _ReservationBottomSheetState();
}

class _ReservationBottomSheetState extends State<ReservationBottomSheet> {
  bool _loading = false;
  DateTime? _selectedDate;          // ← nouvelle variable
  final _service = ReservationService();

  // ── Sélecteur de date ──────────────────────────────────────────────
  Future<void> _choisirDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      locale: const Locale('fr'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppTheme.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _confirmer() async {
    // Vérifier qu'une date est choisie
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une date de voyage.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final user = provider.currentUser!;

    setState(() => _loading = true);

    try {
      final ticketId = await _service.creerReservation(
        clientId:    user.id,
        clientNom:   '${user.prenom} ${user.nom}',
        trajetNom:   widget.trajetNom,
        ligne:       widget.ligne,
        depart:      widget.depart,
        destination: widget.destination,
        heureAller:  widget.heureAller,
        heureRetour: widget.heureRetour,
        prix:        widget.prix,
        joursActifs: widget.joursActifs,
        dateVoyage:  _selectedDate!,   // ← transmis au service
      );

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketPage(
            ticketId:    ticketId,
            depart:      widget.depart,
            destination: widget.destination,
            ligne:       widget.ligne,
            heureAller:  widget.heureAller,
            prix:        widget.prix,
            joursActifs: widget.joursActifs,
            dateVoyage:  _selectedDate!, // ← transmis au ticket
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate == null
        ? 'Choisir une date'
        : DateFormat('EEEE d MMMM yyyy', 'fr').format(_selectedDate!);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Poignée ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Titre ─────────────────────────────────────────────────────
          const Text(
            'Confirmer la réservation',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 24),

          // ── Carte trajet ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ligne ${widget.ligne}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Départ',
                              style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                          Text(widget.depart,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                          Text(widget.heureAller,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppTheme.textGrey),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Arrivée',
                              style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                          Text(widget.destination,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                          Text(widget.heureRetour,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Sélecteur de date ─────────────────────────────────────────
          GestureDetector(
            onTap: _choisirDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _selectedDate == null
                    ? Colors.orange.withOpacity(0.05)
                    : AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedDate == null
                      ? Colors.orange.withOpacity(0.4)
                      : AppTheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: _selectedDate == null ? Colors.orange : AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _selectedDate == null
                            ? Colors.orange[700]
                            : AppTheme.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _selectedDate == null ? Colors.orange : AppTheme.textGrey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Jours actifs ──────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.joursActifs
                .map((j) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(j,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // ── Prix ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total à payer',
                  style: TextStyle(fontSize: 16, color: AppTheme.textGrey)),
              Text(
                '${widget.prix.toStringAsFixed(2)} TND',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bouton confirmer ──────────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirmer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'Confirmer et payer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Annuler ───────────────────────────────────────────────────
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textGrey)),
          ),
        ],
      ),
    );
  }
}