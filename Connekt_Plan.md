# Connekt Production Repair Plan

This document is the working master plan to take the current Flutter app from "demo with real screens" to "production-ready campus platform".

It is based on the current repository structure under `lib/`, the existing GoRouter/Riverpod architecture, and the issues identified in the audit. The goal is not only to patch visible bugs, but to remove the patterns that keep re-creating them.

---

## 1. Mission

### Primary goal
Stabilize the app so that every major flow is:
- secure enough to ship
- consistent in navigation and state handling
- functional instead of decorative
- theme-safe in both light and dark mode
- backed by real repository/provider logic instead of hardcoded UI data

### Definition of "production level" for this app
- No secrets embedded in source.
- No mixed navigation stacks.
- No fake submit buttons or placeholder flows pretending to save data.
- No screen relying on hardcoded dates, attendees, comments, ratings, file sizes, or identity labels when backend data exists.
- All create/read/update actions show loading, success, and failure states.
- Core modules work on real backend data or are clearly feature-flagged off.
- Important flows have tests.

---

## 2. Current App Map

### App foundation
- Entry: `lib/main.dart`
- Router: `lib/core/routing/app_router.dart`
- Config: `lib/core/config/app_config.dart`
- Theme: `lib/core/theme/*` and `lib/theme/*`
- State: Riverpod providers in `lib/core/providers/*`
- Data layer: repositories in `lib/core/repositories/*`

### Main feature areas
- Auth: `lib/screens/auth/*`
- Splash: `lib/screens/splash_screen.dart`
- Main shell: `lib/screens/main_screen.dart`
- Dashboard: `lib/screens/home/dashboard_tab.dart`
- Notes: `lib/screens/notes/*`
- Events: `lib/screens/events/*`
- Chat: `lib/screens/chat/*`
- Ghost / World chat / comments: `lib/screens/ghost/*`
- Lost & found: `lib/screens/lost_found/*`
- Study groups: `lib/screens/study_groups/*`
- Campus: `lib/screens/campus/*`
- Profile: `lib/screens/profile/*`
- AI chat: `lib/screens/ai/ai_chat_screen.dart`

---

## 3. Repair Strategy

### Rule 1: Fix foundations before polishing screens
If routing, config, theming, and repository contracts stay inconsistent, screen-level fixes will keep regressing.

### Rule 2: Remove fake UX first
Any button that only pops a route, any search field with no logic, and any hardcoded card metadata breaks trust immediately.

### Rule 3: Convert screen-local fake state into provider/repository state
Bookmarks, reactions, comments, RSVP, and upload status must move out of widget-local state.

### Rule 4: Every user action needs 4 states
- idle
- loading
- success
- error

### Rule 5: If backend support does not exist yet, the UI must say so explicitly
Never ship decorative controls that look functional.

---

## 4. Priority Roadmap

## P0 - Critical Foundation Repairs

### 4.1 Secure runtime configuration
Target files:
- `lib/core/config/app_config.dart`
- `lib/main.dart`
- platform build config where `--dart-define` is injected
- `README.md`

Tasks:
- Keep all secrets out of source code.
- Standardize required keys:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `GEMINI_API_KEY`
  - any optional fallback AI keys only if truly used
- Remove unused key definitions if the app does not actually use xAI, NVIDIA, Groq.
- Add startup validation with a clear crash message in debug and safer user-facing error handling in release.
- Document local/dev/prod build commands using `--dart-define`.
- Add `.env.example` only as documentation if the team wants local mapping, but do not rely on shipping `.env` in client apps for secret protection.

Acceptance criteria:
- No live secret values exist anywhere in `lib/`.
- App startup fails loudly in development when required config is missing.
- Build instructions are documented.

### 4.2 Unify navigation under GoRouter only
Target files:
- `lib/core/routing/app_router.dart`
- all screens using `Navigator.push`, `pushReplacement`, `popUntil`, or direct `MaterialPageRoute`

Tasks:
- Replace all direct `Navigator.*` pushes for app routes with `context.go`, `context.push`, or named route equivalents.
- Define route constants or typed helpers to avoid raw string duplication.
- Ensure nested tab navigation behaves correctly with `StatefulShellRoute`.
- Decide which screens belong inside shell branches vs standalone routes.
- Normalize back behavior from detail screens and post flows.
- Audit deep-link safety for `state.extra` arguments.

Acceptance criteria:
- No feature screen uses direct Navigator for app navigation.
- Back button behavior is consistent across Android system back and app bar back.
- Tab stack state remains stable when switching tabs.

