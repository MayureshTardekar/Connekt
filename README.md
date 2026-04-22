# Connekt — Smart Campus Companion

Connekt is an all-in-one smart campus companion app for college students. It combines academic tools, social features, and a unique anonymous peer support zone—all in one beautiful app, built with Flutter and Supabase.

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
  - Supabase Auth (Email/password and OAuth)
  - Supabase Database (PostgreSQL with real-time capabilities)
  - Supabase Storage (Media, PDFs, and images)
- **UI Architecture**: Features custom staggering animations, glassmorphic overlays, and a curated indigo/purple color palette.

## 🏃‍♂️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Supabase project (URL and Anon Key).

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
4. Copy `.env.example` to `.env` for your own reference (the app does **not** read `.env` at runtime; it uses compile-time `--dart-define` values). Fill in real values only locally or in CI.
5. Run the app with **build-time** defines (no secrets in source code):
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
     --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
     --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
   ```
   Optional defines (if you use them): `GEMINI_API_KEY_BACKUP`, `GEMINI_API_KEY_TERTIARY`, `GROQ_API_KEY`, `XAI_API_KEY`, `NVIDIA_API_KEY`, `WEB_REDIRECT_URL`, `USE_MOCK_BACKEND=true`.
   Without `SUPABASE_*`, the app runs with live Supabase **disabled** and logs a one-time setup hint in the console.

## 🔐 Security & Anonymity
The standout feature of Connekt—the **Ghost Zone**—is architected from the database-level to keep interactions 100% anonymous. User identifiers (UIDs) are never attached to posts or comments in the backend. Row Level Security (RLS) policies in Supabase ensure secure data access while maintaining privacy across all app interactions.
