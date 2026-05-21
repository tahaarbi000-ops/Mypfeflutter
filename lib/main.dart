import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/app_provider.dart';
import 'utils/app_theme.dart';
import 'screens/auth/onboarding_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/client/home_page.dart';
import 'screens/controleur/controleur_home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(TuniMoveApp(showOnboarding: !seenOnboarding));
}

class TuniMoveApp extends StatelessWidget {
  final bool showOnboarding;
  const TuniMoveApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('fr')],
        title: 'TuniMove',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (context) => AuthGate(showOnboarding: showOnboarding),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final bool showOnboarding;
  const AuthGate({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Show spinner while Firebase + Firestore are initializing
    if (provider.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not logged in → onboarding (first time) or login (returning)
    if (!provider.isLoggedIn) {
      return showOnboarding ? const OnboardingPage() : const LoginPage();
    }

    if (provider.isClient) {
      return const HomePage();
    } else {
      return const ControleurHomePage();
    }
  }
}