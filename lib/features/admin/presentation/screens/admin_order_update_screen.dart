import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';
import '../../../orders/domain/orders_provider.dart';

/// Admin-only. Updates an order's status, tracking number, and courier
/// in one action — the buyer gets a notification the moment this saves
/// (see OrdersActions.adminUpdateOrder), so this is the single place
/// that drives the buyer's whole delivery-status experience.
class AdminOrderUpdateScreen extends ConsumerStatefulWidget {
  final Order order;

  const AdminOrderUpdateScreen({super.key, required this.order});

  @override
  ConsumerState<AdminOrderUpdateScreen> createState() =>
      _AdminOrderUpdateScreenState();
}

class _AdminOrderUpdateScreenState
    extends ConsumerState<AdminOrderUpdateScreen> {
  late OrderStatus _status;
  late final TextEditingController _trackingController;
  late final TextEditingController _courierController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _trackingController =
        TextEditingController(text: widget.order.trackingNumber ?? '');
    _courierController =
        TextEditingController(text: widget.order.courierName ?? '');
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _courierController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(ordersActionsProvider.notifier).adminUpdateOrder(
        widget.order,
        _status,
        trackingNumber: _trackingController.text.trim().isEmpty
            ? null
            : _trackingController.text.trim(),
        courierName: _courierController.text.trim().isEmpty
            ? null
            : _courierController.text.trim(),
      );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Order updated — buyer has been notified.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shortId =
    order.id.length >= 6 ? order.id.substring(order.id.length - 6) : order.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Order #$shortId')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.customerName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('${order.phone} · ${order.address}, ${order.city}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      height: 1.4)),
              const SizedBox(height: 20),

              const Text('STATUS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OrderStatus.values.map((s) {
                  final selected = s == _status;
                  return GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primaryForeground
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text('COURIER',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              TextField(
                controller: _courierController,
                decoration: _dec('e.g. TCS, Leopards, M&P'),
              ),
              const SizedBox(height: 16),

              const Text('TRACKING NUMBER',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              TextField(
                controller: _trackingController,
                decoration: _dec('e.g. TCS123456789'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Saving sends the buyer a notification with the new status and this tracking info.',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    height: 1.5),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Save & Notify Buyer',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textPlaceholder),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
  );
}
