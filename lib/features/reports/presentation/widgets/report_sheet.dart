import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/report_service.dart';
import '../../domain/report_reason.dart';

/// Call this to open the report flow. Handles listing and seller reports
/// with the same UI — only the reason list changes.
///
/// Example:
/// ```dart
/// showReportSheet(
///   context,
///   targetType: ReportTargetType.listing,
///   targetId: product.id,
///   reportedByUserId: kDummyUserId, // swap for real uid post-auth
/// );
/// ```
Future<void> showReportSheet(
    BuildContext context, {
      required ReportTargetType targetType,
      required String targetId,
      required String reportedByUserId,
    }) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReportSheet(
      targetType: targetType,
      targetId: targetId,
      reportedByUserId: reportedByUserId,
    ),
  );
}

class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.reportedByUserId,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String reportedByUserId;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _service = ReportService();
  final _detailsController = TextEditingController();
  ReportReason? _selected;
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    try {
      await _service.submitReport(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selected!,
        details: _detailsController.text,
        reportedByUserId: widget.reportedByUserId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report submitted — our team will review it shortly.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryForeground,
            ),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't submit report. Please try again.",
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.errorText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = ReportReason.forType(widget.targetType);
    final title = widget.targetType == ReportTargetType.listing
        ? 'Report this listing'
        : 'Report this seller';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(title, style: AppTextStyles.displayXSmall),
              const SizedBox(height: 4),
              Text(
                'Help us keep Dobara trustworthy. Your report is anonymous to the other party.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                    (reason) => _ReasonTile(
                  reason: reason,
                  selected: _selected == reason,
                  onTap: () => setState(() => _selected = reason),
                ),
              ),
              const SizedBox(height: 8),
              Text('Additional details (optional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Anything that helps us investigate...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: AppColors.muted,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null || _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.neutral300,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryForeground,
                    ),
                  )
                      : Text('Submit report', style: AppTextStyles.buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: selected
                    ? AppColors.primaryForeground
                    : AppColors.neutral500,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reason.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected
                        ? AppColors.primaryForeground
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}