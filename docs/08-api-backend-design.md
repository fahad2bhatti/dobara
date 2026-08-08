# API / Backend Design

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 8 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

No custom REST API — Flutter talks to Firestore directly for reads and simple writes (per client SDK + security rules, Doc 9). **Cloud Functions** cover the operations that must not trust the client: order creation, status transitions, commission math, and trust-score recalculation.

---

## 1. Callable Cloud Functions

### `placeOrder`
**Trigger:** Callable, invoked at checkout
**Input:** `{ listingIds: string[], addressId: string }`
**Behavior:**
1. Re-validates each listing is still `status: active` (server-side — prevents the stale-cart race from Doc 2, FR-5.6)
2. Creates one `orders/{orderId}` document per listing (per Doc 7 design decision)
3. Sets each listing's `status` to `sold`
4. Snapshots address into `addressSnapshot`
**Output:** `{ orderIds: string[] }` or a typed error if any listing is no longer available

### `updateOrderStatus`
**Trigger:** Callable, invoked by seller (or admin)
**Input:** `{ orderId: string, newStatus: string }`
**Behavior:** Validates the caller is the order's `sellerId` (or an admin), enforces valid transitions only (`placed → confirmed → shipped → delivered`; `placed/confirmed → cancelled`), updates `orders/{orderId}`
**Output:** `{ success: true }`

### `cancelOrder`
**Trigger:** Callable, invoked by buyer
**Input:** `{ orderId: string }`
**Behavior:** Only allowed while status is `placed` or `confirmed` (per SRS FR-6.2). Reverts the listing back to `status: active`.
**Output:** `{ success: true }`

### `submitReview`
**Trigger:** Callable, invoked by buyer after delivery
**Input:** `{ orderId: string, rating: number, comment: string }`
**Behavior:** Validates order belongs to caller and `status: delivered`, validates one review per order, writes `reviews/{reviewId}`
**Output:** `{ success: true }`

### `raiseDispute` / `resolveDispute`
**Trigger:** Callable
**Input (raise):** `{ orderId: string, reason: string }`
**Input (resolve, admin-only):** `{ disputeId: string, resolutionNotes: string }`

---

## 2. Firestore Triggers (Background Functions)

### `onReviewCreated`
**Trigger:** Firestore `onCreate` on `reviews/{reviewId}`
**Behavior:** Recalculates `trustScore` and increments `ratingCount` on the seller's `users/{sellerId}` doc. Keeps the denormalized fields in Doc 7 accurate without a client-side aggregation query.

### `onOrderStatusChange`
**Trigger:** Firestore `onUpdate` on `orders/{orderId}` (when `status` field changes)
**Behavior:** Writes a notification document to `users/{buyerId}/notifications` (and seller's, where relevant) and sends an FCM push — covers SRS FR-9.1.

### `onListingSold` (commission tracking)
**Trigger:** Firestore `onUpdate` on `listings/{listingId}` (when `status` → `sold`)
**Behavior:** Computes commission (platform's cut, per Doc 1 revenue model) and writes a lightweight `commission_ledger` entry for the admin dashboard's revenue KPI — kept separate from `orders` so ledger logic doesn't complicate the order-status flow.

---

## 3. Payment Note

v1 is Cash on Delivery only (Doc 1, Doc 2) — no payment gateway function is needed yet. If a gateway (e.g. JazzCash/EasyPaisa) is added later, it plugs in as an additional Cloud Function (`initiatePayment` / a webhook handler) without changing the `orders` schema — `total` and `status` fields already accommodate it.

---

## 4. Why Callable Functions, Not a REST Layer

Callable Cloud Functions integrate directly with Firebase Auth (caller identity is verified automatically) and are invoked from Flutter via the `cloud_functions` SDK — no separate API-key/auth-header plumbing, no hosting to manage. A REST layer would duplicate what Firebase already provides for this project's scope.
