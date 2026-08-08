# Security & Privacy

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 9 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

---

## 1. Firestore Security Rules

Enforces the role model from Doc 6/7 directly at the database layer — client-side checks are never trusted alone.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuth() { return request.auth != null; }
    function isOwner(uid) { return request.auth.uid == uid; }
    function isAdmin() {
      return isAuth() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{uid} {
      allow read: if isAuth();
      allow write: if isOwner(uid) || isAdmin();

      match /addresses/{addressId} {
        allow read, write: if isOwner(uid);
      }
      match /cart/{listingId} {
        allow read, write: if isOwner(uid);
      }
      match /notifications/{notificationId} {
        allow read: if isOwner(uid);
        allow write: if false; // only Cloud Functions write notifications
      }
    }

    match /listings/{listingId} {
      allow read: if true; // public catalog
      allow create: if isAuth() && request.resource.data.sellerId == request.auth.uid;
      allow update, delete: if isAuth() &&
        (resource.data.sellerId == request.auth.uid || isAdmin());
    }

    match /categories/{categoryId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // orders, reviews, disputes: writes go through Cloud Functions only —
    // client cannot create/update these directly (prevents price tampering,
    // fake reviews, status manipulation)
    match /orders/{orderId} {
      allow read: if isAuth() &&
        (resource.data.buyerId == request.auth.uid ||
         resource.data.sellerId == request.auth.uid ||
         isAdmin());
      allow write: if false;
    }

    match /reviews/{reviewId} {
      allow read: if true;
      allow write: if false;
    }

    match /disputes/{disputeId} {
      allow read: if isAuth() && (resource.data.raisedBy == request.auth.uid || isAdmin());
      allow write: if false;
    }
  }
}
```

**Key decision:** `orders`, `reviews`, and `disputes` are **read-only from the client** — all writes happen through the Cloud Functions defined in Doc 8. This is the main defense against price tampering, fake delivery-status updates, and review spam.

---

## 2. Storage Security Rules (Listing Photos)

```javascript
service firebase.storage {
  match /b/{bucket}/o {
    match /listings/{listingId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## 3. Authentication Security

- Email format validated client-side before any Firebase Auth call
- Rate-limit UI: disable login/register button for 30s after 3 failed attempts (client-side guard; Firebase Auth also rate-limits server-side)
- `flutter_secure_storage` for any locally cached auth token — never `SharedPreferences`
- Firebase App Check enabled before production release — blocks scripted/bot access to Firestore and Functions

---

## 4. API Key & Secret Handling

- No API keys committed to the repo — `google-services.json` excluded from public repo history (or regenerated for release SHA-1 privately)
- Any future third-party keys (e.g. payment gateway) injected via `--dart-define`, never hardcoded
- `.gitignore` covers: `.env`, `*.jks`, `key.properties`, `google-services.json`

---

## 5. PII & Data Handling

| Data | Where stored | Access |
|---|---|---|
| Name, email, phone | `users/{uid}` | Self + admin only |
| Delivery address | `users/{uid}/addresses` | Self only |
| Address snapshot | `orders/{orderId}` | Buyer, seller (for delivery), admin |

- Phone numbers are visible to the seller **only** on an order they're fulfilling (via `addressSnapshot`) — not exposed on public profiles or listings
- Admin panel access to user PII is logged implicitly through Firebase Auth's admin-role check (Section 1) — no anonymous admin actions possible

---

## 6. Account Deletion

Required by Play Store policy (mandatory since 2023). v1 implements:
- In-app "Delete Account" flow (Profile → Settings)
- Cloud Function `deleteAccount`: removes `users/{uid}` doc and subcollections, anonymizes `orders`/`reviews` referencing the uid (keeps transaction history integrity without retaining personal data), revokes Firebase Auth account

---

## 7. Admin Authorization

- Admin role is a Firestore field (`role: 'admin'`), set manually via Firebase Console for v1 (no self-serve admin signup)
- All admin actions route through `isAdmin()` rule checks (Section 1) and admin-gated Cloud Functions (Doc 8) — never a client-side "if isAdmin, show button" without a matching server-side check

---

## 8. Out of Scope for v1 (Noted, Not Ignored)

- Formal data-protection compliance audit — Pakistan does not yet have a fully enacted data-protection law equivalent to GDPR at time of writing; this doc follows general best practice (minimize PII collection, access control, deletion support) rather than a specific regulatory framework. Revisit if a relevant law is enacted.
- Two-factor authentication (candidate for post-v1 hardening)
