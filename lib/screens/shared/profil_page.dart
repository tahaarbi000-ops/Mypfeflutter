import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool _editMode = false;
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _telCtrl;
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _newPhoto;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser!;
    _nomCtrl = TextEditingController(text: user.nom);
    _prenomCtrl = TextEditingController(text: user.prenom);
    _telCtrl = TextEditingController(text: user.telephone);
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _telCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AppProvider>().mettreAJourProfil(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      motDePasse: _passCtrl.text.isNotEmpty ? _passCtrl.text : null,
      photo: _newPhoto,
    );
    if (!mounted) return;
    if (error != null) {
      AppWidgets.showError(context, error);
    } else {
      setState(() { _editMode = false; _newPhoto = null; _passCtrl.clear(); _confirmPassCtrl.clear(); });
      AppWidgets.showSuccess(context, 'Profil mis à jour avec succès !');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final isClient = provider.isClient;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        automaticallyImplyLeading: false,
        actions: [
          if (!_editMode)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editMode = true))
          else
            TextButton(
              onPressed: () => setState(() { _editMode = false; _newPhoto = null; }),
              child: const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar avec photo Firebase Storage
              Stack(
                children: [
                  _buildAvatar(user, isClient),
                  if (_editMode)
                    Positioned(
                      right: 0, bottom: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${user.prenom} ${user.nom}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (isClient ? AppTheme.primary : AppTheme.accent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isClient ? '🎫 Client' : '🛂 Contrôleur',
                  style: TextStyle(
                    color: isClient ? AppTheme.primary : AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informations personnelles',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_editMode) ...[
                        Row(children: [
                          Expanded(child: TextFormField(
                            controller: _prenomCtrl,
                            decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(
                            controller: _nomCtrl,
                            decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          )),
                        ]),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)),
                        ),
                        const Divider(height: 28),
                        const Text('Changer le mot de passe',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textGrey)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Nouveau mot de passe (facultatif)',
                              prefixIcon: Icon(Icons.lock_outline)),
                          validator: (v) => v!.isNotEmpty && v.length < 6 ? 'Min. 6 caractères' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Confirmer', prefixIcon: Icon(Icons.lock_outline)),
                          validator: (v) =>
                              _passCtrl.text.isNotEmpty && v != _passCtrl.text
                                  ? 'Ne correspond pas' : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: provider.loading ? null : _save,
                            icon: provider.loading
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save),
                            label: const Text('Enregistrer'),
                          ),
                        ),
                      ] else ...[
                        AppWidgets.infoTile(Icons.person, 'Prénom', user.prenom),
                        AppWidgets.infoTile(Icons.person_outline, 'Nom', user.nom),
                        AppWidgets.infoTile(Icons.email_outlined, 'Email', user.email),
                        AppWidgets.infoTile(Icons.phone_outlined, 'Téléphone', user.telephone),
                        AppWidgets.infoTile(Icons.lock_outline, 'Mot de passe', '••••••••'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isClient)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistiques', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(children: [
                          _statCard('Billets achetés', '${provider.mesTickets.length}',
                              Icons.confirmation_number, AppTheme.primary),
                          const SizedBox(width: 12),
                          _statCard('Voyages effectués',
                              '${provider.mesTickets.where((t) => t.statut == 'utilise').length}',
                              Icons.check_circle, AppTheme.success),
                        ]),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await AppWidgets.confirmDialog(
                      context,
                      title: 'Déconnexion',
                      content: 'Voulez-vous vous déconnecter ?',
                      confirmLabel: 'Déconnecter',
                      confirmColor: AppTheme.error,
                    );
                    if (confirm && context.mounted) {
                      await context.read<AppProvider>().logout();
                      // AuthGate gère la redirection automatiquement
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.error),
                  label: const Text('Se déconnecter', style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(user, bool isClient) {
    final color = isClient ? AppTheme.primary : AppTheme.accent;
    final radius = 52.0;
    if (_newPhoto != null) {
      return CircleAvatar(radius: radius, backgroundImage: FileImage(_newPhoto!));
    }
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(user.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.15),
      child: Text(
        '${user.prenom.isNotEmpty ? user.prenom[0] : ''}${user.nom.isNotEmpty ? user.nom[0] : ''}'.toUpperCase(),
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
