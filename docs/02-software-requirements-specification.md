# Software Requirements Specification (SRS)

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 2 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

---

## 1. Purpose

This document defines the functional and non-functional requirements for Dobara v1 (MVP). It builds directly on Doc 1 (Project Overview & Scope) — anything marked "Out of Scope" there is not covered here.

---

## 2. User Roles

| Role | Description |
|---|---|
| **Buyer** | Browses, searches, purchases listings |
| **Seller** | Creates and manages listings, fulfills orders |
| **Buyer/Seller** | A single account can act as both — no separate registration needed |
| **Admin** | Moderates listings/users, manages categories, handles disputes, views analytics |

---

## 3. Functional Requirements

### 3.1 Authentication (Buyer/Seller)
- FR-1.1: User can register with email + password
- FR-1.2: User can log in / log out
- FR-1.3: User can reset password via email
- FR-1.4: User can view/edit their profile (name, phone, address, profile photo)
- FR-1.5: Session persists across app restarts until explicit logout

### 3.2 Listings (Seller)
- FR-2.1: Seller can create a listing with: photos (min 1, max 6), title, description, category, size, brand, condition grade, price
- FR-2.2: Seller can edit or delete their own active listings
- FR-2.3: Seller can mark a listing as sold manually
- FR-2.4: Listing automatically marked sold when an order for it is completed
- FR-2.5: Seller can view all their listings filtered by status (Active / Sold / Removed)

### 3.3 Discovery (Buyer)
- FR-3.1: Buyer can browse listings via home feed
- FR-3.2: Buyer can search listings by keyword
- FR-3.3: Buyer can filter by category, size, brand, condition grade, price range
- FR-3.4: Buyer can sort by newest, price (low-high/high-low)
- FR-3.5: Buyer can view full listing details (all photos, description, seller info, seller trust score)

### 3.4 Wishlist
- FR-4.1: Buyer can add/remove a listing to/from wishlist
- FR-4.2: Buyer can view all wishlisted items

### 3.5 Cart & Checkout
- FR-5.1: Buyer can add a listing to cart (single quantity — each listing is a unique secondhand item)
- FR-5.2: Buyer can remove items from cart
- FR-5.3: Buyer can view cart subtotal + delivery charges + total
- FR-5.4: Buyer selects/adds a delivery address at checkout
- FR-5.5: Buyer confirms order with Cash on Delivery (v1 payment method)
- FR-5.6: System prevents checkout if any cart item was sold/removed after being added

### 3.6 Orders
- FR-6.1: Buyer can view order history with status (Placed → Confirmed → Shipped → Delivered, or Cancelled)
- FR-6.2: Buyer can cancel an order before it ships
- FR-6.3: Seller can view incoming orders for their listings and update status
- FR-6.4: Buyer and Seller both receive notifications on status change

### 3.7 Ratings & Reviews
- FR-7.1: Buyer can rate + review a Seller after order is marked Delivered
- FR-7.2: Seller's trust score is calculated from their review history
- FR-7.3: Reviews are visible on the seller's public profile

### 3.8 Admin Panel
- FR-8.1: Admin can view/search all users and suspend/reinstate accounts
- FR-8.2: Admin can view/moderate/remove any listing
- FR-8.3: Admin can manage categories (add/edit/delete)
- FR-8.4: Admin can view dashboard: total users, total listings, total orders, revenue (commission earned)
- FR-8.5: Admin can view and resolve flagged disputes (buyer/seller reported issues)

### 3.9 Notifications
- FR-9.1: Push notification on order status change
- ~~FR-9.2: Push notification when a wishlisted item's price drops~~ — **moved to future backlog** (needs price-history tracking + background triggers; adds MVP complexity without core value)
- FR-9.3: Push notification on new review received

---

## 4. Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | Listing feed loads in <2s on average 4G connection; pagination after 20 items |
| **Scalability** | Firestore structure must support growth to 50k+ listings without redesign |
| **Security** | No sensitive data (passwords, tokens) stored client-side in plain form; Firestore rules enforce role-based access |
| **Availability** | Firebase-backed — no self-hosted uptime concerns for v1 |
| **Usability** | Core buyer flow (browse → buy) completable in ≤5 taps from home |
| **Compatibility** | Android, minSdkVersion 21+ (per your existing FitGenie precedent) |
| **Maintainability** | Feature-first folder structure (per Doc 6); no hardcoded data in production build |
| **Offline behavior** | Cached last-viewed feed shown when offline; clear "no internet" state for actions requiring network |

---

## 5. Assumptions & Constraints

- Firebase is the backend for v1 (confirmed in Doc 1) — no custom server
- COD is the only payment method for v1 — no payment gateway integration required yet (revisit in Doc 8)
- Single currency: PKR
- Android-only for v1

---

## 6. Future Backlog (Out of v1)

- Price-drop notifications on wishlisted items (FR-9.2, deferred)
