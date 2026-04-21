import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageCtrl = PageController();
  int _current = 0;

  final List<_OnboardItem> _items = const [
    _OnboardItem(
      icon: Icons.directions_bus_rounded,
      title: 'Voyagez à travers la Tunisie',
      subtitle: 'Trouvez et réservez vos billets de transport entre toutes les régions de Tunisie, facilement et rapidement.',
      color: AppTheme.secondary,
    ),
    _OnboardItem(
      icon: Icons.qr_code,
      title: 'Votre billet, toujours avec vous',
      subtitle: 'Achetez votre billet en quelques secondes. Votre QR code est disponible hors ligne, prêt à être scanné.',
      color: AppTheme.primary,
    ),
    _OnboardItem(
      icon: Icons.shield_outlined,
      title: 'Sécurisé et fiable',
      subtitle: 'Chaque QR code est unique et chiffré. Le contrôleur valide votre billet en un instant.',
      color: AppTheme.accent,
    ),
  ];

  void _next() {
    if (_current < _items.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Passer', style: TextStyle(color: AppTheme.textGrey)),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _items.length,
                itemBuilder: (_, i) => _OnboardSlide(item: _items[i]),
              ),
            ),
            // Dots + button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _current == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _current == i ? _items[_current].color : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _items[_current].color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _current == _items.length - 1 ? 'Commencer' : 'Suivant',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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
}

class _OnboardSlide extends StatelessWidget {
  final _OnboardItem item;
  const _OnboardSlide({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 72, color: item.color),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            item.subtitle,
            style: const TextStyle(fontSize: 15, color: AppTheme.textGrey, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _OnboardItem({required this.icon, required this.title, required this.subtitle, required this.color});
}
