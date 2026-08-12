# Dobara — Status

**Last updated:** 2026-08-08

## ✅ Done
- Docs 1–10 locked v1.0, committed to `/docs`
- Repo + Flutter project set up at root (`com.fahadbhatti.dobara`)
- Verified running on Chrome/web
- Core deps installed: flutter_riverpod, riverpod_annotation, go_router, firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging, cached_network_image, hive_flutter, flutter_secure_storage, google_fonts
- Dev deps installed: build_runner, riverpod_generator, mocktail
- Firebase project connected (`dobara-ca7ca`) — web + android configured, `firebase_options.dart` wired into `main.dart`, verified on Chrome
- Android API key restricted (package name + SHA1 fingerprint) in Google Cloud Console
- Firestore database created in `asia-south1` (Mumbai); custom security rules deployed (users, listings, cart, orders, trustScores, reports)
- `core/`, `features/`, `shared/` folder structure built per Doc 6
- Full design generated in Figma Make and extracted: colors, fonts (Instrument Serif + Outfit), spacing/radius scale, condition-badge color system
- `AppTheme` built and wired: `app_colors.dart`, `app_text_styles.dart`, `app_spacing.dart`, `app_radius.dart`, `app_theme.dart`
- Home screen built from Figma design (search bar, category chips, hero banner, product grid) — working on Chrome (minor grid overflow deferred)
- Navigation backbone: go_router `StatefulShellRoute` with 5-tab bottom nav (Home, Explore, Sell, Wishlist, Profile); placeholder screens for the 4 non-Home tabs; all tabs confirmed working

## 🗺️ Roadmap (auth intentionally last)
- [x] **Phase 1 — Navigation** (go_router + bottom nav)
- [x] **Phase 2 — Listings**: Listing Detail screen, Explore/Search + filters
- [x] **Phase 3 — Create Listing (Sell flow)**: guided multi-step (photos → category → condition → info → price → description → preview → publish)
- [x] **Phase 4 — Seller Profile**: trust score, active listings, reviews
- [x] **Phase 5 — Cart**
- [x] *Phase 6 — Checkout**: address, COD payment, order summary
- [x] **Phase 7 — Orders**: history + status tracking
- [x] **Phase 8 — Trust & Safety**: report listing / report seller
- [ ] **Phase 9 — Admin**: dashboard, moderation, user management
- [ ] **Phase 10 — Auth**: sign up, login, Firebase Auth service, route guards

## 📋 Not Started (beyond feature phases above)
- Cloud Functions (Doc 8)
- Testing setup (Doc 10)
- Deployment prep (Doc 11 — not yet written)
- Final docs/README/case study (Doc 12 — not yet written)