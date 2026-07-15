# Apex Lifter — Mobile

Flutter app for **Apex Lifter**, a gym social app: log machine workouts, check in at your gym by GPS, climb leaderboards, challenge other lifters to head-to-head lift-offs judged by the gym community, and collect medals for every win.

Companion API: [apex_lifter_backend](https://github.com/dchristo978/apex_lifter_backend) (Laravel). The app is a thin client — all domain rules live server-side.

## Tech stack

- **Flutter** (Dart SDK ^3.9), Material 3, iOS/Android (desktop/web targets scaffolded)
- **provider** — state management (`ChangeNotifier` per domain)
- **http** — plain JSON client with Sanctum bearer tokens (`lib/services/api_client.dart`)
- **confetti** — celebration animations for challenge/medal moments
- **geolocator** + **permission_handler** — GPS gym check-in
- **image_picker** — avatar photos and challenge proof videos
- **flutter_localizations / intl** — full **English + Indonesian** localization

## Architecture

```
lib/
  main.dart            # MultiProvider wiring + app bootstrap (splash → login/onboarding → shell)
  models/models.dart   # all API DTOs with fromJson (User, Challenge, Medal, ...)
  services/            # ApiClient (auth token, get/post/patch/upload), permissions
  providers/           # AuthProvider, WorkoutProvider, ChallengeProvider, ... one per domain
  screens/             # one file per screen (see tour below)
  widgets/             # shared UI: user_avatar, streak_card, challenge_widgets, confetti_burst
  l10n/                # app_en.arb + app_id.arb (source) → generated AppLocalizations
```

Pattern: screens read providers via `context.watch`/`context.read`; providers call `ApiClient` and hold lists/loading flags; models are immutable DTOs parsed from JSON. Screens that show another user's data (public profile, medal case) fetch directly through `ApiClient`.

### Backend URL

`ApiClient` defaults to `http://127.0.0.1:8000/api` (`http://10.0.2.2:8000/api` on the Android emulator) — see `lib/services/api_client.dart` to point elsewhere.

## Screen tour

| Screen | What it does |
|---|---|
| `main_shell.dart` | Bottom navigation: Home / Leaderboard / Profile (Cupertino-native tab bar on iOS) |
| `home_screen.dart`, `log_set_sheet.dart` | Check-in status, streak, quick set logging (weight × reps per machine) |
| `gyms_screen.dart`, `gym_presence_screen.dart` | GPS check-in, who's at the gym right now |
| `leaderboard_screen.dart`, `machine_leaderboard_screen.dart`, `gym_leaderboard_screen.dart` | Rankings by estimated 1RM with gender/age/weight-class filters |
| `progress_screen.dart` | Per-machine 1RM progress over time |
| `profile_screen.dart`, `edit_profile_screen.dart`, `featured_machines_screen.dart` | Own profile, body weight (stale after 90 days), pin up to 3 featured machines |
| `public_profile_screen.dart` | Any lifter's profile: stats, records, session history, medals row → medal case, challenge buttons |
| `challenges_screen.dart`, `create_challenge_screen.dart`, `challenge_detail_screen.dart` | The Arena (judge others with criteria + reason codes), your challenges, proof-video upload |
| `medals_screen.dart` | **Medal Case** — gold "trophy room" listing every challenge win; owners attach a story to each medal (max 100 words, live word counter) |
| `notifications_screen.dart` | Rank alerts and challenge deep links |
| `settings_screen.dart` | Language (EN/ID) and preferences |

### Confetti moments

`lib/widgets/confetti_burst.dart` exposes a fire-and-forget `celebrate(context)` overlay (two gold cannons). It fires when you: create a challenge, judge one in the arena, open a challenge you won, open a received challenge from a notification, open a medal case that has medals, or tap any medal.

## Getting started

1. Run the backend (see its README), seed demo data, keep it on port 8000.
2. ```bash
   flutter pub get
   flutter run
   ```
3. Log in with a seeded account: `demo@apex.test` / `password`.

## Development

```bash
flutter analyze          # lints (flutter_lints)
flutter test             # model-parsing tests in test/
flutter gen-l10n         # regenerate localizations after editing lib/l10n/*.arb
```

- **Localization**: every user-facing string goes through `AppLocalizations`. Add keys to both `app_en.arb` and `app_id.arb`, then run `flutter gen-l10n` (generated files are checked in under `lib/l10n/`).
- **App icon**: `dart run flutter_launcher_icons` regenerates launcher icons from `assets/icon/app_icon.png`.
