import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../cart/data/cart_providers.dart';
import '../../../orders/domain/orders_provider.dart';

const int _kDeliveryFee = 200;

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

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
          _cityController.text.trim().isNotEmpty;

  Future<void> _placeOrder() async {
    if (!_canPlaceOrder || _placing) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final cartItems = ref.read(cartStreamProvider).asData?.value ?? const [];
    if (cartItems.isEmpty) return;

    setState(() => _placing = true);

    final subtotal = ref.read(cartTotalProvider);
    final order = Order(
      id: '', // assigned by Firestore on write
      buyerId: user.uid,
      items: cartItems.map(OrderItem.fromCartItem).toList(),
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
      await ref.read(cartActionsProvider.notifier).clearCart();
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

    final cartAsync = ref.watch(cartStreamProvider);
    final items = cartAsync.asData?.value ?? const [];
    final subtotal = ref.watch(cartTotalProvider);
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
                    _input(_nameController, 'Full Name'),
                    const SizedBox(height: 10),
                    _input(_phoneController, 'Phone Number',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 10),
                    _input(_addressController, 'Street Address', maxLines: 2),
                    const SizedBox(height: 10),
                    _input(_cityController, 'City'),
                    const SizedBox(height: 6),
                    const Text(
                      'Your exact address is shared with the seller only after the order is placed.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          height: 1.4),
                    ),
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
                          ...items.map((item) => Padding(
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
                  onPressed: (items.isEmpty || _placing) ? null : _placeOrder,
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
                    'Place Order — Rs. ${_formatPrice(total)}',
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