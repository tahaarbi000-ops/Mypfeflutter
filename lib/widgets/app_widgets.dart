import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppWidgets {
  // Badge de statut générique
  static Widget statutBadge(String statut) {
    Color color;
    String label;
    IconData icon;
    switch (statut) {
      case 'en_cours':
        color = AppTheme.success; label = 'En cours'; icon = Icons.play_circle;
        break;
      case 'planifie':
        color = AppTheme.accent; label = 'Planifié'; icon = Icons.schedule;
        break;
      case 'termine':
        color = AppTheme.textGrey; label = 'Terminé'; icon = Icons.check_circle;
        break;
      case 'valide':
        color = AppTheme.success; label = 'Valide'; icon = Icons.verified;
        break;
      case 'utilise':
        color = AppTheme.textGrey; label = 'Utilisé'; icon = Icons.done_all;
        break;
      case 'expire':
        color = AppTheme.error; label = 'Expiré'; icon = Icons.cancel;
        break;
      default:
        color = AppTheme.textGrey; label = statut; icon = Icons.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // Séparateur en pointillés (style billet)
  static Widget ticketDivider() {
    return Row(children: [
      Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppTheme.background, shape: BoxShape.circle)),
      Expanded(child: LayoutBuilder(builder: (_, c) => Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate((c.maxWidth / 9).floor(), (_) =>
          Container(width: 5, height: 1.5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(1)))),
      ))),
      Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppTheme.background, shape: BoxShape.circle)),
    ]);
  }

  // Carte info avec icône
  static Widget infoTile(IconData icon, String label, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor ?? AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        ]),
      ]),
    );
  }

  // Avatar initiales
  static Widget avatar(String prenom, String nom, {double radius = 24, Color? color}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: (color ?? AppTheme.primary).withOpacity(0.15),
      child: Text(
        '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: color ?? AppTheme.primary,
        ),
      ),
    );
  }

  // Empty state
  static Widget emptyState(String message, {IconData icon = Icons.inbox, String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: AppTheme.textGrey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey), textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }

  // Snackbar succès
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(message),
      ]),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Snackbar erreur
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Dialog de confirmation
  static Future<bool> confirmDialog(BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Confirmer',
    Color confirmColor = AppTheme.primary,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
