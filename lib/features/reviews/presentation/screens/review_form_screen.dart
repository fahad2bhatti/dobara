import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/review_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../listings/domain/listings_provider.dart';
import '../../data/reviews_providers.dart';

/// Shared by "Write a Review" and "Edit Your Review" — pre-fills from
/// [existing] when the signed-in user already reviewed this listing.
class ReviewFormScreen extends ConsumerStatefulWidget {
  final String listingId;
  final Review? existing;

  const ReviewFormScreen({super.key, required this.listingId, this.existing});

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  late int _rating;
  late final TextEditingController _commentController;
  late List<String> _existingPhotoUrls;
  final List<Uint8List> _newPhotos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 5;
    _commentController = TextEditingController(text: widget.existing?.comment ?? '');
    _existingPhotoUrls = List<String>.from(widget.existing?.photoUrls ?? const []);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int get _totalPhotoCount => _existingPhotoUrls.length + _newPhotos.length;

  Future<void> _pickPhoto() async {
    if (_totalPhotoCount >= 5) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _newPhotos.add(bytes));
    }
  }

  Future<void> _submit() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a few words about the item.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var photoUrls = _existingPhotoUrls;
      if (_newPhotos.isNotEmpty) {
        final uploaded = await ref.read(storageServiceProvider).uploadImages(
          folder: 'dobara/reviews/${widget.listingId}',
          images: _newPhotos,
        );
        photoUrls = [..._existingPhotoUrls, ...uploaded];
      }

      final user = ref.read(currentUserProvider);
      final profile = ref.read(userProfileProvider).asData?.value;
      final name = profile?.name ?? user?.email?.split('@').first ?? 'Dobara user';

      await ref.read(reviewsActionsProvider.notifier).submit(
        widget.listingId,
        Review(
          id: user?.uid ?? '',
          userId: user?.uid ?? '',
          listingId: widget.listingId,
          userName: name,
          rating: _rating,
          comment: _commentController.text.trim(),
          photoUrls: photoUrls,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existing != null
            ? 'Review updated.'
            : 'Thanks for your review!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(widget.existing != null ? 'Edit Your Review' : 'Write a Review')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('YOUR RATING',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 34,
                        color: filled ? const Color(0xFFF5A623) : AppColors.neutral300,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              const Text('YOUR REVIEW',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'How was the quality, fit, and condition?',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textPlaceholder),
                  filled: true,
                  fillColor: AppColors.surface,
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
              const SizedBox(height: 20),

              const Text('PHOTOS (OPTIONAL)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  ...List.generate(_existingPhotoUrls.length, (i) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                              imageUrl: _existingPhotoUrls[i], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _existingPhotoUrls.removeAt(i)),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 11, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  ...List.generate(_newPhotos.length, (i) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_newPhotos[i], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _newPhotos.removeAt(i)),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 11, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_totalPhotoCount < 5)
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4EF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accent, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 18, color: AppColors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(widget.existing != null ? 'Update Review' : 'Submit Review',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
