# Complete Feature List

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 3 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

Traces directly to Doc 2 (SRS) functional requirements — FR references included for each feature.

---

## A. Customer App (Buyer + Seller — single account, dual role)

### A1. Authentication & Profile
- Splash screen
- Onboarding (3-screen intro to condition grading + trust score concept)
- Register / Login / Forgot password (FR-1.1–1.3)
- Edit profile: name, phone, address, profile photo (FR-1.4)
- Persistent session (FR-1.5)
- Logout

### A2. Home / Discovery
- Home feed: recent listings, curated categories
- Category browsing (Clothing, Shoes, Accessories → subcategories)
- Search by keyword (FR-3.2)
- Filters: category, size, brand, condition grade, price range (FR-3.3)
- Sort: newest, price low-high, price high-low (FR-3.4)
- Pagination (20 items/page, per Doc 2 NFR)

### A3. Listing Details
- Photo gallery (up to 6 images)
- Title, description, category, size, brand, condition grade, price
- Seller info card: name, trust score, member since, ratings (FR-3.5)
- Add to wishlist / Add to cart

### A4. Wishlist
- Add/remove listing (FR-4.1)
- Wishlist screen (FR-4.2)

### A5. Cart & Checkout
- Add/remove listing from cart (single qty per unique item) (FR-5.1–5.2)
- Cart summary: subtotal, delivery charge, total (FR-5.3)
- Address selection / add new address (FR-5.4)
- Order confirmation — Cash on Delivery (FR-5.5)
- Stale-cart guard: blocks checkout if item was sold/removed (FR-5.6)

### A6. Orders (Buyer)
- Order history list with status (FR-6.1)
- Order detail view
- Cancel order (pre-shipment only) (FR-6.2)

### A7. Seller Tools
- Create listing: photos, title, description, category, size, brand, condition, price (FR-2.1)
- Edit / delete own listing (FR-2.2)
- Manually mark as sold (FR-2.3)
- Auto-mark sold on completed order (FR-2.4)
- My Listings, filterable by Active / Sold / Removed (FR-2.5)
- Incoming orders view + status update (FR-6.3)

### A8. Ratings & Reviews
- Buyer rates/reviews seller post-delivery (FR-7.1)
- Trust score shown on seller profile (FR-7.2, FR-7.3)

### A9. Notifications
- Order status change (FR-9.1)
- New review received (FR-9.2, renumbered post-Doc-2 lock)

---

## B. Admin Panel

### B1. Dashboard
- Total users, total listings, total orders
- Revenue (commission earned)
- Basic trend view (orders/day, new users/day)

### B2. User Management
- Search/view all users
- Suspend / reinstate account (FR-8.1)

### B3. Listing Moderation
- View/search all listings
- Remove listing (policy violation) (FR-8.2)

### B4. Category Management
- Add / edit / delete categories & subcategories (FR-8.3)

### B5. Order Oversight
- View all orders across the platform
- Filter by status

### B6. Dispute Resolution
- View flagged disputes (buyer/seller reported issues)
- Resolve with action (refund guidance, warning, listing removal) (FR-8.5)

### B7. Reviews Moderation
- View all reviews
- Remove reviews that violate policy (spam, abuse)

---

## C. Explicitly Deferred (Future Backlog)

- In-app buyer/seller chat or negotiation
- Auction-style listings
- Price-drop notifications (deferred in Doc 2)
- Online payment gateway (COD only for v1 — revisit in Doc 8)
- Boosted/paid listing visibility (revenue model exists in Doc 1, implementation deferred)
- iOS release
