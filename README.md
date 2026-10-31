# SafeGuard+ — Women & Child Safety Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![OpenStreetMap](https://img.shields.io/badge/Map-OpenStreetMap-7EBC6F?logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen)](#)

SafeGuard+ is an autonomous personal safety and crisis intervention mobile application built with Flutter and Cloud Firestore. Designed to protect women and children in distressed or unsafe environments, the app combines one-touch multi-channel SOS emergency broadcasts (SMS, automated call, WhatsApp live tracking, audio siren, strobe flashlight) with real-time guardian linking, GPS tracking, and a peer safety community board.

---

## 📱 App Preview & Screenshots

| Login & Role Selection | Safety Dashboard | Live Safety Map | Community Alerts |
| :---: | :---: | :---: | :---: |
| ![Login Screen](screenshots/login.png) | ![Dashboard](screenshots/dashboard.png) | ![Map Screen](screenshots/map.png) | ![Community](screenshots/community.png) |

*(Note: Replace placeholder paths above with actual device screenshots in `screenshots/`)*

---

## 🚨 Problem Statement

Personal safety threats, unexpected transit delays, and emergencies require immediate intervention. Traditional communication channels (opening a dialer or typing a text) are too slow and often impossible in acute crisis situations. SafeGuard+ solves this through:
- **Instant Multi-Modal Dispatch**: Activating hardware alarms, background GPS logging, and dispatching SMS alerts in a single long-press.
- **Role-Based Family Protection**: Distinct customized workflows for **Women**, **Children**, and **Guardians**.
- **Offline Fault Tolerance**: Queuing SOS events locally on-device and auto-syncing them once network connectivity is restored.

---

## ⚡ Key Features

1. **One-Touch SOS Emergency System**
   - Long-press emergency trigger button with pulsing visual haptics.
   - Automatically queries saved emergency contacts and linked guardians from Firestore.
   - Dispatches background SMS messages with live Google Maps and OpenStreetMap tracking links via native telephony.
   - Launches automated phone call to emergency services (`112`).
   - Opens quick WhatsApp SOS sharing sheet with live coordinates.
   - Plays the device's default system alarm sound in loop mode and activates hardware flashlight strobe beacon.
   - Logs real-time SOS notification documents in Firestore for instant guardian alerting.

2. **Real-Time Live Location Tracking & Mapping**
   - Interactive OpenStreetMap integration powered by `flutter_map` and `latlong2` (no proprietary map API key required).
   - Real-time GPS coordinate streaming (`geolocator`).
   - Guardian live network view displaying active wards and family member pins with status badges.
   - Automatic background movement detection (notifies guardians when a ward moves >200 meters).

3. **Role-Based Dashboards & Guardian Pairing**
   - **Woman Dashboard**: Emergency SOS trigger, quick safety status broadcast ("I am safe", "Need a ride"), emergency contact sheet, and guardian status.
   - **Child Dashboard**: Simplified visual interface, one-touch SOS alert, and quick guardian status.
   - **Guardian Dashboard**: Incoming ward pairing requests, active alert monitor, and family member location map cards.
   - **Unique 6-Digit Guardian ID Pairing**: Wards link with guardians using unique system-generated IDs (e.g. `GDN123456`) with request-acceptance lifecycle management.

4. **Emergency Contacts Management**
   - Private, role-scoped emergency contact directory (`child_emergency_contacts` / `women_emergency_contacts`).
   - Quick-add and delete phone numbers directly synced with Cloud Firestore.

5. **Community Safety Feed**
   - Geolocation-filtered neighborhood community bulletin.
   - Authenticated peer safety posts with urgency flags (`isUrgent`) and post liking.
   - Community-wide broadcast SOS alert for neighborhood alerts.

6. **Offline Sync & Fault Tolerance**
   - `connectivity_plus` network listener detects lost connections.
   - Unsent emergency events are cached locally in `shared_preferences`.
   - Automatically syncs pending alerts to Firestore the instant connectivity resumes.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart 3)
- **Backend / BaaS**:
  - **Firebase Authentication**: Email and Password authentication.
  - **Cloud Firestore**: Real-time NoSQL database with strict security rules.
- **State Management**: `provider` pattern (`UserProvider`, `EmergencyProvider`, `LocationProvider`, `ContactProvider`).
- **Mapping & GIS**: `flutter_map`, `latlong2`, OpenStreetMap tile servers.
- **Hardware Integration**:
  - `telephony`: Android background SMS dispatch.
  - `geolocator`: High-accuracy GPS positioning & stream listeners.
  - `torch_light`: Hardware camera flash control.
  - `flutter_ringtone_player`: Plays device default system alarm sound.
  - `vibration`: Hardware haptic patterns.
  - `url_launcher`: Telephony dialer intents.
  - `share_plus`: Cross-platform OS sharing sheet.

