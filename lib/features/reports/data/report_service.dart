import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/report_reason.dart';

/// Writes report submissions to the `reports` Firestore collection so the
/// Admin/Moderation dashboard (Phase 9) can read them.
///
/// TODO(auth): reportedByUserId is a placeholder until Phase 10. Swap
/// `kDummyUserId` for the real signed-in uid once auth exists — see
/// core/constants/dev_config.dart.
class ReportService {
  ReportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> submitReport({
    required ReportTargetType targetType,
    required String targetId, // listingId or sellerId being reported
    required ReportReason reason,
    String? details,
    required String reportedByUserId, // pass kDummyUserId until auth lands
  }) async {
    await _firestore.collection('reports').add({
      'targetType': targetType.name, // 'listing' | 'seller'
      'targetId': targetId,
      'reasonValue': reason.value,
      'reasonLabel': reason.label,
      'details': details?.trim().isEmpty == true ? null : details?.trim(),
      'reportedByUserId': reportedByUserId,
      'status': 'pending', // pending | reviewed | dismissed | actioned
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}