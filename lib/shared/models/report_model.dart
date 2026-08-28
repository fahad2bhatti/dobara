import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  fakeOrCounterfeit('Fake or counterfeit item'),
  incorrectCondition('Incorrect condition grading'),
  misleadingDescription('Misleading description'),
  inappropriateContent('Inappropriate content'),
  other('Other');

  final String label;
  const ReportReason(this.label);

  static ReportReason fromValue(String value) {
    return ReportReason.values.firstWhere(
          (r) => r.name == value,
      orElse: () => ReportReason.other,
    );
  }
}

enum ReportTargetType {
  listing,
  seller;

  static ReportTargetType fromValue(String value) {
    return ReportTargetType.values.firstWhere(
          (t) => t.name == value,
      orElse: () => ReportTargetType.listing,
    );
  }
}

/// Stored at reports/{reportId}. reporterId is kept so admin can see who
/// filed a report (never shown to other buyers), and so future abuse
/// checks (e.g. rate-limiting repeat reporters) have something to key off.
class Report {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId; // listingId or sellerName
  final String targetLabel; // human-readable, for admin list display
  final ReportReason reason;
  final String? note;
  final DateTime reportedAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.reason,
    this.note,
    required this.reportedAt,
  });

  Map<String, dynamic> toMap() => {
    'reporterId': reporterId,
    'targetType': targetType.name,
    'targetId': targetId,
    'targetLabel': targetLabel,
    'reason': reason.name,
    'note': note,
    'reportedAt': FieldValue.serverTimestamp(),
  };

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Report(
      id: doc.id,
      reporterId: map['reporterId'] ?? '',
      targetType: ReportTargetType.fromValue(map['targetType'] ?? 'listing'),
      targetId: map['targetId'] ?? '',
      targetLabel: map['targetLabel'] ?? '',
      reason: ReportReason.fromValue(map['reason'] ?? 'other'),
      note: map['note'],
      reportedAt: (map['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}