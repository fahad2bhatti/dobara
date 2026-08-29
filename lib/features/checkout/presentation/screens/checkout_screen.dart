import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/models/address_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../cart/data/cart_providers.dart';
import '../../../orders/domain/orders_provider.dart';
import '../../../addresses/data/addresses_providers.dart';
import '../../../../shared/constants/pk_locations.dart';

const int _kDeliveryFee = 200;

class CheckoutScreen extends ConsumerStatefulWidget {
  /// When set, this is a Buy Now purchase — the order is built from
  /// this single product instead of the persisted cart, and the cart
  /// is never read or modified.
  final Product? buyNowProduct;

  const CheckoutScreen({super.key, this.buyNowProduct});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  bool _placed = false;
  bool _placing = false;

  String? _selectedProvince;
  String? _selectedCity;
  bool _customCity = false; // true when "Other" was picked for city

  String? _selectedSavedAddressId;
  bool _saveNewAddress = false;
  String _newAddressLabel = 'Home';

  bool get _isBuyNow => widget.buyNowProduct != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _canPlaceOrder =>
      _nameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty &&
          _selectedProvince != null &&
          _cityController.text.trim().isNotEmpty;

  List<OrderItem> _buildOrderItems() {
    if (_isBuyNow) return [OrderItem.fromProduct(widget.buyNowProduct!)];
    final cartItems = ref.read(cartStreamProvider).asData?.value ?? const [];
    return cartItems.map(OrderItem.fromCartItem).toList();
  }

  void _applySavedAddress(SavedAddress a) {
    setState(() {
      _selectedSavedAddressId = a.id;
      _nameController.text = a.customerName;
      _phoneController.text = a.phone;
      _addressController.text = a.address;
      _selectedProvince = a.province;
      final cities = kCitiesByProvince[a.province] ?? const [];
      if (cities.contains(a.city)) {
        _selectedCity = a.city;
        _customCity = false;
      } else {
        _selectedCity = null;
        _customCity = true;
      }
      _cityController.text = a.city;
      _saveNewAddress = false; // already saved — no need to re-save
    });
  }

  void _startNewAddress() {
    setState(() {
      _selectedSavedAddressId = null;
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _selectedProvince = null;
      _selectedCity = null;
      _customCity = false;
      _cityController.clear();
      _saveNewAddress = false;
    });
  }

