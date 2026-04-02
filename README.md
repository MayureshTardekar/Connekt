# Connekt — Smart Campus Companion

Connekt is an all-in-one smart campus companion app for college students. It combines academic tools, social features, and a unique anonymous peer support zone—all in one beautiful app, built with Flutter and Firebase.

## 🚀 Features

- **Dashboard**: A modern, immersive home screen with quick access to all modules and personalized greetings.
- **Ghost Zone (Anonymous Peer Support)**: Vent, seek advice, and share feelings completely anonymously. Post and comment without your identity being logged or linked.
- **Chat**: Fast, reliable one-to-one messaging between students with real-time updates.
- **Notes Sharing (WIP)**: Upload and view educational PDFs and resources categorized by subject.
- **Campus Events (WIP)**: Keep track of campus events and safely post new ones.
- **Lost & Found (WIP)**: Report lost or found campus items with images and detailed descriptions to assist peers.
- **Study Groups (WIP)**: Join or create targeted study sessions for collaboration.

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend / Database**: 
  - Firebase Authentication (Email/password management)
  - Cloud Firestore (Real-time NoSQL Database)
  - Firebase Storage (Media, PDFs, and images)
- **UI Architecture**: Features custom staggering animations, glassmorphic overlays, and a curated indigo/purple color palette.

## 🏃‍♂️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Valid `google-services.json` configured in `android/app` via your Firebase project.

### Installation
1. Clone the repository.
   ```bash
   git clone https://github.com/MayureshTardekar/Connekt
   ```
2. Navigate into the project folder.
   ```bash
   cd Connekt
   ```
3. Install dependencies.
   ```bash
   flutter pub get
   ```
4. Run the app.
   ```bash
   flutter run
   ```

## 🔐 Security & Anonymity
The standout feature of Connekt—the **Ghost Zone**—is architected from the database-level to keep interactions 100% anonymous. User identifiers (UIDs) are never attached to posts or comments in the backend. Comprehensive Firebase Security Rules restrict read/write access securely to ensure complete privacy across all app interactions.
