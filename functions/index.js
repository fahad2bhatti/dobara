const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

const db = admin.firestore();

// Mirrors the constant in checkout_screen.dart — keep both in sync if
// delivery pricing ever changes.
const DELIVERY_FEE = 200;

/**
 * Recomputes each item's price from the live listing doc instead of
 * trusting whatever the client sends, so a buyer can never place an
 * order at a price they typed in themselves.
 */
function effectivePrice(listing) {
  const price = Number(listing.price) || 0;
  const discountPercent = listing.discountPercent;
  if (discountPercent && discountPercent > 0) {
    return Math.round(price - (price * discountPercent) / 100);
  }
  return price;
}

exports.placeOrder = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "You must be signed in to place an order.");
  }

  const data = request.data || {};
  const rawItems = Array.isArray(data.items) ? data.items : [];
  const customerName = String(data.customerName || "").trim();
  const phone = String(data.phone || "").trim();
  const address = String(data.address || "").trim();
  const city = String(data.city || "").trim();

  if (rawItems.length === 0) {
    throw new HttpsError("invalid-argument", "Cart is empty.");
  }
  if (!customerName || !phone || !address || !city) {
    throw new HttpsError("invalid-argument", "Missing delivery details.");
  }

  // Fetch every listing referenced by the cart in one batch — this is
  // the server-side source of truth for price, name, image, and seller.
  const listingIds = rawItems.map((i) => String(i.listingId || ""));
  if (listingIds.some((id) => !id)) {
    throw new HttpsError("invalid-argument", "Invalid item in cart.");
  }

  const listingSnaps = await db.getAll(
    ...listingIds.map((id) => db.collection("listings").doc(id))
  );

  const items = [];
  for (let i = 0; i < rawItems.length; i++) {
    const snap = listingSnaps[i];
    if (!snap.exists) {
      throw new HttpsError("not-found", `Listing ${listingIds[i]} no longer exists.`);
    }
    const listing = snap.data();
    if (listing.isSoldOut) {
      throw new HttpsError(
        "failed-precondition",
        `"${listing.name || "An item"}" in your cart just sold out.`
      );
    }

    const quantity = Math.max(1, Math.floor(Number(rawItems[i].quantity) || 1));
    const price = effectivePrice(listing);

    items.push({
      listingId: snap.id,
      name: listing.name || "",
      price,
      imageUrl: (listing.imageUrls && listing.imageUrls[0]) || "",
      sellerId: (listing.seller && listing.seller.id) || "",
      sellerName: (listing.seller && listing.seller.name) || "Dobara Seller",
      quantity,
    });
  }

  const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const total = subtotal + DELIVERY_FEE;
  const sellerIds = [...new Set(items.map((i) => i.sellerId))];

  const orderRef = await db.collection("orders").add({
    buyerId: auth.uid,
    items,
    sellerIds,
    subtotal,
    deliveryFee: DELIVERY_FEE,
    total,
    customerName,
    phone,
    address,
    city,
    status: "placed",
    placedAt: admin.firestore.FieldValue.serverTimestamp(),
    trackingNumber: null,
    courierName: null,
  });

  return { orderId: orderRef.id };
});