### 4.3 Fix theme system and dark mode correctness
Target files:
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart`
- `lib/theme/app_theme.dart`
- screens with hardcoded `Colors.white`, `Color(0xFF...)`, or `AppColors.background`

Tasks:
- Choose one theme source of truth. Remove or merge duplicate theme implementations.
- Replace hardcoded surfaces/text colors with theme tokens:
  - `colorScheme.surface`
  - `colorScheme.surfaceContainer*`
  - `colorScheme.onSurface`
  - `colorScheme.primary`
  - `textTheme`
- Introduce semantic helpers for cards, chips, borders, and input fills.
- Audit all major screens in both modes.
- Fix Ghost/World tab specifically for light mode compatibility.

Acceptance criteria:
- All main screens are readable in light and dark mode.
- No major screen has white cards on light text or dark-only backgrounds in light mode.
- Theme usage is consistent and centralized.

### 4.4 Improve splash/auth boot flow resilience
Target files:
- `lib/screens/splash_screen.dart`
- `lib/core/providers/auth_provider.dart`
- `lib/core/repositories/auth_repository.dart`

Tasks:
- Remove fake progress behavior if loading is not actually tied to initialization.
- Wrap campus/session checks with try/catch.
- Add retry and offline-friendly error state.
- Route based on actual auth state and campus membership state.

Acceptance criteria:
- Splash does not silently fail on backend/network error.
- Users always land in a defined state: login, campus select, or dashboard.

---

## P1 - Convert Fake Flows Into Real Product Flows

### 4.5 Auth polish and correctness
Target files:
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/signup_screen.dart`
- `lib/core/repositories/auth_repository.dart`
- `lib/core/providers/auth_provider.dart`

Tasks:
- Send `full_name` into user metadata/profile storage during signup.
- Strengthen email validation.
- Add show/hide toggle for confirm password.
- Make "Forgot?" actionable or remove it until implemented.
- Add loading state for social sign-in buttons.
- Add terms/privacy links to real screens or external URLs.
- Add inline password requirements/strength feedback.

Acceptance criteria:
- Signup persists name.
- Auth screens show proper validation and loading/error state.
- No dead legal/auth controls remain.

### 4.6 Make note upload actually work
Target files:
- `lib/screens/notes/upload_note_screen.dart`
- `lib/core/repositories/notes_repository.dart`
- related model/storage utilities

Tasks:
- Use `file_picker` for real document selection.
- Validate title, subject/category, file, and campus context.
- Upload file to storage and persist note metadata.
- Show progress, success, and failure state.
- Return to notes list through router and refresh list data.

Acceptance criteria:
- A user can select a real file and create a note record.
- Newly uploaded note appears in notes list.

### 4.7 Make event posting actually work
Target files:
- `lib/screens/events/post_event_screen.dart`
- `lib/core/repositories/campus_repository.dart` or dedicated events repository
- `lib/core/models/campus_event.dart`

Tasks:
- Persist date/time values selected by the user.
- Validate title, description, date, time, location/category.
- Save the event and refresh events list.
- Replace fake pop-only submit.

Acceptance criteria:
- A posted event persists and shows with real date/time.

### 4.8 Turn decorative search/filter UI into real behavior
Target files:
- `lib/screens/notes/notes_tab.dart`
- `lib/screens/events/events_tab.dart`
- `lib/screens/chat/chat_tab.dart`
- `lib/screens/campus/campus_selection_screen.dart`
- `lib/screens/lost_found/lost_found_tab.dart`

Tasks:
- Add controllers/state for search fields.
- Ensure filter chip values match actual stored categories.
- Apply local or repository-level filtering.
- Debounce search where needed.

Acceptance criteria:
- Search and filter controls visibly affect results.
- There are no decorative search bars left in primary flows.

---

## P1 - Remove Demo Data and Hardcoded UI Claims

### 4.9 Notes module realism pass
Target files:
- `lib/screens/notes/notes_tab.dart`
- `lib/screens/notes/note_detail_screen.dart`
- `lib/core/models/academic_note.dart`
- `lib/core/repositories/notes_repository.dart`

Tasks:
- Remove hardcoded `4.8` rating unless rating data truly exists.
- Fix category mismatch: UI chips must align with repository values.
- Pass real download count/file metadata.
- Replace hardcoded author academic info with real optional metadata.
- Replace mock comments with repository-driven comments, or hide the section until supported.
- Persist bookmarks using backend or local storage.
- Implement real file download/open flow if note file URLs exist.