  void _confirmDeleteAddress(SavedAddress a) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${a.label}" from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(addressesActionsProvider.notifier).deleteAddress(a.id);
              if (_selectedSavedAddressId == a.id) _startNewAddress();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_canPlaceOrder || _placing) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final orderItems = _buildOrderItems();
    if (orderItems.isEmpty) return;

    setState(() => _placing = true);

    final subtotal = orderItems.fold<int>(0, (sum, i) => sum + i.subtotal);
    final order = Order(
      id: '', // assigned by Firestore on write
      buyerId: user.uid,
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: _kDeliveryFee,
      total: subtotal + _kDeliveryFee,
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      status: OrderStatus.placed,
      placedAt: DateTime.now(), // local placeholder; toMap() writes the real server value
    );

    try {
      await ref.read(ordersActionsProvider.notifier).placeOrder(order);

      // Buy Now never wrote to the cart, so there's nothing to clear.
      if (!_isBuyNow) {
        await ref.read(cartActionsProvider.notifier).clearCart();
      }

      // Persist this address for next time, if the user opted in and
      // it isn't already one of their saved addresses.
      if (_saveNewAddress && _selectedSavedAddressId == null) {
        await ref.read(addressesActionsProvider.notifier).addAddress(
          SavedAddress(
            id: '',
            label: _newAddressLabel,
            customerName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            province: _selectedProvince!,
            city: _cityController.text.trim(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _placing = false;
        _placed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_placed) return _buildConfirmation();

    // Buy Now: a single fixed item, no Firestore cart involved.
    // Normal checkout: live Firestore cart.
    final List<OrderItem> summaryItems;
    final int subtotal;
    final bool hasItems;

    if (_isBuyNow) {
      summaryItems = [OrderItem.fromProduct(widget.buyNowProduct!)];
      subtotal = summaryItems.first.subtotal;
      hasItems = true;
    } else {
      final cartAsync = ref.watch(cartStreamProvider);
      final cartItems = cartAsync.asData?.value ?? const [];
      summaryItems = cartItems.map(OrderItem.fromCartItem).toList();
      subtotal = ref.watch(cartTotalProvider);
      hasItems = cartItems.isNotEmpty;
    }
    final total = subtotal + _kDeliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('DELIVERY ADDRESS'),
                    const SizedBox(height: 10),

                    _savedAddressesRow(),
                    const SizedBox(height: 14),

                    _input(_nameController, 'Full Name'),
                    const SizedBox(height: 10),
                    _input(_phoneController, 'Phone Number',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 10),
                    _input(_addressController, 'Street Address', maxLines: 2),
                    const SizedBox(height: 14),

                    _sectionLabel('PROVINCE'),
                    const SizedBox(height: 8),
                    _provinceChips(),
                    const SizedBox(height: 14),

                    _sectionLabel('CITY'),
                    const SizedBox(height: 8),
                    _cityChips(),
                    if (_customCity) ...[
                      const SizedBox(height: 8),
                      _input(_cityController, 'Enter your city'),
                    ],
                    const SizedBox(height: 10),

                    const Text(
                      'Your exact address is shared with the seller only after the order is placed.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          height: 1.4),
                    ),
                    const SizedBox(height: 12),

                    if (_selectedSavedAddressId == null)
                      _saveAddressToggle(),
                    const SizedBox(height: 20),

                    _sectionLabel('PAYMENT METHOD'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Cash on Delivery',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel('ORDER SUMMARY'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        children: [
                          ...summaryItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.quantity > 1
                                        ? '${item.name} x${item.quantity}'
                                        : item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                Text(
                                  'Rs. ${_formatPrice(item.subtotal)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          )),
                          const Divider(height: 16, color: AppColors.divider),
                          _summaryRow(
                              'Subtotal', 'Rs. ${_formatPrice(subtotal)}'),
                          const SizedBox(height: 4),
                          _summaryRow(
                              'Delivery', 'Rs. ${_formatPrice(_kDeliveryFee)}'),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 8),
                          _summaryRow('Total', 'Rs. ${_formatPrice(total)}',
                              bold: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border:
                Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!hasItems || _placing || !_canPlaceOrder)
                      ? null
                      : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.38),
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _placing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    'Place Order · Rs. ${_formatPrice(total)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Saved addresses ─────────────────────────────────────

  Widget _savedAddressesRow() {
    final addressesAsync = ref.watch(addressesStreamProvider);
    final saved = addressesAsync.asData?.value ?? const <SavedAddress>[];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: saved.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == saved.length) {
            final selected = _selectedSavedAddressId == null &&
                _nameController.text.trim().isEmpty;
            return GestureDetector(
              onTap: _startNewAddress,
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: AppColors.primary),
                    SizedBox(height: 4),
                    Text('Add New',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            );
          }

          final a = saved[i];
          final selected = a.id == _selectedSavedAddressId;
          return GestureDetector(
            onTap: () => _applySavedAddress(a),
            onLongPress: () => _confirmDeleteAddress(a),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        a.label.toLowerCase() == 'office'
                            ? Icons.work_outline
                            : Icons.home_outlined,
                        size: 14,
                        color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${a.address}, ${a.city}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _saveAddressToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _saveNewAddress,
                onChanged: (v) => setState(() => _saveNewAddress = v ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Save this address for next time',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        if (_saveNewAddress) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: kAddressLabels.map((l) {
              final sel = l == _newAddressLabel;
              return GestureDetector(
                onTap: () => setState(() => _newAddressLabel = l),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sel ? AppColors.background : AppColors.textSecondary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Province / city chip pickers ────────────────────────

  Widget _provinceChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kProvinces.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final prov = kProvinces[i];
          final selected = prov == _selectedProvince;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedProvince = prov;
              _selectedCity = null;
              _customCity = false;
              _cityController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                prov,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.background : AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cityChips() {
    if (_selectedProvince == null) {
      return const Text(
        'Select a province first',
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
      );
    }
    final cities = kCitiesByProvince[_selectedProvince] ?? const <String>[];
    final options = [...cities, 'Other'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = options[i];
          final isOther = c == 'Other';
          final selected = isOther ? _customCity : (_selectedCity == c);
          return GestureDetector(
            onTap: () => setState(() {
              if (isOther) {
                _customCity = true;
                _selectedCity = null;
                _cityController.clear();
              } else {
                _customCity = false;
                _selectedCity = c;
                _cityController.text = c;
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                c,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.background : AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Shared small widgets ────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: AppColors.textTertiary,
    ),
  );

  Widget _input(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        const TextStyle(fontSize: 13, color: AppColors.textPlaceholder),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 14 : 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? AppColors.textPrimary : AppColors.textTertiary)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: bold ? AppColors.primary : AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                      color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check,
                      size: 32, color: AppColors.successText),
                ),
                const SizedBox(height: 12),
                const Text('Order Placed!',
                    style: TextStyle(
                        fontFamily: 'Instrument Serif',
                        fontSize: 26,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                const Text(
                  'Pay on delivery. You\'ll get updates as your order is confirmed and shipped.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      height: 1.6),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Back to Home',
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}