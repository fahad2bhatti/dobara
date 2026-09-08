# Dobara — دوبارہ

**A trust-first Pakistani marketplace for pre-loved fashion.**

Dobara gives second-hand clothing a second life. Every listing carries a standardized, honest condition grade, and the whole visual language leans on Pakistani textile-dye heritage instead of a generic marketplace look.

Built solo, end to end — architecture, backend, and UI — as a production-grade Flutter portfolio project.

---

## Features

- 🛍️ **Browse & Search** — category filters, condition-graded listings, real-time Firestore-backed catalog
- 📦 **Sell Flow** — guided multi-step listing creation (photos → category → condition → price → preview → publish), with real image uploads via Cloudinary
- 🛒 **Cart & Checkout** — live Firestore-persisted cart, address management, Cash-on-Delivery checkout
- 📬 **Orders** — Firestore-persisted order history with live status tracking; orders are placed via a Cloud Function that looks up price and seller server-side, so nothing is client-tamperable
- ⭐ **Reviews** — one review per user per listing, editable, with photo uploads; gated to real signed-in (non-anonymous) users
- 🔔 **Notifications** — in-app notifications, including buyer alerts on order status updates
- 🚩 **Trust & Safety** — report listings, admin moderation queue
- 📊 **Admin Analytics** — revenue, items sold, average order value, order-status breakdown, daily/monthly sales charts, top-performing listings and categories, most-viewed listings, new-vs-returning buyer counts, city-wise order distribution, and an auto-generated monthly summary with a rule-based suggestion
- 🔐 **Auth** — Firebase Authentication, with guest browsing allowed on Home/Explore and login required for Sell, Cart, Checkout, and Profile

> **Note:** Dobara currently runs as a single-brand catalog — only the admin manages listings; regular users browse and buy. (Originally scoped as peer-to-peer; deliberately narrowed for a tighter, more focused v1.)

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter |
| State management | Riverpod (`flutter_riverpod`, code-gen via `riverpod_generator`) |
| Routing | `go_router` (`StatefulShellRoute` bottom-nav) |
| Backend | Firebase — Firestore, Auth, Cloud Functions, Cloud Messaging |
| Image hosting | Cloudinary (unsigned upload) |
| Charts | `fl_chart` |
| Local storage | `hive_flutter`, `flutter_secure_storage` |
| Fonts | Google Fonts — Instrument Serif (display) + Outfit (body) |

---

## Project Documentation

Dobara was built following a full SDLC documentation pipeline before any code was written. All 12 documents live in [`/docs`](./docs):

1. Project Overview & Scope
2. Software Requirements Specification
3. Complete Feature List
4. User Flow & Screen Flow
5. UI/UX Design System
6. Technical Architecture
7. Database Schema (ERD)
8. API / Backend Design
9. Security & Privacy
10. Testing & QA

---

## Getting Started

```bash
git clone https://github.com/fahad2bhatti/dobara.git
cd dobara
flutter pub get
```

This project connects to a live Firebase project (Firestore, Auth, Cloud Functions). To run your own instance:

1. Create a Firebase project and enable Firestore, Authentication, and Cloud Functions
2. Run `flutterfire configure` to generate your own `firebase_options.dart`
3. Deploy the included `firestore.rules` and `firestore.indexes.json`
4. Deploy the Cloud Functions in [`/functions`](./functions)
5. Set up a Cloudinary account and update the cloud name / unsigned upload preset in `storage_service.dart`

```bash
flutter run
```

---

## Status

Actively developed. Core buyer + admin flows (browsing, cart, checkout, orders, reviews, notifications, analytics, auth) are complete and running on real Firestore data. Currently in a UI polish pass (skeleton loading states, empty-state consistency) ahead of a public release build.

---

## Author

**Fahad Bhatti** — [@fahad2bhatti](https://github.com/fahad2bhatti)