Acceptance criteria:
- Notes screens show real data only.
- Unsupported metadata is hidden instead of faked.

### 4.10 Events module realism pass
Target files:
- `lib/screens/events/events_tab.dart`
- `lib/screens/events/event_detail_screen.dart`
- `lib/core/models/campus_event.dart`

Tasks:
- Generate day selector dynamically from current week or upcoming event dates.
- Filter events by selected day.
- Replace hardcoded attendee counts and avatars with real attendee data or hide avatars/count preview.
- Use actual event date formatting.
- Make RSVP/"Interested" persist or remove until implemented.
- Implement "Add to Calendar" with actual integration or label it clearly as upcoming.
- Remove hardcoded description append.
- Remove unconditional "Official Club" badge.
- Replace negative-width overlap trick with proper stacked avatar layout.

Acceptance criteria:
- Event cards and detail screen are data-driven.
- Date, attendees, and RSVP states are truthful.

### 4.11 Ghost/comments/world chat integrity pass
Target files:
- `lib/screens/ghost/ghost_tab.dart`
- `lib/screens/ghost/comments_screen.dart`
- `lib/screens/ghost/post_ghost_screen.dart`
- `lib/core/repositories/ghost_repository.dart`

Tasks:
- Replace local hardcoded comments with repository-backed comments.
- Use relative time formatting from timestamps.
- Persist likes/dislikes/comments if feature is enabled.
- Add alias validation for world chat if aliases exist.
- Add message length limits and basic content rules.
- Confirm whether daily refresh exists; if not, remove or reword that claim.
- Fix theme issues on all ghost/world screens.

Acceptance criteria:
- Anonymous/social screens do not display fake timestamps or fake engagement.
- User-generated actions persist or are clearly unavailable.

### 4.12 Chat reliability pass
Target files:
- `lib/screens/chat/chat_tab.dart`
- `lib/screens/chat/chat_detail_screen.dart`
- `lib/core/providers/chat_provider.dart`
- `lib/core/repositories/chat_repository.dart`

Tasks:
- Make compose action functional.
- Implement chat list search.
- Improve time formatting to human-readable form.
- Replace constant "Online" with actual presence or remove it.
- Replace `senderId: 'me'` placeholder with authenticated user id.
- Persist reactions if reactions are exposed.
- Disable or hide unimplemented call/media actions until supported.
- Add undo to archive or use a safer archive flow.

Acceptance criteria:
- Chat does not misrepresent user state.
- Main actions are either functional or clearly absent.

---

## P2 - Data, State, and Architecture Cleanup

### 4.13 Standardize repository/provider patterns
Target files:
- `lib/core/repositories/*`
- `lib/core/providers/*`
- `lib/screens/study_groups/study_groups_tab.dart`

Tasks:
- Ensure all feature data access goes through providers/repositories, not local repository instantiation inside widgets.
- Convert `_groupRepo` style local construction to Riverpod providers.
- Define consistent result/error models for async operations.
- Split repository responsibilities more cleanly if `campus_repository.dart` or others are overloaded.

Acceptance criteria:
- Screens do not create data-layer objects directly.
- Async feature flows use a consistent state pattern.

### 4.14 Remove N+1 and wasteful queries
Target files:
- `lib/screens/study_groups/study_groups_tab.dart`
- any FutureBuilder-per-card patterns

Tasks:
- Replace per-item membership checks with batched repository response.
- Preload membership map or enrich list query results.

Acceptance criteria:
- Group list rendering does not trigger one extra request per card.

### 4.15 Dashboard transformation
Target files:
- `lib/screens/home/dashboard_tab.dart`
- `lib/core/providers/dashboard_provider.dart`

Tasks:
- Convert dashboard from static launcher into an activity surface.
- Show:
  - recent notes
  - upcoming events
  - unread chat count
  - campus membership summary
  - optional world/ghost pulse
- Remove dead helpers like unused `_buildStatPill()`.
- Clean spacing leftovers and empty layout artifacts.

Acceptance criteria:
- Dashboard feels alive and reflects real app data.
- Screen gives users a reason to return.

### 4.16 Campus selection reliability
Target files:
- `lib/screens/campus/campus_selection_screen.dart`
- `lib/core/providers/campus_provider.dart`
- `lib/core/repositories/campus_repository.dart`

Tasks:
- Make search functional.
- Prevent duplicate campus creation/join edge cases.
- Add loading state during join/create.
- Provide a recovery path from study groups and other campus-dependent screens back to campus selection.

Acceptance criteria:
- Campus join/select/create flows are trustworthy and recoverable.

