# User Flow & Screen Flow

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 4 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

---

## 1. Buyer Flow (Primary Path)

```
Splash
  ↓
Onboarding (first launch only)
  ↓
Login / Register
  ↓
Home Feed
  ├── Category Browse
  ├── Search + Filters
  └── Wishlist
  ↓
Listing Details
  ├── Add to Wishlist
  └── Add to Cart
  ↓
Cart
  ↓
Checkout
  ├── Select/Add Address
  └── Confirm Order (COD)
  ↓
Order Success
  ↓
Order Tracking → Order History
  ↓
(Post-delivery) Rate & Review Seller
```

## 2. Seller Flow

```
Home Feed (bottom nav)
  ↓
My Listings
  ↓
Create Listing
  ├── Upload Photos (1–6)
  ├── Title, Description
  ├── Category, Size, Brand
  ├── Condition Grade
  └── Price
  ↓
Listing Published (status: Active)
  ↓
Incoming Orders
  ↓
Update Order Status (Confirmed → Shipped → Delivered)
  ↓
Listing auto-marked Sold
```

## 3. Admin Flow

```
Admin Login
  ↓
Dashboard (KPIs)
  ├── User Management → Suspend/Reinstate
  ├── Listing Moderation → Remove
  ├── Category Management → Add/Edit/Delete
  ├── Order Oversight → Filter by status
  ├── Dispute Resolution → Resolve
  └── Reviews Moderation → Remove
```

## 4. Bottom Navigation (Buyer/Seller shared account)

| Tab | Screen |
|---|---|
| Home | Discovery feed |
| Search | Search + filters |
| Sell | Create listing (seller entry point) |
| Wishlist | Saved items |
| Profile | Account, My Listings, Orders, Settings |

## 5. Screen Inventory (for Doc 6 folder mapping)

**Auth:** Splash, Onboarding, Login, Register, ForgotPassword
**Home:** HomeFeed, CategoryBrowse, SearchResults, Filters
**Listings:** ListingDetails, CreateListing, EditListing, MyListings
**Wishlist:** WishlistScreen
**Cart:** CartScreen, Checkout, AddressForm
**Orders:** OrderHistory, OrderDetails, IncomingOrders (seller)
**Profile:** ProfileScreen, EditProfile, SellerPublicProfile, Settings
**Reviews:** WriteReview, ReviewsList
**Admin:** AdminDashboard, UserManagement, ListingModeration, CategoryManagement, OrderOversight, DisputeResolution, ReviewModeration
