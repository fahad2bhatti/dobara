import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/listings_provider.dart';

const List<String> _kCategories = ['Clothing', 'Shoes', 'Bags', 'Accessories'];

/// Simple single-page edit form for an existing listing — unlike the
/// guided 8-step Sell flow (which is for creating new listings), an
/// edit just needs a straightforward form since all fields already
/// have values. Admin-only (route + Firestore rules both enforce this).
class EditListingScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditListingScreen({super.key, required this.product});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _sizeController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;
  late String _category;
  late ConditionGrade _condition;
  late bool _soldOut;
  bool _saving = false;

  // Images: existing (already-uploaded) URLs the admin can remove,
  // plus newly picked bytes that get uploaded to Cloudinary on save.
  late List<String> _existingImageUrls;
  final List<Uint8List> _newImages = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _brandController = TextEditingController(text: p.brand);
    _sizeController = TextEditingController(text: p.size ?? '');
    _priceController = TextEditingController(text: p.price.toString());
    _descController = TextEditingController(text: p.description);
    _category = _kCategories.contains(p.category) ? p.category : _kCategories.first;
    _condition = p.condition;
    _soldOut = p.isSoldOut;
    _existingImageUrls = List<String>.from(p.imageUrls);
  }

  int get _totalImageCount => _existingImageUrls.length + _newImages.length;

  Future<void> _pickImage() async {
    if (_totalImageCount >= 8) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _newImages.add(bytes));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_priceController.text.trim());
    if (_nameController.text.trim().isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and price.')),
      );
      return;
    }
    if (_totalImageCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please keep at least one photo.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var imageUrls = _existingImageUrls;
      if (_newImages.isNotEmpty) {
        final user = ref.read(currentUserProvider);
        final uploaded = await ref.read(storageServiceProvider).uploadListingImages(
          sellerId: user?.uid ?? widget.product.seller.id,
          listingId: widget.product.id,
          images: _newImages,
        );
        imageUrls = [..._existingImageUrls, ...uploaded];
      }

      await ref.read(listingsActionsProvider.notifier).updateListing(
        widget.product.id,
        {
          'name': _nameController.text.trim(),
          'brand': _brandController.text.trim(),
          'size': _sizeController.text.trim().isEmpty
              ? null
              : _sizeController.text.trim(),
          'price': price,
          'category': _category,
          'condition': _condition.label,
          'description': _descController.text.trim(),
          'isSoldOut': _soldOut,
          'imageUrls': imageUrls,
        },
      );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update listing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Listing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photos ────────────────────────────────
              _labeled('PHOTOS', GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  ...List.generate(_existingImageUrls.length, (i) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _existingImageUrls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                Container(color: AppColors.muted),
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.muted,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 3,
                          right: 3,
                          child: GestureDetector(
                            onTap: () => setState(
                                    () => _existingImageUrls.removeAt(i)),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  ...List.generate(_newImages.length, (i) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_newImages[i], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 3,
                          right: 3,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _newImages.removeAt(i)),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 3,
                          left: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('NEW',
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_totalImageCount < 8)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4EF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 20, color: AppColors.accent),
                            SizedBox(height: 3),
                            Text('Add Photo',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ),
                ],
              )),
              const SizedBox(height: 18),

              // ── Sold out toggle ──────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _soldOut ? AppColors.warningBg : AppColors.muted,
                  borderRadius: BorderRadius.circular(14),
                  border: _soldOut
                      ? Border.all(color: AppColors.warningBorder, width: 1)
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sold Out',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _soldOut
                                  ? AppColors.warningText
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hides Buy/Add to Cart and shows a Sold Out badge.',
                            style: TextStyle(
                              fontSize: 11,
                              color: _soldOut
                                  ? AppColors.warningText
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _soldOut,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _soldOut = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _labeled('NAME', TextField(
                controller: _nameController,
                decoration: _dec('Item name'),
              )),
              const SizedBox(height: 14),
              _labeled('BRAND', TextField(
                controller: _brandController,
                decoration: _dec("e.g. Levi's, Nike, Zara"),
              )),
              const SizedBox(height: 14),
              _labeled('SIZE', TextField(
                controller: _sizeController,
                decoration: _dec('e.g. M, L, UK 9'),
              )),
              const SizedBox(height: 14),

              _labeled('CATEGORY', Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kCategories.map((c) {
                  final selected = c == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
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
                        c,
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
              )),
              const SizedBox(height: 14),

              _labeled('CONDITION', Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ConditionGrade.values.map((g) {
                  final selected = g == _condition;
                  return GestureDetector(
                    onTap: () => setState(() => _condition = g),
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
                        g.label,
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
              )),
              const SizedBox(height: 14),

              _labeled('PRICE', Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('Rs.',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 14),

              _labeled('DESCRIPTION', TextField(
                controller: _descController,
                maxLines: 5,
                decoration: _dec('Describe the item...'),
              )),
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
                      : const Text('Save Changes',
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

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.textTertiary)),
        const SizedBox(height: 7),
        child,
      ],
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