---

## P2 - UX Reliability and Guardrails

### 4.17 Loading, empty, error, retry states
Target files:
- all primary feature screens
- `lib/core/widgets/app_states.dart`

Tasks:
- Standardize reusable loading, empty, and retry components.
- Ensure every async screen has explicit state handling.

Acceptance criteria:
- No blank screens on failure.
- No silent failures on upload/post/join actions.

### 4.18 Validation and moderation
Target files:
- auth, notes, events, ghost, chat, lost & found create flows

Tasks:
- Add form validation rules.
- Add length limits.
- Add basic sanitization/content rules where needed.
- Prevent empty aliases/messages.

Acceptance criteria:
- Invalid input is blocked before network submission.

### 4.19 Accessibility and semantics
Target files:
- all major screens

Tasks:
- Add semantic labels for icon-only actions.
- Improve tap targets.
- Ensure contrast meets accessibility baseline.
- Test keyboard handling and screen reader hints on forms.

Acceptance criteria:
- Main flows are accessible on mobile with assistive tooling.

---

## P3 - Feature Completion Gaps

These are lower priority than truthfulness and stability. They should not ship as fake controls.

### 4.20 Notes enhancements
- Real PDF preview rendering
- Download/open file handling
- Real comments/bookmarks if supported

### 4.21 Events enhancements
- Calendar integration
- RSVP attendee management
- Club verification/badging model

### 4.22 Chat enhancements
- Media attachments
- Voice/video calls
- Sticker/GIF tabs
- Presence system

### 4.23 Profile enhancements
- Edit display name
- Better image upload error surfacing
- Usage/activity stats

### 4.24 AI chat hardening
Target files:
- `lib/screens/ai/ai_chat_screen.dart`
- `lib/core/providers/ai_provider.dart`
- `lib/core/repositories/ai_repository.dart`

Tasks:
- Replace brittle string-matching error detection with typed error handling.
- Persist chat history if feature should survive restart.
- Remove hardcoded suggestion cards or make them dynamic.

---

## 5. Screen-by-Screen Repair Checklist

### Splash
- Replace fake progress with real init state.
- Add try/catch and retry path.
- Clarify auth + campus decision tree.

### Login
- Fix email validation.
- Make forgot password real or remove it.
- Add social loading state.
- Remove hardcoded white card theming.

### Signup
- Persist full name.
- Add confirm password visibility toggle.
- Wire terms/privacy.
- Add password guidance.

### Dashboard
- Replace launcher-only layout with live data modules.
- Remove dead spacing and dead helper methods.

### Notes Tab
- Fix category chips.
- Make search/filter functional.
- Remove fake ratings.
- Make "View All" meaningful or remove it.

### Note Detail
- Remove hardcoded author/course labels.
- Replace fake preview/comments.
- Make download real or hide CTA.
- Persist bookmark state.

### Upload Note
- Use real file picker.
- Validate input.
- Save note for real.

### Events Tab
- Dynamic date selector.
- Real filter logic.
- Real attendees or no fake attendee UI.
- Real interested state or remove.

### Event Detail
- Real event date.
- Truthful attendees and badge state.
- Real calendar integration or hidden CTA.
- Fix avatar overlap implementation.

### Post Event
- Bind form state.
- Persist selected date/time.
- Validate and submit.

### World Chat / Ghost Tab
- Theme-safe colors.
- Validate alias.
- Add message limits.
- Clarify/reset policy truthfully.

### Chat Tab
- Compose action.
- Search logic.
- Better timestamps.
- Safer archive UX.

### Chat Detail
- Real sender identity.
- Real or hidden online state.
- Disable fake media/call actions if unsupported.
- Persist reactions if shown.

### Comments
- Load real comments.
- Use real timestamps.
- Persist interactions.

### Lost & Found
- Show reporter data correctly where policy allows.
- Add claimed/resolved flow.
- Verify category values.

### Study Groups
- Remove N+1 queries.
- Route users to campus selection from empty state.
- Use Riverpod for repository access.

### Campus Selection
- Make search work.
- Prevent duplicates.
- Add loading state.

### Profile
- Improve image upload failure handling.
- Add editable profile name.
- Add meaningful stats if available.

### AI Chat
- Remove hardcoded suggestion content.
- Replace brittle error detection.
- Persist history if product requires continuity.

---

## 6. Data Model and Backend Work Needed

The UI can only become truthful if the backend contracts support the data. Review models and storage schema for the following:

