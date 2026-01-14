# School Bus Tracking MVP (India)

A production-minded MVP for tracking school buses using **only smartphones**. The bus phone runs in Driver mode (Android-focused) and parents track the bus in Parent mode (Android/iOS).

## Project Structure

```
lib/
  main.dart
  screens/
    role_selection_screen.dart
    driver_screen.dart
    parent_screen.dart
  services/
    background_service.dart

docs/
  firebase_schema.md
  firebase_rules.json
  permissions.md

pubspec.yaml
```

## Key Features

- **Driver mode**: login, start/end trip, background GPS tracking, low-bandwidth updates.
- **Parent mode**: anonymous login, live map, last-updated status, stale-data handling.
- **Firebase RTDB**: real-time updates with offline persistence.

## Setup Notes

1. Create a Firebase project and add Android/iOS apps.
2. Add `google-services.json` and `GoogleService-Info.plist`.
3. Enable **Authentication** (email/password + anonymous).
4. Enable **Realtime Database** and apply rules from `docs/firebase_rules.json`.
5. Configure Google Maps API keys (see `docs/permissions.md`).

## Running

```
flutter pub get
flutter run
```

## MVP Data Model & Rules

- Schema: `docs/firebase_schema.md`
- Security rules: `docs/firebase_rules.json`

