# Database Schema (ERD)

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 7 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

Database: **Cloud Firestore**. Rules: max 2 levels of subcollections, denormalize for read performance, `serverTimestamp()` everywhere (per Doc 6 conventions).

---

## 1. Collections Overview

```
users/{uid}
  └── addresses/{addressId}
  └── cart/{listingId}
  └── notifications/{notificationId}

listings/{listingId}

categories/{categoryId}

orders/{orderId}

reviews/{reviewId}

disputes/{disputeId}
```

---

## 2. Field-Level Schema

### `users/{uid}`
| Field | Type | Notes |
|---|---|---|
| displayName | string | |
| email | string | |
| phone | string | |
| photoURL | string | |
| role | string | `buyer_seller` \| `admin` (single role model — see Doc 6) |
| status | string | `active` \| `suspended` |
| trustScore | number | derived, recalculated on new review (avg rating) |
| ratingCount | number | denormalized count, avoids reading all reviews to show a number |
| fcmToken | string | for push notifications |
| createdAt | timestamp | `serverTimestamp()` |

### `users/{uid}/addresses/{addressId}`
| Field | Type |
|---|---|
| label | string |
| line1 | string |
| city | string |
| phone | string |
| isDefault | boolean |

### `users/{uid}/cart/{listingId}`
| Field | Type |
|---|---|
| addedAt | timestamp |

Cart is stored server-side (not just local Riverpod state) so it persists across devices/reinstalls — small enough to justify a subcollection.

### `listings/{listingId}`
| Field | Type | Notes |
|---|---|---|
| sellerId | string (ref) | |
| sellerName | string | **denormalized** — avoids a join to show seller name on every card |
| title | string | |
| description | string | |
| categoryId | string (ref) | |
| size | string | |
| brand | string | |
| conditionGrade | string | `new_with_tags` \| `like_new` \| `good` \| `fair` |
| price | number | PKR |
| photos | array\<string\> | Storage URLs, max 6 |
| status | string | `active` \| `sold` \| `removed` |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `categories/{categoryId}`
| Field | Type |
|---|---|
| name | string |
| parentId | string (nullable) — null for top-level (Clothing/Shoes/Accessories) |
| order | number |

### `orders/{orderId}`
| Field | Type | Notes |
|---|---|---|
| buyerId | string (ref) | |
| sellerId | string (ref) | |
| listingId | string (ref) | |
| listingTitle | string | **denormalized** snapshot (listing may be edited/deleted later) |
| listingPhoto | string | **denormalized** snapshot |
| price | number | snapshot at time of order |
| deliveryCharge | number | |
| total | number | |
| addressSnapshot | map | copied from address doc at order time — address may change later, order must keep what was used |
| status | string | `placed` → `confirmed` → `shipped` → `delivered`, or `cancelled` |
| createdAt | timestamp | |
| updatedAt | timestamp | |

**Design decision:** one order = one listing (not a cart of order-items). Since every listing is a unique secondhand item, a multi-item cart checkout creates **one order document per listing**, even if the buyer checked out several at once. This avoids a nested `order_items` subcollection and keeps per-seller order status independent (Seller A shipping doesn't block Seller B's item).

### `reviews/{reviewId}`
| Field | Type |
|---|---|
| orderId | string (ref) |
| buyerId | string (ref) |
| sellerId | string (ref) |
| rating | number (1–5) |
| comment | string |
| createdAt | timestamp |

### `disputes/{disputeId}`
| Field | Type |
|---|---|
| orderId | string (ref) |
| raisedBy | string (ref, uid) |
| reason | string |
| status | string — `open` \| `resolved` |
| resolutionNotes | string |
| createdAt | timestamp |
| resolvedAt | timestamp (nullable) |

### `users/{uid}/notifications/{notificationId}`
| Field | Type |
|---|---|
| type | string — `order_update` \| `new_review` |
| message | string |
| relatedId | string — orderId or reviewId |
| read | boolean |
| createdAt | timestamp |

---

## 3. Relationships

```
User (seller) ──< Listing
User (buyer)  ──< Order >── Listing
Order         ──< Review
Order         ──< Dispute
User          ──< Address (subcollection)
User          ──< Cart item (subcollection)
User          ──< Notification (subcollection)
Category      ──< Listing (via categoryId)
```

---

## 4. Denormalization Summary (and why)

| Denormalized field | Lives in | Reason |
|---|---|---|
| `sellerName` | `listings` | Avoid a user-doc read per card in a feed of 20+ listings |
| `listingTitle`, `listingPhoto` | `orders` | Listing may be edited or removed after the order is placed — order must show what was actually bought |
| `trustScore`, `ratingCount` | `users` | Avoid aggregating all reviews on every profile view |
| `addressSnapshot` | `orders` | Address may be edited/deleted later — delivery must reflect what was true at order time |

---

## 5. Indexing Notes (for Firebase Console)

- Composite index: `listings` on (`categoryId`, `status`, `createdAt desc`) — for filtered + sorted feed
- Composite index: `orders` on (`sellerId`, `status`) — for seller's incoming-orders view
- Composite index: `orders` on (`buyerId`, `createdAt desc`) — for buyer's order history