### Likely model upgrades needed
- `AcademicNote`
  - `fileUrl`
  - `fileSizeBytes`
  - `downloadsCount`
  - `bookmarkCount` or user bookmark relation
  - optional `subject`, `semester`, `uploaderName`

- `CampusEvent`
  - `startAt`
  - `endAt`
  - `location`
  - `attendeeCount`
  - `attendeePreview`
  - `rsvpStatusByUser` or separate RSVP relation
  - `isOfficial`

- `ChatConversation` / `ChatMessage`
  - `senderId`
  - `status`
  - optional `reactionSummary`
  - optional `presence` model separate from message

- `GhostPost` / comments
  - `createdAt`
  - `commentCount`
  - `reactionCount`
  - moderation/report metadata if required

- `LostItem`
  - `reporterName`
  - `status`
  - `resolvedAt`

- `StudyGroup`
  - membership summary embedded enough to avoid N+1 checks

### Backend rules to verify
- auth ownership
- campus-scoped reads/writes
- file storage permissions
- comment/reaction integrity
- note upload and event posting authorization

---

## 7. Testing Plan

### Unit tests
- config validation
- repository mapping/parsing
- filter/search logic
- auth validation helpers
- date/time formatting helpers

### Widget tests
- login/signup form validation
- notes search/filter behavior
- events day filter behavior
- loading/empty/error states
- dark mode rendering for critical screens

### Integration tests
- splash to auth/dashboard routing
- signup and login
- upload note flow
- post event flow
- campus join/select flow

### Manual QA checklist
- Android back button on all major detail screens
- tab switching preserves state
- offline or failed network handling
- long text, empty text, invalid file, duplicate submission
- dark mode and light mode screenshots for all primary screens

---

## 8. Production Readiness Gates

Do not call the app production-ready until all of the following are true:

- Secrets are not hardcoded.
- Router is unified.
- Theme is stable in both modes.
- Upload Note and Post Event are fully functional.
- Search/filter bars are not decorative.
- Hardcoded engagement/date/identity values are removed.
- Core errors are surfaced to users.
- Dashboard is data-driven.
- Study groups N+1 issue is fixed.
- Basic tests exist and pass.

---

## 9. Suggested Execution Order

### Sprint 1 - Foundation lockdown
1. Config cleanup
2. Router cleanup
3. Theme cleanup
4. Splash/auth boot hardening

### Sprint 2 - Truthful core flows
1. Signup fixes
2. Upload note real implementation
3. Post event real implementation
4. Search/filter activation

### Sprint 3 - Remove fake data
1. Notes realism pass
2. Events realism pass
3. Ghost/comments realism pass
4. Chat truthfulness pass

### Sprint 4 - Architecture and dashboard
1. Repository/provider cleanup
2. Study groups N+1 fix
3. Dashboard activity feed and stats
4. Campus selection reliability

### Sprint 5 - Reliability and QA
1. Loading/error/empty states
2. Validation and moderation basics
3. Tests
4. release checklist

---

## 10. Immediate Actionable Worklist

If work starts now, this is the best order:

1. Audit every `Navigator.` usage and replace it with GoRouter usage.
2. Audit every hardcoded color and move it to theme-driven styling.
3. Confirm all keys in `app_config.dart` are required, safe, and documented.
4. Make signup save `full_name`.
5. Implement real note upload.
6. Implement real event posting.
7. Fix notes/events/chat/campus search and filter controls.
8. Remove fake hardcoded content from note/event/comment/detail screens.
9. Fix study group data loading pattern.
10. Turn dashboard into a live activity surface.

---

## 11. Nice-to-Have Product Upgrade

### Campus Activity Feed
This is the highest-ROI engagement upgrade after core fixes.

Recommended dashboard sections:
- recent notes
- upcoming events
- unread chats
- trending ghost posts
- open study groups

Why it matters:
- makes the app feel alive immediately
- reduces demo-app perception
- gives users a reason to open the app daily
- reuses data already flowing through the main modules

---

## 12. Ownership Template

Use this template while executing the repair:

### Foundation owner
- config
- routing
- theme
- boot flow

### Feature owner
- notes
- events
- chat
- ghost
- lost & found
- study groups

### QA owner
- regression checklist
- dark mode audit
- routing audit
- production build validation

---

## 13. Final Outcome

If this plan is executed properly, Connekt will move from:
- visually strong but functionally inconsistent

to:
- secure
- truthful
- navigationally stable
- theme-safe
- data-driven
- ready for beta testing with real users

This document should be updated as each module is repaired so it stays the single source of truth for the app hardening effort.
