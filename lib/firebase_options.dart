// lib/firebase_options.dart
// ⚠️  CE FICHIER EST GÉNÉRÉ PAR FlutterFire CLI
// ⚠️  Remplacez les valeurs ci-dessous par celles de votre projet Firebase
//
// ÉTAPES D'INSTALLATION :
// 1. Créez un projet sur https://console.firebase.google.com
// 2. Installez FlutterFire CLI : dart pub global activate flutterfire_cli
// 3. Lancez : flutterfire configure
// 4. Ce fichier sera auto-généré avec vos vraies clés
//
// OU remplacez manuellement les valeurs YOUR_* ci-dessous

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plateforme non supportée');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHe-jNMzq2DuqGb44msnOKTNLixmE4aaQ',
    appId: '1:895056519634:android:c2b05e2b67e83da65e680b',
    messagingSenderId: '895056519634',
    projectId: 'pfe2026-7fd35',
    databaseURL: 'https://pfe2026-7fd35-default-rtdb.firebaseio.com',
    storageBucket: 'pfe2026-7fd35.firebasestorage.app',
  );

  // 🔴 Remplacez par vos valeurs Firebase

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-1HUTNp-KWNCPc3sHpM3_C35pBd-MsPs',
    appId: '1:895056519634:ios:a8a5bc35628168d85e680b',
    messagingSenderId: '895056519634',
    projectId: 'pfe2026-7fd35',
    databaseURL: 'https://pfe2026-7fd35-default-rtdb.firebaseio.com',
    storageBucket: 'pfe2026-7fd35.firebasestorage.app',
    iosBundleId: 'com.example.transportTunisia',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDoldp_Oi3G9w0tTlsYe6YGAwh-W4TmxL4',
    appId: '1:895056519634:web:ee25e75d28f0d1d95e680b',
    messagingSenderId: '895056519634',
    projectId: 'pfe2026-7fd35',
    authDomain: 'pfe2026-7fd35.firebaseapp.com',
    databaseURL: 'https://pfe2026-7fd35-default-rtdb.firebaseio.com',
    storageBucket: 'pfe2026-7fd35.firebasestorage.app',
    measurementId: 'G-R0EPTNM410',
  );

}