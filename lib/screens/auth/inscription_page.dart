import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});
  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AppProvider>().inscrire(
          nom: _nomCtrl.text.trim(),
          prenom: _prenomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telephone: _telCtrl.text.trim(),
          motDePasse: _passCtrl.text,
          role: 'client', // always client
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Compte créé avec succès !'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
      // Pop back to login, AuthGate will handle navigation
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AppProvider>().loading;
    return Scaffold(
      backgroundColor: AppTheme.secondary,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Inscription',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child:
                          _field(_prenomCtrl, 'Prénom', Icons.person_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_nomCtrl, 'Nom', Icons.person_outline),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _field(
                    _emailCtrl,
                    'Email',
                    Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains('@') ? 'Email invalide' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _telCtrl,
                    'Téléphone',
                    Icons.phone_outlined,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        v!.length < 6 ? 'Min. 6 caractères' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => v != _passCtrl.text
                        ? 'Les mots de passe ne correspondent pas'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : _inscrire,
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("S'inscrire"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator ?? (v) => v!.isEmpty ? 'Champ requis' : null,
    );
  }
}
