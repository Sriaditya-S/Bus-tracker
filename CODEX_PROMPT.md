# Codex Prompt: School Bus Tracking MVP (India)

You are a senior mobile engineer building a real-world MVP for a **school bus tracking system in India**.

Build a **production-ready MVP** with the following constraints and features:

## Core Idea

- Track **school buses using only a smartphone kept in the bus**
- No external GPS hardware
- Parents can **see live bus location like a delivery tracking app**
- Works reliably in **India** with unstable mobile networks

---

## Platforms & Stack

- **Flutter** (single codebase)
- **Android + iOS**
- **Firebase backend**
  - Firebase Authentication
  - Firebase Realtime Database (for low-latency live location)
  - Firebase Cloud Functions (optional but preferred)
- **Google Maps**

---

## App Structure

Build **one Flutter app** with **role selection** at launch:

### 1. Driver Mode (Bus Phone – Android focused)

- Login via email/password (MVP)
- Start Trip / End Trip buttons
- Background GPS tracking (foreground service on Android)
- Send GPS location every **5–10 seconds**
- Automatically slow updates when stationary
- Show trip status (active/inactive)
- Store trip trail points
- Handle offline caching and sync when network returns

### 2. Parent Mode (Android + iOS)

- Login via **anonymous login (MVP)** or phone OTP
- Live map showing:
  - Current bus position
  - Last updated timestamp
  - Trip active/inactive status
- Auto camera follow
- Graceful handling of no-signal / stale location

---

## Backend Data Model

Design Firebase Realtime Database structure similar to:

- `/buses/{busId}/live`
  - lat, lng, speed, heading, updatedAt, tripId, isActive
- `/trips/{tripId}`
  - meta: busId, routeId, startAt, endAt
  - points: location trail
- `/routes/{routeId}`
  - parentsAllowed/{parentUid}: true

Include **basic security rules** so parents can only read assigned bus data.

---

## India-Specific Requirements

- Optimized for low-end Android phones
- Background tracking must be reliable on Android
- Battery-aware location updates
- App must survive network drops
- No assumptions of high-end hardware

---

## Output Requirements

Generate:

1. Flutter project structure
2. `pubspec.yaml` dependencies
3. `main.dart` with working MVP
4. Background service implementation
5. Firebase data structure and rules
6. Android + iOS permission setup

Code should be:

- Clean
- Well-commented
- Copy-paste runnable

---

## Important Constraints

- Keep it **simple but scalable**
- Avoid fancy UI
- Focus on reliability and correctness
- Assume **bus phone is Android**, parents may be iOS or Android

Build this as if it will be demoed to a **real school management**.

---

## Optional Follow-up (if supported)

After generating the MVP, outline how to extend it with:

- Route stops
- ETA calculation
- Parent notifications
- Admin web panel
