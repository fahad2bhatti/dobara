/// Reasons a user can select when reporting a listing or a seller.
///
/// `label` is what's shown in the UI. `value` is the stable string stored
/// in Firestore so copy can change later without breaking old reports.
enum ReportTargetType { listing, seller }

class ReportReason {
  final String value;
  final String label;

  const ReportReason._(this.value, this.label);

  static const fakeOrCounterfeit =
  ReportReason._('fake_counterfeit', 'Fake / counterfeit item');
  static const incorrectCondition =
  ReportReason._('incorrect_condition', 'Incorrect condition');
  static const misleadingDescription =
  ReportReason._('misleading_description', 'Misleading description');
  static const inappropriateContent =
  ReportReason._('inappropriate_content', 'Inappropriate content');

  // Seller-specific reasons (not in the original listing report spec —
  // added since "Report Seller" needs its own reason set; adjust freely).
  static const fraudulentBehavior =
  ReportReason._('fraudulent_behavior', 'Fraudulent behavior');
  static const nonDelivery =
  ReportReason._('non_delivery', 'Item never delivered');
  static const harassment =
  ReportReason._('harassment', 'Harassment or abuse');

  static const other = ReportReason._('other', 'Other');

  static List<ReportReason> forType(ReportTargetType type) {
    switch (type) {
      case ReportTargetType.listing:
        return [
          fakeOrCounterfeit,
          incorrectCondition,
          misleadingDescription,
          inappropriateContent,
          other,
        ];
      case ReportTargetType.seller:
        return [
          fraudulentBehavior,
          nonDelivery,
          harassment,
          inappropriateContent,
          other,
        ];
    }
  }
}