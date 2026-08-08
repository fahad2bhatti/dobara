# Testing & QA

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 10 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

---

## 1. Test Types & Tools

| Type | Tool | Scope |
|---|---|---|
| Unit tests | `flutter_test` + `mocktail` | Repositories, Riverpod notifiers, utils/validators |
| Widget tests | `flutter_test` | Individual screens/components in isolation |
| Firebase mocking | `firebase_auth_mocks`, `fake_cloud_firestore` | Auth + Firestore logic without hitting real backend |
| Integration tests | `integration_test` package | Full buyer flow (browse → checkout) and seller flow (list → fulfill) end-to-end on a device/emulator |
| Security rules tests | Firebase Emulator Suite | Validates Doc 9 rules actually block what they should |

---

## 2. Functional Test Checklist (traces to Doc 2 FRs)

- [ ] Register / Login / Forgot password (FR-1.1–1.3)
- [ ] Create / edit / delete listing (FR-2.1–2.2)
- [ ] Search + filters return correct results (FR-3.2–3.3)
- [ ] Wishlist add/remove persists (FR-4.1)
- [ ] Cart blocks checkout on stale/sold item (FR-5.6) — critical path, test explicitly
- [ ] Order status transitions follow allowed sequence only (Doc 8 `updateOrderStatus`)
- [ ] Cancel order only allowed pre-shipment (FR-6.2)
- [ ] Review only submittable once, only after delivery (Doc 8 `submitReview`)
- [ ] Trust score recalculates correctly after new review (Doc 8 `onReviewCreated`)
- [ ] Admin: suspend user blocks their ability to list/order
- [ ] Admin: remove listing hides it from buyer feed immediately

## 3. UI Test Checklist

- [ ] All screens from Doc 4's screen inventory render without overflow at 3 breakpoints (small phone, standard, large phone)
- [ ] Skeleton loading states match Doc 5 spec on feed, listing details, orders
- [ ] Empty states show correct message + action for: empty wishlist, empty cart, no search results, no orders yet
- [ ] Condition badges (Doc 5) render with text label, not color-only
- [ ] Dark mode: not in v1 scope (Doc 1) — confirm no dark-mode leakage from system theme

## 4. Network & Resilience Testing

- [ ] Slow connection (throttled 3G): feed still loads, skeletons show appropriately
- [ ] No connection: cached last-viewed feed shown (per Doc 2 NFR), clear offline indicator
- [ ] API/Function failure: `placeOrder` failure shows a clear, specific error — not a generic crash
- [ ] Retry mechanism works after reconnect

## 5. Security Testing

- [ ] Non-owner cannot edit/delete another seller's listing (rules test)
- [ ] Non-admin cannot write to `categories` or reach `/admin` routes (rules + router redirect test)
- [ ] Client cannot directly write to `orders`/`reviews`/`disputes` (rules test — these must fail)
- [ ] `git grep` before every release: no committed API keys or `google-services.json` in history

## 6. Pre-Release Manual QA Pass

- [ ] Full buyer journey on a physical Android device: splash → browse → buy → track → review
- [ ] Full seller journey: list → receive order → fulfill → get reviewed
- [ ] Full admin journey: moderate a listing, resolve a dispute, suspend a test account
- [ ] Push notifications actually arrive (order update, new review)

---

## 7. Definition of Done (per feature)

A feature is not "done" until:
1. Unit/widget tests written for its logic
2. Manually tested on a physical Android device
3. Empty, loading, and error states all implemented (not just the happy path)
4. Firestore rules cover its read/write pattern and are tested in the Emulator
5. No hardcoded/dummy data remaining (per Doc 1 success criteria)
