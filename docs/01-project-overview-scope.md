# Project Overview & Scope

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 1 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

---

## Project Goal

To design and build a production-grade Flutter + Firebase marketplace app — demonstrating full-cycle software development (architecture, backend, database design, security, and deployment) as a portfolio-quality case study, not a tutorial clone.

---

## 1. Elevator Pitch

A trust-first, Pakistan-focused marketplace where users buy and sell pre-loved (thrifted/secondhand) fashion — clothing, shoes, and accessories — with clear condition grading, seller trust scores, and fashion-specific discovery (size, brand, category filters). Where OLX/Facebook Marketplace treat used clothes as generic classifieds, this app treats them as a proper fashion retail experience.

---

## 2. Target Audience

- **Primary:** Ages 18–30, university students and young professionals in major Pakistani cities (Karachi, Lahore, Islamabad)
- **Buyer persona:** Fashion-conscious, budget-conscious — wants trendy/branded pieces without full retail price
- **Seller persona:** Has unused/outgrown clothing sitting idle, wants an easy way to resell instead of listing on generic classifieds
- **Secondary:** Sustainability-minded users who prefer reuse over fast-fashion waste

---

## 3. Problem Being Solved

- Existing platforms (OLX, Facebook Marketplace) treat secondhand clothing as generic listings — no condition standards, no fashion-specific filters, no seller accountability
- Buyers can't trust listing accuracy ("good condition" means nothing without a standard)
- No dedicated space for fashion resale culture, despite it growing in Pakistan

---

## 4. Unique Selling Point (USP)

1. **Standardized condition grading** — New with Tags / Like New / Good / Fair, applied consistently to every listing
2. **Seller trust score** — ratings, completed-sales count, response rate
3. **Fashion-specific discovery** — filter by size, brand, category, condition (not available on generic classifieds)
4. **Curated, not cluttered** — fashion-only scope keeps the catalog relevant, unlike mixed-category marketplaces

---

## 5. Business / Revenue Model

- Commission per completed sale (percentage cut on transactions)
- Optional "boosted listing" feature for sellers (paid visibility)
- Future: featured seller storefronts (small businesses/thrift resellers operating at scale)

---

## 6. App Name

**Status: LOCKED ✅**

**DOBARA** (Urdu: دوبارہ — "Again")

Brand idea: *Give pre-loved fashion a second life.*

This name carries forward into Doc 6 (Technical Architecture) as the package/app identifier (e.g. `com.dobara.app` or similar, to be finalized in that doc).

---

## 7. Scope

### In Scope (v1 / MVP)
- Buyer flow: browse, search, filter, wishlist, cart, checkout, order tracking
- Seller flow: create listing (photos, condition grade, price, category, size), manage active listings, view sales
- Admin panel: user management, listing moderation, category management, dispute handling, analytics dashboard
- Ratings & reviews (buyer → seller, post-transaction)
- Cash on Delivery as primary payment method (Pakistan market fit); online payment gateway evaluated in Doc 8
- Push notifications (order updates, listing status)

### Out of Scope (v1 — future consideration)
- In-app chat/negotiation between buyer and seller
- Auction-style listings
- International shipping
- Multi-language support (English-only for v1)
- iOS release (Android-first, per your existing FitGenie precedent)

---

## 8. Success Criteria

- Full buyer + seller + admin flow functional end-to-end on a real Firebase backend (no hardcoded data)
- Play Store-ready release build
- Portfolio-presentable: clean GitHub repo, README, architecture diagrams, case study write-up
