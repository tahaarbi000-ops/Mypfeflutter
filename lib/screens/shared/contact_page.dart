import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _sujetCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _type = 'information';
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Contact & Assistance'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contact infos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Contactez-nous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _contactItem(Icons.phone, '+216 71 123 456', 'Téléphone'),
                    _contactItem(Icons.email, 'support@tunistransport.tn', 'Email'),
                    _contactItem(Icons.location_on, 'Avenue Habib Bourguiba, Tunis', 'Adresse'),
                    _contactItem(Icons.access_time, 'Lun-Sam: 07h00 - 20h00', 'Horaires'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _sent
                    ? Column(
                        children: [
                          const SizedBox(height: 20),
                          const Icon(Icons.check_circle, color: AppTheme.success, size: 60),
                          const SizedBox(height: 12),
                          const Text('Message envoyé !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Nous vous répondrons dans les 24h', style: TextStyle(color: AppTheme.textGrey)),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => setState(() { _sent = false; _sujetCtrl.clear(); _messageCtrl.clear(); }),
                            child: const Text('Envoyer un autre message'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Envoyer un message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _type,
                              decoration: const InputDecoration(
                                labelText: 'Type de demande',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'information', child: Text('Demande d\'information')),
                                DropdownMenuItem(value: 'reclamation', child: Text('Réclamation')),
                                DropdownMenuItem(value: 'remboursement', child: Text('Remboursement')),
                                DropdownMenuItem(value: 'autre', child: Text('Autre')),
                              ],
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _sujetCtrl,
                              decoration: const InputDecoration(labelText: 'Sujet', prefixIcon: Icon(Icons.subject)),
                              validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _messageCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                prefixIcon: Icon(Icons.message_outlined),
                                alignLabelWithHint: true,
                              ),
                              validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _sent = true);
                                }
                              },
                              icon: const Icon(Icons.send),
                              label: const Text('Envoyer'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // FAQ
            Card(
              child: ExpansionTile(
                title: const Text('Questions fréquentes', style: TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: false,
                children: [
                  _faqItem('Comment annuler mon billet ?', 'Contactez-nous au moins 2h avant le départ pour un remboursement.'),
                  _faqItem('Puis-je changer de trajet ?', 'Oui, sous réserve de disponibilité, 24h avant le départ.'),
                  _faqItem('Le QR code est-il sécurisé ?', 'Oui, chaque QR code est unique et ne peut être utilisé qu\'une seule fois.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactItem(IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(answer, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const Divider(),
        ],
      ),
    );
  }
}
