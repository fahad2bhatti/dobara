# Technical Architecture

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 6 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

---

## 1. Tech Stack

| Layer | Choice | Reasoning |
|---|---|---|
| Framework | Flutter (stable channel) | Your existing stack, single Android codebase |
| Backend | Firebase (Auth, Firestore, Storage, Cloud Functions, FCM) | No server to manage, fast to build, scales for MVP traffic, matches your FitGenie precedent |
| State Management | Riverpod 2.x (code generation) | Compile-safe, testable, scales better than Provider/GetX for a multi-role app (buyer/seller/admin state) |
| Navigation | GoRouter | Declarative, deep-link ready, role-based redirect support (buyer vs admin routing) |
| Local cache | Hive | Lightweight, used only for offline last-viewed-feed cache |

**App identifier:** `com.dobara.app`

---

## 2. Folder Structure (Feature-First)

```
lib/
├── core/
│   ├── constants/        # app_colors.dart, app_text_styles.dart, app_sizes.dart
│   ├── theme/             # app_theme.dart (maps Doc 5 tokens → ThemeData)
│   ├── utils/             # validators.dart, formatters.dart, extensions.dart
│   ├── services/          # firebase_service.dart, notification_service.dart
│   ├── errors/            # failure.dart, error_handler.dart
│   └── router/            # app_router.dart (GoRouter, role-based redirects)
│
├── features/
│   ├── auth/
│   │   ├── data/          # auth_repository.dart
│   │   ├── domain/        # user_model.dart
│   │   └── presentation/  # login_screen.dart, register_screen.dart, ...
│   ├── home/
│   ├── listings/          # covers both browse (buyer) and manage (seller)
│   ├── wishlist/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   ├── profile/
│   ├── reviews/
│   ├── notifications/
│   └── admin/
│       ├── dashboard/
│       ├── user_management/
│       ├── listing_moderation/
│       ├── category_management/
│       ├── order_oversight/
│       └── dispute_resolution/
│
├── shared/
│   ├── widgets/            # listing_card.dart, condition_badge.dart, trust_score_chip.dart
│   └── providers/          # shared Riverpod providers (current user, connectivity)
│
└── main.dart
```

Each `features/<name>/` folder is self-contained: `data/` (repository), `domain/` (models), `presentation/` (screens + widgets). `core/` never holds feature-specific logic. `shared/widgets/` holds only components reused across 2+ features (e.g. `ListingCard` is used in Home, Search, Wishlist, and My Listings).

---

## 3. State Management Pattern

```dart
@riverpod
class ListingFeedNotifier extends _$ListingFeedNotifier {
  @override
  FutureOr<List<Listing>> build() => ref.read(listingRepositoryProvider).fetchFeed();

  Future<void> loadMore() async {
    final current = state.valueOrNull ?? [];
    final next = await ref.read(listingRepositoryProvider).fetchFeed(startAfter: current.last);
    state = AsyncData([...current, ...next]);
  }
}
```

Role-based state (buyer/seller/admin) is derived from a single `currentUserProvider` — no separate app builds per role; UI conditionally shows seller/admin entry points based on the user's role field in Firestore.

---

## 4. Routing (Role-Aware)

```dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null && !state.matchedLocation.startsWith('/auth')) {
      return '/auth/login';
    }
    if (state.matchedLocation.startsWith('/admin') && user?.role != 'admin') {
      return '/home'; // non-admins can't reach admin routes
    }
    return null;
  },
  routes: [...],
);
```

---

## 5. Standing Coding Conventions (apply project-wide)

- No `.withOpacity()` — use `.withValues(alpha:)`
- GoRouter only for navigation — never `Navigator.push` directly
- `FieldValue.serverTimestamp()` for all Firestore timestamps — never `DateTime.now()`
- API keys/secrets via `--dart-define` — never committed
- `const` constructors everywhere possible; `ListView.builder` for all lists
- `CachedNetworkImage` for all listing photos, with skeleton placeholder (Doc 5 loading state)

---

## 6. Why Not a Custom Backend

Firebase covers every v1 requirement (auth, real-time listing feed, file storage for photos, push notifications) without operational overhead. Cloud Functions cover the few pieces of server-side logic needed (commission calculation, dispute state transitions) — see Doc 8 for exact function specs. A custom Node/Express backend would add deployment and hosting complexity with no v1 benefit; revisit only if a future feature (e.g. payment gateway with server-side verification) requires it.
