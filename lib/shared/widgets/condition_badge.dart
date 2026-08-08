import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../models/product_model.dart';

enum ConditionBadgeSize { sm, md }

/// Pill badge showing a product's condition grade with a colored dot.
/// Colors come from [AppColors.conditionColors] — never hardcode per-badge.
class ConditionBadge extends StatelessWidget {
  final ConditionGrade grade;
  final ConditionBadgeSize size;

  const ConditionBadge({
    super.key,
    required this.grade,
    this.size = ConditionBadgeSize.sm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.conditionColors[grade.label]!;
    final isMd = size == ConditionBadgeSize.md;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMd ? 10 : 7,
        vertical: isMd ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            grade.label,
            style: TextStyle(
              fontSize: isMd ? 11 : 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}