### Folder Structure
```
lib/
├── bottomNav.dart                  # Role-aware bottom navigation shell
├── firebase_options.dart           # FlutterFire generated platform configurations
├── main.dart                       # App entry point, MultiProvider registration
├── models/
│   ├── notification_model.dart     # In-app notification / alert model
│   ├── request_model.dart          # Guardian link request model
│   ├── sos_alert_model.dart        # SOS alert payload model
│   └── user_model.dart             # User profile data model
├── providers/
│   ├── contact_provider.dart       # Emergency contacts state & sync
│   ├── emergency_provider.dart     # SOS orchestration, SMS & alert dispatch
│   ├── location_provider.dart      # GPS tracking, stream listener & geo-fencing
│   └── user_provider.dart          # Auth state, profile management & requests
├── screens/
│   ├── alerts/                     # Notification & SOS banner screen
│   ├── auth/                       # Login, Register, Role Selection
│   ├── circle/                     # Safety Circle & tips
│   ├── community/                  # Peer community safety post feed
│   ├── contacts/                   # Emergency contacts management
│   ├── home/                       # Dashboards (Woman, Child, Guardian)
│   ├── map/                        # Live OpenStreetMap screen
│   └── profile/                    # User profile view & credential settings
├── services/
│   ├── auth_service.dart           # FirebaseAuth wrapper & error mapping
│   ├── community_service.dart      # Community post operations & broadcasts
│   ├── emergency_service.dart      # Siren, Torch, SMS, Call & WhatsApp handlers
│   ├── firestore_service.dart      # Firestore queries, streams & mutations
│   └── offline_service.dart        # SharedPreferences offline queue & sync
├── theme/
│   └── app_theme.dart              # Global color palette & Material theme
└── widgets/
    ├── add_guardian_dialog.dart    # Guardian pairing request modal
    ├── notification_manager.dart   # Global SOS banner listener & audio alarm
    └── tap_effect.dart             # Interactive haptic button feedback
```

---

## 🗄️ Firestore Data Model

```
├── users/{uid}
│   ├── uid: string
│   ├── name: string
│   ├── email: string
│   ├── phone: string
│   ├── role: "woman" | "child" | "guardian"
│   ├── guardianId: string (e.g. "GDN123456")
│   ├── linkedUserIds: array<string>
│   ├── emergencyContacts: array<string>
│   ├── latitude: number
│   ├── longitude: number
│   ├── batteryLevel: number
│   ├── lastSeen: string (ISO8601)
│   └── address: string
│
├── guardian_requests/{requestId}
│   ├── id: string
│   ├── fromId: string
│   ├── toId: string
│   ├── fromName: string
│   ├── fromPhone: string
│   ├── fromRole: string
│   ├── status: "pending" | "accepted" | "rejected"
│   └── timestamp: string (ISO8601)
│
├── notifications/{notificationId}
│   ├── id: string
│   ├── type: "SOS" | "status_update" | "movement" | "guardian_request"
│   ├── senderId: string
│   ├── senderName: string
│   ├── receiverId: string
│   ├── message: string
│   ├── status: "unread" | "read" | "resolved"
│   ├── timestamp: string (ISO8601)
│   └── location: { lat: number, lon: number }
│
├── child_emergency_contacts/{uid}/contacts/{contactId}
│   └── name: string, phone: string
│
├── women_emergency_contacts/{uid}/contacts/{contactId}
│   └── name: string, phone: string
│
├── community_posts/{postId}
│   ├── userId: string, userName: string, content: string, isUrgent: bool, likes: number, timestamp: timestamp
│
├── community_notifications/{notificationId}
│   ├── userId: string, userName: string, message: string, latitude: number, longitude: number, type: string, timestamp: timestamp
│
└── public_locations/{uid}
    ├── uid: string, name: string, role: string, latitude: number, longitude: number, lastUpdated: timestamp
```

---

## 🚀 Setup & Installation Instructions

### Prerequisites
- **Flutter SDK**: `^3.10.4` or higher (`flutter --version`)
- **Dart SDK**: `^3.10.4`
- **Android Studio / Xcode** for mobile builds
- **Firebase CLI** (`npm install -g firebase-tools`)
- **FlutterFire CLI** (`dart pub global activate flutterfire_cli`)

### 1. Clone Repository & Install Dependencies
```bash
git clone https://github.com/your-username/safeguard.git
cd safeguard
flutter pub get
```

### 2. Configure Firebase Project
1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** and activate the **Email/Password** sign-in provider.
3. Enable **Cloud Firestore Database** (start in Production Mode).
4. Run FlutterFire CLI to bind your app:
   ```bash
   flutterfire configure
   ```
   Select your Firebase project and platforms (Android, iOS, Web).

### 3. Deploy Firestore Security Rules & Indexes
Deploy the security rules and composite indexes included in this repository:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```
*(Or paste the contents of `firestore.rules` into Firebase Console > Firestore Database > Rules).*

### 4. Run the Application
```bash
# Debug mode on connected device
flutter run
```

---

## 🔒 Security Notes & Architecture Principles

- **No Third-Party Secret Exposure**: The app relies exclusively on client SDKs and public OpenStreetMap tiles. No paid private API keys or cloud service secrets are embedded in the app bundle.
- **Strict Role-Based Firestore Rules**:
  - User profiles can only be written by the document owner (`request.auth.uid == userId`), with a strict atomic exemption allowing guardians to add themselves to `linkedUserIds` upon request acceptance.
  - Emergency contacts are isolated in subcollections strictly readable and writable only by the account owner.
  - Public coordinates for nearby peer alerts are stored in `public_locations/{uid}` with approximate precision, avoiding exposing full user profiles.
  - Notifications and SOS broadcasts require verified sender IDs matching the caller's authenticated UID.
- **Offline Protection**: Sensitive pending SOS events stored in local SharedPreferences are protected by device sandbox boundaries.

---

## ⚠️ Limitations & Future Improvements

- **SMS via SIM Card**: Background SMS utilizes the device's physical SIM card via Android's `TelephonyManager`. iOS does not permit silent background SMS without showing the native SMS composer (`MFMessageComposeViewController`).
- **Battery Optimization**: Location tracking currently uses high-accuracy GPS streams; integrating dynamic distance filters and geofencing will optimize long-term battery consumption.
