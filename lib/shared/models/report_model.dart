enum ReportReason {
  fakeOrCounterfeit('Fake or counterfeit item'),
  incorrectCondition('Incorrect condition grading'),
  misleadingDescription('Misleading description'),
  inappropriateContent('Inappropriate content'),
  other('Other');

  final String label;
  const ReportReason(this.label);
}

enum ReportTargetType { listing, seller }

class Report {
  final String id;
  final ReportTargetType targetType;
  final String targetId; // listingId or sellerName
  final String targetLabel; // human-readable, for admin list display
  final ReportReason reason;
  final String? note;
  final DateTime reportedAt;

  const Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.reason,
    this.note,
    required this.reportedAt,
  });
}