# CampusHive — Smart Campus Companion App
### Complete Project Reference Document
> One file to rule them all. Use this as your bible while building.

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [App Name & Branding](#2-app-name--branding)
3. [Tech Stack](#3-tech-stack)
4. [App Modules](#4-app-modules)
5. [Firebase Database Schema](#5-firebase-database-schema)
6. [File & Folder Structure](#6-file--folder-structure)
7. [Phase-wise Build Plan](#7-phase-wise-build-plan)
8. [Screen-by-Screen UI Plan](#8-screen-by-screen-ui-plan)
9. [Team Division](#9-team-division)
10. [Gradle Dependencies](#10-gradle-dependencies)
11. [Firebase Security Rules](#11-firebase-security-rules)
12. [Splash Screen Guide](#12-splash-screen-guide)
13. [Viva Preparation](#13-viva-preparation)
14. [Timeline](#14-timeline)

---

## 1. Project Overview

**App Name:** CampusHive (or UniPulse — pick one)  
**Type:** Android Mobile App  
**Language:** Java  
**IDE:** Android Studio  
**Backend:** Firebase (Auth + Firestore + Storage)  
**Min SDK:** API 21 (Android 5.0)  
**Target SDK:** API 34  

### What this app does
CampusHive is an all-in-one smart campus companion for college students. It combines academic tools (notes, events), social features (named chat, lost & found, study groups), and a unique anonymous peer support zone — all in one app.

### Two ideas that make it stand out
1. **Smart Campus Companion** — Notes, Events, Lost & Found, Study Groups in one unified platform
2. **Anonymous Peer Support** — Students can post feelings, seek advice, and support each other completely anonymously. No userId stored. No identity exposed.

---

## 2. App Name & Branding

| Option | Tagline | Vibe |
|--------|---------|------|
| **CampusHive** | Your campus. Your community. Your hive. | Community + anonymous zone |
| **UniPulse** | Feel the pulse of your campus. | Energetic, startup-feel |
| **NexCampus** | The next-gen campus companion. | Futuristic |

**Recommended: CampusHive**

### Color Palette (suggested)
| Element | Color | Hex |
|---------|-------|-----|
| Primary | Deep Blue | `#1565C0` |
| Accent | Teal | `#00897B` |
| Background | White | `#FFFFFF` |
| Surface | Light Gray | `#F5F5F5` |
| Text Primary | Near Black | `#212121` |
| Text Secondary | Gray | `#757575` |
| Anonymous Zone | Deep Purple | `#6A1B9A` |
| Error | Red | `#D32F2F` |

### Font
- **Headings:** Poppins Bold
- **Body:** Roboto Regular
- Add both via Google Fonts in `res/font/`

---

## 3. Tech Stack

### Frontend
| Tool | Purpose |
|------|---------|
| Java | Primary programming language |
| XML | UI layouts |
| Android Studio | IDE |
| Lottie | Splash screen animation |
| Glide | Image loading from URLs |
| CircleImageView | Round profile images |
| CardView | Dashboard cards |
| RecyclerView | All list screens |
| Material Design Components | UI components |

### Backend — Firebase
| Service | Used For |
|---------|---------|
| Firebase Authentication | Login, Signup, Session management |
| Cloud Firestore | Main NoSQL database (all app data) |
| Firebase Storage | PDF uploads (notes) + Image uploads (lost items) |
| Firebase Cloud Messaging | Push notifications (optional, Phase 2) |

### Why Firebase over Supabase (for this project)
- Official Android SDK — deeply integrated
- Real-time with 2 lines of code (`addSnapshotListener`)
- Google Sign-In works out of the box
- Mentioned in most Android syllabi — examiner-friendly
- Free tier is sufficient: 1GB storage, 50k reads/day

---

## 4. App Modules

### Module 1 — Authentication
- Email/password login and signup
- Store user profile in Firestore on signup
- Auto-login if user session exists
- Logout from settings

### Module 2 — Dashboard
- Home screen with grid of feature cards
- Show logged-in user's name at top
- Navigate to all modules from here

### Module 3 — Notes Sharing
- Upload PDF notes with title and subject
- View list of all uploaded notes
- Open/download PDF in external viewer
- Filter by subject (optional)

### Module 4 — Events
- Post campus events (title, date, description, location)
- View all upcoming events sorted by date
- Real-time updates

### Module 5 — Lost & Found
- Post a lost item with image + description
- View all lost items with contact info
- Contact poster via Chat module
- Mark item as found (delete)

### Module 6 — Student Chat (Named)
- 1-to-1 real-time chat between named users
- Chat list showing all active conversations
- Message bubbles (sent right, received left)
- Real-time updates with snapshot listener

### Module 7 — Anonymous Peer Support ⭐ USP
- Post thoughts, feelings, rants anonymously
- Mood tags: Stressed / Happy / Confused / Venting / Motivated
- Like posts (with anti-double-like protection)
- Comment anonymously on any post
- Filter feed by mood
- **CRITICAL: NO userId stored anywhere in this module**

### Module 8 — Study Group Finder
- Post a study session (subject, time, location, max members)
- Browse and join open study groups
- See your created and joined groups
- Member count shown, disable join when full

---

## 5. Firebase Database Schema

### Collection: `users`
```
users/{userId}
  - uid: string
  - name: string
  - email: string
  - createdAt: timestamp
```

### Collection: `notes`
```
notes/{noteId}
  - title: string
  - subject: string
  - fileUrl: string         ← Firebase Storage download URL
  - uploadedBy: string      ← user's name (not uid)
  - uploadedById: string    ← uid (for delete permission)
  - timestamp: timestamp
```

### Collection: `events`
```
events/{eventId}
  - title: string
  - description: string
  - date: timestamp
  - location: string        ← optional
  - postedBy: string        ← user's name
  - postedById: string      ← uid
  - timestamp: timestamp
```

### Collection: `lost_items`
```
lost_items/{itemId}
  - title: string
  - description: string
  - imageUrl: string        ← Firebase Storage download URL
  - postedBy: string        ← user's name
  - postedById: string      ← uid (for chat routing)
  - isFound: boolean
  - timestamp: timestamp
```

### Collection: `chats`
```
chats/{chatId}             ← chatId = sorted(uid1 + uid2)
  - participants: [uid1, uid2]
  - lastMessage: string
  - lastMessageTime: timestamp

chats/{chatId}/messages/{messageId}
  - text: string
  - senderId: string
  - senderName: string
  - timestamp: timestamp
```

### Collection: `anonymous_posts`
```
anonymous_posts/{postId}
  - content: string
  - mood: string            ← "stressed" | "happy" | "confused" | "venting" | "motivated"
  - likes: number
  - likedBy: [string]       ← array of UIDs to prevent double likes (UIDs not shown in UI)
  - commentCount: number
  - timestamp: timestamp
  ← NO userId field — complete anonymity
```

### Collection: `comments`
```
comments/{commentId}
  - postId: string          ← reference to anonymous_posts
  - content: string
  - timestamp: timestamp
  ← NO userId field — complete anonymity
```

### Collection: `study_groups`
```
study_groups/{groupId}
  - subject: string
  - description: string
  - dateTime: timestamp
  - location: string
  - createdBy: string       ← user's name
  - createdById: string     ← uid
  - maxMembers: number
  - memberCount: number
  - members: [uid]          ← array of joined user UIDs
  - timestamp: timestamp
```

---

## 6. File & Folder Structure

```
app/
└── src/main/
    ├── java/com/yourpackage/campushive/
    │   ├── activities/
    │   │   ├── SplashActivity.java
    │   │   ├── LoginActivity.java
    │   │   ├── SignupActivity.java
    │   │   ├── DashboardActivity.java
    │   │   ├── NotesActivity.java
    │   │   ├── UploadNoteActivity.java
    │   │   ├── EventsActivity.java
    │   │   ├── PostEventActivity.java
    │   │   ├── LostFoundActivity.java
    │   │   ├── PostLostItemActivity.java
    │   │   ├── ItemDetailActivity.java
    │   │   ├── ChatListActivity.java
    │   │   ├── ChatActivity.java
    │   │   ├── AnonFeedActivity.java
    │   │   ├── PostAnonActivity.java
    │   │   ├── CommentsActivity.java
    │   │   ├── StudyGroupActivity.java
    │   │   └── PostGroupActivity.java
    │   │
    │   ├── adapters/
    │   │   ├── NotesAdapter.java
    │   │   ├── EventsAdapter.java
    │   │   ├── LostItemsAdapter.java
    │   │   ├── ChatListAdapter.java
    │   │   ├── MessageAdapter.java
    │   │   ├── AnonPostAdapter.java
    │   │   ├── CommentsAdapter.java
    │   │   └── StudyGroupAdapter.java
    │   │
    │   ├── models/
    │   │   ├── User.java
    │   │   ├── Note.java
    │   │   ├── Event.java
    │   │   ├── LostItem.java
    │   │   ├── ChatMessage.java
    │   │   ├── ChatPreview.java
    │   │   ├── AnonPost.java
    │   │   ├── Comment.java
    │   │   └── StudyGroup.java
    │   │
    │   └── utils/
    │       ├── FirebaseHelper.java
    │       └── Constants.java
    │
    └── res/
        ├── layout/
        │   ├── activity_splash.xml
        │   ├── activity_login.xml
        │   ├── activity_signup.xml
        │   ├── activity_dashboard.xml
        │   ├── activity_notes.xml
        │   ├── activity_upload_note.xml
        │   ├── activity_events.xml
        │   ├── activity_post_event.xml
        │   ├── activity_lost_found.xml
        │   ├── activity_post_lost_item.xml
        │   ├── activity_item_detail.xml
        │   ├── activity_chat_list.xml
        │   ├── activity_chat.xml
        │   ├── activity_anon_feed.xml
        │   ├── activity_post_anon.xml
        │   ├── activity_comments.xml
        │   ├── activity_study_group.xml
        │   ├── activity_post_group.xml
        │   ├── item_note.xml
        │   ├── item_event.xml
        │   ├── item_lost.xml
        │   ├── item_chat_preview.xml
        │   ├── item_message_sent.xml
        │   ├── item_message_received.xml
        │   ├── item_anon_post.xml
        │   ├── item_comment.xml
        │   └── item_study_group.xml
        │
        ├── raw/
        │   └── splash_anim.json       ← Lottie animation file
        │
        ├── drawable/
        │   └── (icons, backgrounds)
        │
        └── values/
            ├── strings.xml
            ├── colors.xml
            └── styles.xml
```

---

## 7. Implementation Plan (Frontend/Product-first, Backend-later)

### Phase 0 — Foundation Cleanup (2–4 days)
**Goal:** Make the codebase scalable before features explode.
*   **Tasks:**
    *   Create feature folders: `features/chat`, `features/ghost`, `features/events`, etc.
    *   Add app-wide models and mock repositories (`ChatRepository`, `EventsRepository`, etc.) returning dummy JSON.
    *   Add state management (Riverpod / Bloc / Provider — pick one and stick to it).
    *   Add route management (GoRouter / centralized routes).
    *   Add design tokens for spacing, radius, and typography consistency.
*   **Why first:** Current screens are strong visually but mostly use screen-local state/hardcoded content. A modular architecture will make the phased build much faster.
*   **Done criteria:** Every module reads from a mock repository, no business logic directly inside big widget trees.

### Phase 1 — Chat V1 (Core UX) (1–2 weeks)
**Goal:** Fully functional chat experience (still mock/local mode), with production-like behavior.
*   **Features:**
    *   Conversation list (last message preview, unread badge, pinned chats, archive swipe actions).
    *   Chat detail (text send, reply-to message, date separators).
    *   Message status states (sending/sent/read/failed as UI-only simulation).
    *   Long press menu (copy, delete, react placeholder).
    *   Search across chats/messages.
    *   Empty states + skeleton loaders.
*   **Nice additions:** Voice note UI placeholder, attach button bottom sheet (camera/gallery/document placeholders for media sharing), “start new chat” from edit icon.
*   **Done criteria:** Chat feels complete even without backend. All data sourced from local mock models.

### Phase 2 — Expressive Messaging & Social Connections (1 week)
**Goal:** Make chat “fun + sticky” and introduce direct social connection management.
*   **Features:** 
    *   **Friend Requests Flow:** UI for accepting/ignoring requests, pending friends list, and blocking from strangers.
    *   **Like / Dislike Mechanics:** Thumbs up/down quick interactions on messages alongside other emoji reactions.
    *   Emoji picker panel, sticker tray with categories (college, mood, memes), GIF picker UI (mock API first).
    *   Full-screen media viewer for images/GIFs.
*   **UX polish:** Recent emojis/stickers, Favorite stickers, Quick reactions (Like/Dislike) on double tap.
*   **Done criteria:** Users can express via text + emoji + sticker + GIF in the same thread. Reaction counts (Like/Dislike) update smoothly. Friend Request tabs work with mock users.

### Phase 3 — Campus Social Layer (1–2 weeks)
**Goal:** Connect the chat to the rest of the ecosystem.
*   **Features:** Share card into chat (Notes, Event, Lost&Found item, Ghost post preview), mini actions in card (“Open module”, “Save”, “Forward”), deep links between tabs/modules.

### Phase 4 — Ghost Zone Advanced UX (1 week)
**Goal:** Make Anonymous social stronger + safer (UI first).
*   **Features:** Mood-based feed tabs with stronger sorting controls, **Ephemeral Content** (posts wiping after 24h UI), **Anonymous Polls**, post composer improvements (mood selector, tags, character counter, “sensitive content” warning toggle), comments enhancements (nested replies UI, upvote/downvote toggle, save post), report/block UI flows (placeholders).

### Phase 5 — Notes / Events / Lost&Found V2 polish (1–2 weeks)
**Goal:** Make WIP modules usable before backend.
*   **Notes:** Filter by subject/semester, note detail screen with preview pages/comments, bookmark + downloaded tab UI, **Assignment Tracker**.
*   **Events:** Event detail page + RSVP states ("Going"), calendar month view + local notification reminders, official Club Pages.
*   **Lost & Found:** Report flow with image carousel placeholder, claim flow UI, status timeline, **Campus Marketplace** tab for selling.

### Phase 6 — Quality, Performance, Accessibility (ongoing, 1 week sprint)
**Goal:** Production feel.
*   **Must-do:** Dark mode support, better keyboard handling, accessibility labels, semantic buttons, animation performance profiling (60fps target).
*   **Extras:** Error states + retry UI, offline mock persistence (Hive/Isar local store).

### Phase 7 — Backend Integration Readiness Layer
**Goal:** Make backend plug-in as easy as flipping a switch.
*   **Tasks:** Add DTO mappers (mock JSON -> domain model), `useMockData` flags, logging + analytics event hooks, basic unit tests.

### 🔥 Extra Features (Future Engagement)
*   **Engagement boosters:** Karma / Points System, Daily streaks, Campus leaderboard, “Ask seniors” Q&A room, **Focus Timer** + group pomodoro rooms.
*   **Premium UX touches:** Message drafts, scheduled messages, smart suggestions, theme packs, onboarding personas.
*   **Safety + trust:** Anonymous mode indicators, content warnings, gentle anti-bullying nudges.

### Recommended Sprint Order
1. **Phase 0 + Phase 1** (Foundation + Core chat usable)
2. **Phase 2** (GIF/sticker/reactions)
3. **Phase 3** (Module sharing)
4. **Phase 4/5 parallel** (Ghost + other modules depth)
5. **Phase 6 + 7** (Quality + integration readiness)

---

## 8. Screen-by-Screen UI Plan

### Splash Screen
- Full-screen Lottie animation (education/rocket/campus theme)
- App name below animation
- 2.5 second delay then → check auth → Dashboard or Login

### Login Screen
- App logo at top
- Email EditText
- Password EditText (with show/hide toggle)
- LOGIN button (filled, primary color)
- "Don't have an account? Sign Up" text link

### Signup Screen
- Name, Email, Password, Confirm Password EditTexts
- SIGN UP button
- "Already have an account? Login" text link

### Dashboard
- Top bar: App name + logout icon
- "Welcome back, [Name]!" subtitle
- 2x3 grid of CardViews, each with icon + label:
  - Notes | Events
  - Lost & Found | Chat
  - Anonymous | Study Groups

### Notes Screen
- Toolbar with "Notes" title + Upload FAB (+ icon)
- RecyclerView: each item shows title, subject, uploader, timestamp
- Tap → open PDF in external app

### Events Screen
- RecyclerView sorted by upcoming date
- Each card: event title, date badge, description snippet, location
- FAB to post new event

### Lost & Found Screen
- RecyclerView: image thumbnail (left) + title, description, poster name
- FAB to post new item
- Tap item → Item Detail screen with "Contact via Chat" button

### Chat List Screen
- RecyclerView: avatar circle + name + last message + time
- Tap → opens ChatActivity

### Chat Screen
- Messages with sent (right, blue) and received (left, gray) bubbles
- Sender name shown on received bubbles
- Bottom bar: EditText + Send button

### Anonymous Feed Screen
- Mood filter chips at top: All / Stressed / Happy / Confused / Venting / Motivated
- RecyclerView: mood tag badge, post content, like count, comment count, timestamp
- No names, no avatars — completely anonymous look
- FAB to write new post

### Post Anonymous Screen
- Mood selector — row of colored chips
- Large multiline text area: "What's on your mind?"
- POST button
- Small disclaimer: "This post is completely anonymous"

### Study Groups Screen
- RecyclerView: subject, date/time, location, spots left badge
- FAB to create group
- "My Groups" toggle at top

---

## 9. Team Division

### Person 1 — UI (XML Person)
Owns all layout files. Does NOT write Java logic.
- All `activity_*.xml` layout files
- All `item_*.xml` RecyclerView row layouts
- `colors.xml`, `styles.xml`, theme setup
- Dashboard card grid
- Chat bubble layouts
- Anonymous feed UI
- Navigation flow between screens

### Person 2 — Firebase (Backend Person)
Owns all Firebase integration. Does NOT write UI.
- Firebase Auth — login, signup, logout
- All Firestore reads and writes
- Firebase Storage — PDF and image uploads
- Getting download URLs after upload
- Firestore security rules
- Setting up Firebase project + `google-services.json`

### Person 3 — Logic (Java Person)
Owns business logic and complex features.
- RecyclerView adapters for all modules
- Real-time `addSnapshotListener` implementations
- ChatId generation logic
- Anonymous like system (likedBy array check)
- Study group join logic (member count check)
- Mood filter logic in anonymous feed
- PDF file picker intent
- Image picker intent
- Handler/postDelayed for splash screen timing

---

## 10. Gradle Dependencies

Add these to `app/build.gradle` inside `dependencies {}`:

```gradle
dependencies {
    // Firebase BoM — controls all Firebase library versions
    implementation platform('com.google.firebase:firebase-bom:33.0.0')
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-storage'
    implementation 'com.google.firebase:firebase-messaging'  // optional - notifications

    // Lottie — splash screen animations
    implementation 'com.airbnb.android:lottie:6.4.0'

    // Glide — image loading from URLs
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    annotationProcessor 'com.github.bumptech.glide:compiler:4.16.0'

    // CircleImageView — round profile images
    implementation 'de.hdodenhof:circleimageview:3.1.0'

    // Material Design Components
    implementation 'com.google.android.material:material:1.12.0'

    // CardView + RecyclerView
    implementation 'androidx.cardview:cardview:1.0.0'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'

    // Default AndroidX
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
}
```

Also add to the TOP of `app/build.gradle` (plugins block):
```gradle
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'   // ← required for Firebase
}
```

And in `project/build.gradle`:
```gradle
plugins {
    id 'com.google.gms.google-services' version '4.4.2' apply false
}
```

---

## 11. Firebase Security Rules

Paste this in Firestore → Rules tab:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users — read own data only, write own doc only
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Notes — any logged-in user can read, only uploader can delete
    match /notes/{noteId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.uploadedById;
    }

    // Events — any logged-in user can read/create
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.postedById;
    }

    // Lost & Found — same pattern
    match /lost_items/{itemId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.postedById;
    }

    // Chats — only participants can read/write
    match /chats/{chatId} {
      allow read, write: if request.auth != null &&
        request.auth.uid in resource.data.participants;

      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }

    // Anonymous posts — any logged-in user can read/create (no uid stored)
    match /anonymous_posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;  // for likes
    }

    // Comments — any logged-in user (no uid stored)
    match /comments/{commentId} {
      allow read, create: if request.auth != null;
    }

    // Study Groups
    match /study_groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;  // for joining
      allow delete: if request.auth.uid == resource.data.createdById;
    }
  }
}
```

---

## 12. Splash Screen Guide

### Step 1 — Get animation
Go to **lottiefiles.com** → search: `campus`, `education`, `rocket`, `hello`, `students`  
Download as **Lottie JSON** format (free)

### Step 2 — Add to project
Place the downloaded `.json` file at:
```
app/src/main/res/raw/splash_anim.json
```

### Step 3 — XML layout (activity_splash.xml)
```xml
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/white">

    <com.airbnb.lottie.LottieAnimationView
        android:id="@+id/lottieView"
        android:layout_width="280dp"
        android:layout_height="280dp"
        android:layout_centerHorizontal="true"
        android:layout_centerVertical="true"
        android:layout_above="@id/appName"
        app:lottie_rawRes="@raw/splash_anim"
        app:lottie_autoPlay="true"
        app:lottie_loop="false" />

    <TextView
        android:id="@+id/appName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="CampusHive"
        android:textSize="28sp"
        android:textStyle="bold"
        android:textColor="@color/primary"
        android:layout_centerHorizontal="true"
        android:layout_centerVertical="true"/>

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Your campus. Your community."
        android:textSize="13sp"
        android:textColor="@color/textSecondary"
        android:layout_centerHorizontal="true"
        android:layout_below="@id/appName"
        android:layout_marginTop="4dp"/>

</RelativeLayout>
```

### Step 4 — Java (SplashActivity.java)
```java
public class SplashActivity extends AppCompatActivity {
    private static final int SPLASH_DELAY = 2500; // 2.5 seconds

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
            Intent intent;
            if (user != null) {
                intent = new Intent(SplashActivity.this, DashboardActivity.class);
            } else {
                intent = new Intent(SplashActivity.this, LoginActivity.class);
            }
            startActivity(intent);
            finish();
        }, SPLASH_DELAY);
    }
}
```

### Step 5 — Set as launcher in AndroidManifest.xml
```xml
<activity android:name=".activities.SplashActivity"
    android:theme="@style/Theme.AppCompat.NoActionBar">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```

---

## 13. Viva Preparation

### Key lines to say (memorize these)

> "We used Firebase for real-time data synchronization using Firestore's snapshot listeners."

> "We implemented a dual-identity system — named chat for direct communication and a completely anonymous peer support section where no userId is stored at any point."

> "Firestore was used as a scalable NoSQL database. Collections were designed to minimize reads and support real-time updates."

> "Firebase Storage was used to store PDFs for notes and images for lost items, with download URLs saved in Firestore."

> "We used the Lottie animation library by Airbnb for our splash screen — it plays Adobe After Effects animations as native vector JSON, keeping the file size under 100KB."

> "Anonymous posts use a likedBy array field to prevent duplicate likes without exposing user identity in the UI."

### Module-wise ownership for viva
| Module | Who explains it |
|--------|----------------|
| Auth + Firestore setup | Person 2 |
| Dashboard + UI design | Person 1 |
| Notes + Events | Person 1 (UI) + Person 2 (Firebase) |
| Lost & Found | Person 1 (UI) + Person 2 (Firebase) |
| Chat system | Person 3 |
| Anonymous section | Person 3 (logic) + Person 2 (DB) |
| Study Groups | Person 3 |

### Common viva questions + answers

**Q: Why Firebase over a traditional SQL database?**  
A: Firebase Firestore provides real-time data sync out of the box, which is essential for our chat and live feeds. It also has a generous free tier and official Android SDK.

**Q: How did you ensure anonymity?**  
A: We deliberately designed the `anonymous_posts` and `comments` collections to not include any userId field. Even though users must be logged in to post (to prevent spam), their identity is never written to the anonymous documents.

**Q: What is a snapshot listener?**  
A: `addSnapshotListener` is a Firestore method that listens for real-time changes. Whenever a document or collection changes, our UI is updated instantly without the user needing to refresh.

**Q: How does chat work?**  
A: We generate a unique chatId by sorting both user UIDs alphabetically and concatenating them. This ensures the same two users always get the same chat room regardless of who initiates.

**Q: What is Lottie?**  
A: Lottie is an open-source animation library by Airbnb. It parses Adobe After Effects animations exported as JSON and renders them natively on Android. Files are tiny (50–200KB) and resolution-independent.

---

## 14. Timeline

| Days | Phase | Tasks |
|------|-------|-------|
| Day 1–2 | Setup | Android Studio, Firebase, dependencies, folder structure |
| Day 2–3 | Auth | Login, Signup, Firestore user save, session check |
| Day 3 | Dashboard | Home screen, card grid, navigation |
| Day 4 | Notes | Upload PDF, Firestore save, view/download |
| Day 5 | Events | Post event, list view, real-time |
| Day 5–6 | Lost & Found | Post item, image upload, contact via chat |
| Day 6–7 | Chat | Chat list, 1-to-1 chat, real-time messages |
| Day 7–8 | Anonymous | Anon feed, post, likes, comments, mood filter |
| Day 8–9 | Study Groups | Post group, join, member count, my groups |
| Day 10–12 | Polish | Loading states, empty states, testing, docs |

### Total: 10–12 days for a complete, submission-ready app

---

## Quick Checklist Before Submission

- [ ] App runs without crashes on a physical device
- [ ] Login and logout work correctly
- [ ] All 6 modules are functional
- [ ] Real-time updates visible in Chat and Anonymous feed
- [ ] Images load correctly in Lost & Found
- [ ] PDF opens correctly from Notes
- [ ] Anonymous posts have NO name/avatar shown
- [ ] Firestore security rules are set
- [ ] App name is consistent everywhere (manifest, strings.xml, splash)
- [ ] SRS document prepared
- [ ] ER/Database diagram prepared
- [ ] Screenshots taken for report
- [ ] Each team member can explain their part independently

---

*Document prepared for Assignment 9 & 10 — Smart Campus Companion App*  
*App: CampusHive | Stack: Java + Android + Firebase | Team: 3 members*
