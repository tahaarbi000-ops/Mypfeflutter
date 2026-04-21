# 🚌 TunisTransport — Flutter + Firebase

Application mobile de transport en Tunisie avec **Firebase Auth**, **Cloud Firestore** et **Firebase Storage**.

---

## 🏗️ Architecture Firebase

```
Firebase Project
├── Authentication       → Email/Password
├── Cloud Firestore      → users / trajets / tickets
└── Firebase Storage     → photos de profil
```

### Collections Firestore

| Collection | Description |
|---|---|
| `users/{uid}` | Profil utilisateur (nom, rôle, téléphone…) |
| `trajets/{id}` | Trajets (départ, destination, région, statut…) |
| `tickets/{id}` | Billets achetés avec QR code ID |

---

## 🚀 Installation

### 1. Prérequis
```bash
flutter --version   # >= 3.0.0
dart --version      # >= 3.0.0
```

### 2. Créer le projet Firebase

1. Aller sur [console.firebase.google.com](https://console.firebase.google.com)
2. Créer un nouveau projet **TunisTransport**
3. Activer **Authentication > Email/Password**
4. Créer la base **Firestore** (mode production)
5. Activer **Storage**

### 3. Configurer FlutterFire CLI (recommandé)

```bash
# Installer la CLI
dart pub global activate flutterfire_cli

# Dans le dossier du projet
flutterfire configure
# → Sélectionnez votre projet Firebase
# → Choisissez Android + iOS
# → lib/firebase_options.dart sera généré automatiquement
```

### 4. OU configuration manuelle

**Android :** Téléchargez `google-services.json` → placez dans `android/app/`

**iOS :** Téléchargez `GoogleService-Info.plist` → placez dans `ios/Runner/`

**Puis** remplacez les valeurs `YOUR_*` dans `lib/firebase_options.dart`

### 5. Déployer les règles de sécurité

```bash
npm install -g firebase-tools
firebase login
firebase init   # choisir Firestore + Storage
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### 6. Lancer l'application

```bash
flutter pub get
flutter run
```

---

## 📱 Fonctionnalités

### 👤 Client
| Page | Firebase utilisé |
|---|---|
| Connexion | Firebase Auth |
| Inscription | Firebase Auth + Firestore |
| Accueil + filtre régions | Firestore stream (temps réel) |
| Achat billet | Firestore transaction |
| Mes voyages + QR Code | Firestore stream |
| Modifier profil | Firestore + Storage (photo) |

### 🛂 Contrôleur
| Page | Firebase utilisé |
|---|---|
| Dashboard | Firestore stream |
| Scanner QR | Firestore update (atomic) |
| Gérer trajet | Firestore update |
| Modifier profil | Firestore + Storage (photo) |

---

## 🔒 Règles de sécurité

Les règles Firestore garantissent :
- Un utilisateur ne peut **lire/modifier que son propre profil**
- Seul un **contrôleur** peut créer/gérer des trajets
- Seul un **client** peut acheter un billet (pour lui-même)
- Seul un **contrôleur** peut scanner/valider un ticket
- **L'email et le rôle** ne peuvent jamais être modifiés

---

## 📂 Structure du projet

```
lib/
├── main.dart                        ← Firebase init + AuthGate
├── firebase_options.dart            ← Config Firebase (à compléter)
├── models/
│   ├── user_model.dart
│   └── trajet_model.dart            ← TrajetModel + TicketModel
├── services/
│   ├── auth_service.dart            ← Firebase Auth
│   ├── firestore_service.dart       ← Cloud Firestore CRUD
│   ├── storage_service.dart         ← Firebase Storage (photos)
│   └── app_provider.dart            ← ChangeNotifier global
├── utils/app_theme.dart
├── widgets/app_widgets.dart
└── screens/
    ├── auth/
    │   ├── onboarding_page.dart
    │   ├── login_page.dart
    │   ├── inscription_page.dart
    │   └── reset_password_page.dart ← Mot de passe oublié
    ├── client/
    │   ├── home_page.dart
    │   ├── trajet_detail_page.dart
    │   ├── mes_voyages_page.dart
    │   └── ticket_detail_page.dart
    ├── controleur/
    │   ├── controleur_home_page.dart
    │   ├── scanner_page.dart
    │   └── gerer_trajet_page.dart
    └── shared/
        ├── contact_page.dart
        └── profil_page.dart         ← Upload photo Firebase Storage
```

---

## 🌐 Temps réel

Grâce aux **streams Firestore**, toute mise à jour est reflétée instantanément :
- La liste des trajets se met à jour sans recharger
- Les tickets scannés apparaissent en temps réel chez le contrôleur
- Les places restantes se décrément en direct après un achat

---

## ⚠️ Notes importantes

- **minSdk Android : 21** (requis par Firebase)
- **multiDexEnabled : true** (requis pour Firebase sur Android)
- iOS : `NSCameraUsageDescription` déjà dans `Info.plist`
- Les données de démo sont seeded automatiquement à la première connexion contrôleur
