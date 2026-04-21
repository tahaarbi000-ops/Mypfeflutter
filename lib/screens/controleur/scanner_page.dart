import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanning = false;
  bool _flashOn = false;
  bool _processing = false;
  String? _lastMessage;
  bool? _lastSuccess;
  String? _lastTicketId;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    setState(() => _processing = true);

    final error = await context.read<AppProvider>().scannerTicket(raw);

    if (!mounted) return;
    setState(() {
      _processing = false;
      _scanning = false;
      _lastSuccess = error == null;
      _lastMessage = error ?? '✅ Ticket validé avec succès !';
      _lastTicketId = raw;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tickets = provider.ticketsScannesToday;
    final trajetActuel = provider.trajetActuel;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        automaticallyImplyLeading: false,
        actions: [
          if (_scanning)
            IconButton(
              icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () { _ctrl.toggleTorch(); setState(() => _flashOn = !_flashOn); },
            ),
        ],
      ),
      body: Column(
        children: [
          // Trajet actuel banner
          if (trajetActuel != null)
            Container(
              color: AppTheme.success.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const Icon(Icons.route, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${trajetActuel.depart} → ${trajetActuel.destination}',
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 13),
                )),
                Text('${tickets.length} validés',
                    style: const TextStyle(color: AppTheme.success, fontSize: 12)),
              ]),
            )
          else
            Container(
              color: AppTheme.warning.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(children: [
                Icon(Icons.warning_amber, color: AppTheme.warning, size: 18),
                SizedBox(width: 8),
                Text('Aucun trajet en cours — démarrez un trajet d\'abord',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12)),
              ]),
            ),

          // Zone scanner
          Container(
            height: 280,
            color: Colors.black,
            child: _scanning
                ? Stack(children: [
                    MobileScanner(controller: _ctrl, onDetect: _onDetect),
                    // Overlay
                    Center(child: Container(
                      width: 210, height: 210,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primary, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(children: [
                        Positioned(top: 0, left: 0, child: _corner(false, false)),
                        Positioned(top: 0, right: 0, child: _corner(false, true)),
                        Positioned(bottom: 0, left: 0, child: _corner(true, false)),
                        Positioned(bottom: 0, right: 0, child: _corner(true, true)),
                      ]),
                    )),
                    if (_processing)
                      Container(
                        color: Colors.black54,
                        child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                      ),
                    Positioned(
                      bottom: 16, left: 0, right: 0,
                      child: Center(child: ElevatedButton.icon(
                        onPressed: () => setState(() => _scanning = false),
                        icon: const Icon(Icons.stop),
                        label: const Text('Arrêter'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                      )),
                    ),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(Icons.qr_code_scanner, size: 80,
                          color: trajetActuel != null ? Colors.white54 : Colors.white24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trajetActuel != null
                          ? 'Prêt à scanner un billet'
                          : 'Démarrez un trajet pour scanner',
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: trajetActuel != null
                          ? () => setState(() { _scanning = true; _lastMessage = null; })
                          : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scanner un billet'),
                    ),
                  ]),
          ),

          // Résultat scan
          if (_lastMessage != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_lastSuccess! ? AppTheme.success : AppTheme.error).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _lastSuccess! ? AppTheme.success : AppTheme.error, width: 1.2),
              ),
              child: Row(children: [
                Icon(_lastSuccess! ? Icons.check_circle : Icons.error,
                    color: _lastSuccess! ? AppTheme.success : AppTheme.error),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_lastMessage!,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _lastSuccess! ? AppTheme.success : AppTheme.error)),
                  if (_lastTicketId != null)
                    Text('ID: ${_lastTicketId!.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ])),
                if (trajetActuel != null)
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primary),
                    tooltip: 'Scanner un autre',
                    onPressed: () => setState(() {
                      _scanning = true; _lastMessage = null; _lastTicketId = null;
                    }),
                  ),
              ]),
            ),

          // Liste tickets scannés
          Expanded(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  const Text('Tickets validés', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (tickets.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('${tickets.length} total',
                          style: const TextStyle(
                              color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ]),
              ),
              Expanded(
                child: tickets.isEmpty
                    ? AppWidgets.emptyState('Aucun ticket scanné', icon: Icons.qr_code,
                        subtitle: 'Les tickets validés apparaîtront ici.')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: tickets.length,
                        itemBuilder: (_, i) {
                          final t = tickets[i];
                          final trajet = provider.getTrajetById(t.trajetId);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.success,
                                radius: 18,
                                child: Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                              title: Text(t.clientNom,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                trajet != null
                                    ? '${trajet.depart} → ${trajet.destination}'
                                    : 'Trajet inconnu',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${t.prix.toStringAsFixed(2)} TND',
                                      style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  Text(t.id.substring(0, 6).toUpperCase(),
                                      style: const TextStyle(
                                          color: AppTheme.textGrey, fontSize: 10,
                                          fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _corner(bool bottom, bool right) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: bottom ? BorderSide.none : const BorderSide(color: AppTheme.primary, width: 3),
          bottom: bottom ? const BorderSide(color: AppTheme.primary, width: 3) : BorderSide.none,
          left: right ? BorderSide.none : const BorderSide(color: AppTheme.primary, width: 3),
          right: right ? const BorderSide(color: AppTheme.primary, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
