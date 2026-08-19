import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/condition_badge.dart';
import '../../../../shared/widgets/trust_score.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/listings_provider.dart';

const List<String> _kSellCategories = ['Clothing', 'Shoes', 'Bags', 'Accessories'];
const List<String> _kStepTitles = [
  'Add Photos',
  'Category',
  'Condition',
  'Product Details',
  'Set Your Price',
  'Description',
  'Preview',
  'Publish',
];
const int _kTotalSteps = 8;

class _SellForm {
  String category = '';
  ConditionGrade? condition;
  String brand = '';
  String size = '';
  String color = '';
  String price = '';
  String description = '';
}

/// Guided, multi-step sell flow — matches Doc 5 spec:
/// Photos → Category → Condition → Details → Price → Description
/// → Preview → Publish. Condition is picker-only, never free text.
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  int _step = 1;
  bool _published = false;
  bool _publishing = false;
  final _form = _SellForm();
  final List<Uint8List> _pickedImages = [];

  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _brandController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _canNext {
    if (_step == 2) return _form.category.isNotEmpty;
    if (_step == 3) return _form.condition != null;
    if (_step == 5) {
      final p = int.tryParse(_form.price);
      return p != null && p > 0;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedImages.add(bytes));
    }
  }

  // TEMP: while Storage billing is unresolved, publish with a category
  // placeholder instead of the picked photos. Remove once Storage works.

  Future<void> _publishListing() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _publishing = true);

    // Prefer the Firestore profile (has real trust score / sales count);
    // fall back to bare Auth user info if the profile hasn't loaded yet.
    final profile = ref.read(userProfileProvider).asData?.value;
    final seller = Seller(
      id: user.uid,
      name: profile?.name ?? user.displayName ?? user.email ?? 'Dobara Seller',
      trustScore: profile?.trustScore,
      completedSales: profile?.completedSales ?? 0,
      avatarUrl: profile?.avatarUrl ?? '',
    );

    try {
      await ref.read(listingsRepositoryProvider).publishListing(
        name: _form.brand.isEmpty
            ? '${_form.category} Item'
            : '${_form.brand} ${_form.category}',
        brand: _form.brand.isEmpty ? 'Unbranded' : _form.brand,
        price: int.tryParse(_form.price) ?? 0,
        condition: _form.condition!,
        category: _form.category,
        size: _form.size.isEmpty ? null : _form.size,
        city: profile?.city ?? 'Lahore',
        description: _form.description,
        seller: seller,
        images: _pickedImages,
      );
      if (mounted) {
        setState(() {
          _publishing = false;
          _published = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _publishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish listing: $e')),
        );
      }
    }
  }

  void _handleNext() {
    if (!_canNext) return;
    if (_step < _kTotalSteps) {
      setState(() => _step++);
    } else {
      _publishListing();
    }
  }

  void _handleBack() {
    if (_step > 1) setState(() => _step--);
  }

  void _reset() {
    setState(() {
      _published = false;
      _step = 1;
      _form.category = '';
      _form.condition = null;
      _form.brand = '';
      _form.size = '';
      _form.color = '';
      _form.price = '';
      _form.description = '';
      _brandController.clear();
      _sizeController.clear();
      _colorController.clear();
      _priceController.clear();
      _descController.clear();
      _pickedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_published) return _buildPublishedState();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _buildStepContent(),
              ),
            ),
            _buildCta(),
          ],
        ),
      ),
    );
  }

  // ── Header + progress bar ──────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_step > 1)
                    GestureDetector(
                      onTap: _handleBack,
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            size: 15, color: AppColors.primary),
                      ),
                    ),
                  const Text(
                    'Sell an Item',
                    style: TextStyle(
                      fontFamily: 'Instrument Serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$_step / $_kTotalSteps',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_step - 1) / (_kTotalSteps - 1),
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _kStepTitles[_step - 1].toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step router ─────────────────────────────────────
  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildPhotosStep();
      case 2:
        return _buildCategoryStep();
      case 3:
        return _buildConditionStep();
      case 4:
        return _buildDetailsStep();
      case 5:
        return _buildPriceStep();
      case 6:
        return _buildDescriptionStep();
      case 7:
        return _buildPreviewStep();
      case 8:
        return _buildPublishStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Photos ──────────────────────────────────
  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add up to 8 photos. Clear, well-lit photos sell 3× faster.',
          style: TextStyle(
              fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            if (_pickedImages.length < 8)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_outlined,
                          size: 22, color: AppColors.accent),
                      SizedBox(height: 4),
                      Text('Add Photo',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ...List.generate(_pickedImages.length, (i) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_pickedImages[i], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 3,
                    right: 3,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _pickedImages.removeAt(i)),
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
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.successBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('📸 Photo tips',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successText)),
              SizedBox(height: 6),
              Text('· Use natural daylight for true colour',
                  style: TextStyle(fontSize: 11, color: AppColors.successText)),
              Text('· Show front, back, and any flaws',
                  style: TextStyle(fontSize: 11, color: AppColors.successText)),
              Text('· Include size labels if visible',
                  style: TextStyle(fontSize: 11, color: AppColors.successText)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2: Category ────────────────────────────────
  Widget _buildCategoryStep() {
    const icons = {
      'Clothing': '👕',
      'Shoes': '👟',
      'Bags': '👜',
      'Accessories': '💍',
    };
    const subs = {
      'Clothing': 'Tops, bottoms, dresses & more',
      'Shoes': 'Sneakers, heels, boots & sandals',
      'Bags': 'Handbags, backpacks & wallets',
      'Accessories': 'Jewellery, belts, scarves & more',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('What are you selling?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        ..._kSellCategories.map((c) {
          final sel = _form.category == c;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _form.category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                      width: 2),
                ),
                child: Row(
                  children: [
                    Text(icons[c]!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? AppColors.background
                                      : AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(subs[c]!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: sel
                                      ? AppColors.background.withValues(alpha: 0.7)
                                      : AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    if (sel)
                      const Icon(Icons.check,
                          size: 18, color: AppColors.background),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 3: Condition ───────────────────────────────
  Widget _buildConditionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Select the condition that best describes your item. Be honest — it builds trust.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
        ...ConditionGrade.values.map((grade) {
          final colors = AppColors.conditionColors[grade.label]!;
          final sel = _form.condition == grade;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _form.condition = grade),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: sel ? colors.bg : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? colors.border : AppColors.border, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration:
                      BoxDecoration(color: colors.dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(grade.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.text)),
                          const SizedBox(height: 2),
                          Text(grade.description,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.mutedForeground)),
                        ],
                      ),
                    ),
                    if (sel) Icon(Icons.check, size: 14, color: colors.text),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 4: Product Details ─────────────────────────
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Text('Tell buyers more about your item.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 14),
        _labeledInput('BRAND', _brandController, "e.g. Levi's, Nike, Zara",
                (v) => _form.brand = v),
        const SizedBox(height: 16),
        _labeledInput('SIZE', _sizeController, 'e.g. M, L, UK 9, 32×30',
                (v) => _form.size = v),
        const SizedBox(height: 16),
        _labeledInput('COLOUR', _colorController, 'e.g. Navy Blue, Off-White',
                (v) => _form.color = v),
      ],
    );
  }

  Widget _labeledInput(String label, TextEditingController controller,
      String hint, ValueChanged<String> onChanged) {
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
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 13, color: AppColors.textPlaceholder),
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
        ),
      ],
    );
  }

  // ── Step 5: Price ────────────────────────────────────
  Widget _buildPriceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Text('Set a fair price. Competitive prices sell faster.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 16),
        const Text('ASKING PRICE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.textTertiary)),
        const SizedBox(height: 7),
        Container(
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
                  onChanged: (v) => setState(() => _form.price = v),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warningBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡 Pricing Guide',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warningText)),
              const SizedBox(height: 8),
              ..._pricingGuideRow('Like New', '60–80% of retail'),
              ..._pricingGuideRow('Excellent', '40–60% of retail'),
              ..._pricingGuideRow('Good', '20–40% of retail'),
              ..._pricingGuideRow('Fair / Well Worn', '10–20% of retail'),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _pricingGuideRow(String label, String range) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.warningText)),
            Text(range,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningText)),
          ],
        ),
      ),
    ];
  }

  // ── Step 6: Description ─────────────────────────────
  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Text('Give buyers the full picture. Be honest about any flaws.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          maxLength: 500,
          maxLines: 7,
          onChanged: (v) => setState(() => _form.description = v),
          style: const TextStyle(
              fontSize: 13, color: AppColors.textPrimary, height: 1.5),
          decoration: InputDecoration(
            hintText:
            'Describe your item — how it fits, why you are selling it, any specific measurements or details...',
            hintStyle: const TextStyle(
                fontSize: 13, color: AppColors.textPlaceholder),
            filled: true,
            fillColor: AppColors.surface,
            counterStyle:
            const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            contentPadding: const EdgeInsets.all(14),
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
        ),
      ],
    );
  }

  // ── Step 7: Preview ─────────────────────────────────
  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Text('Here is how your listing will appear to buyers.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 14),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Container(
                  color: AppColors.muted,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _pickedImages.isNotEmpty
                          ? Image.memory(_pickedImages.first, fit: BoxFit.cover)
                          : const Center(
                        child: Icon(Icons.camera_alt_outlined,
                            size: 48, color: AppColors.neutral300),
                      ),
                      if (_form.condition != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: ConditionBadge(grade: _form.condition!),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_form.brand.isEmpty ? 'Brand' : _form.brand} · '
                          '${_form.category.isEmpty ? 'Category' : _form.category}'
                          '${_form.size.isNotEmpty ? ' · ${_form.size}' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _form.brand.isEmpty ? 'Your Item' : '${_form.brand} Item',
                      style: const TextStyle(
                          fontFamily: 'Instrument Serif',
                          fontSize: 18,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _form.price.isEmpty
                          ? 'Rs. —'
                          : 'Rs. ${_formatPrice(int.tryParse(_form.price) ?? 0)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    const TrustScore(score: null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 8: Publish confirm ─────────────────────────
  Widget _buildPublishStep() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
              color: AppColors.successBg, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 30, color: AppColors.successText),
        ),
        const SizedBox(height: 14),
        const Text('Ready to Publish',
            style: TextStyle(
                fontFamily: 'Instrument Serif',
                fontSize: 24,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text(
          'Your listing will go live immediately and be visible to buyers in your city first.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13, color: AppColors.mutedForeground, height: 1.5),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _summaryRow('Category', _form.category.isEmpty ? '—' : _form.category),
              _summaryRow('Condition',
                  _form.condition == null ? '—' : _form.condition!.label),
              _summaryRow('Brand', _form.brand.isEmpty ? '—' : _form.brand),
              _summaryRow('Size', _form.size.isEmpty ? '—' : _form.size),
              _summaryRow(
                  'Price',
                  _form.price.isEmpty
                      ? '—'
                      : 'Rs. ${_formatPrice(int.tryParse(_form.price) ?? 0)}',
                  last: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String k, String v, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
            bottom: BorderSide(color: AppColors.neutral200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          Text(v,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ── CTA bar ──────────────────────────────────────────
  Widget _buildCta() {
    final label = _step == _kTotalSteps
        ? 'Publish Listing'
        : _step == 7
        ? 'Looks Good, Continue'
        : 'Continue';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_canNext && !_publishing) ? _handleNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.38),
            foregroundColor: AppColors.primaryForeground,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _publishing
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ── Published success state ─────────────────────────
  Widget _buildPublishedState() {
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
                const Text('Listing Published!',
                    style: TextStyle(
                        fontFamily: 'Instrument Serif',
                        fontSize: 26,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                const Text(
                  'Your item is now live. Buyers in your city will see it first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.mutedForeground, height: 1.6),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Sell Another Item',
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