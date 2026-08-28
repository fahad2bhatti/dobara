import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/report_model.dart';

class ReportsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  /// All open reports, newest first — admin only (enforced by
  /// Firestore rules; a non-admin caller gets permission-denied on the
  /// first doc, not a filtered result).
  Stream<List<Report>> watchReports() {
    return _reports
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Report.fromDoc(d)).toList());
  }

  Future<void> submitReport(Report report) {
    return _reports.add(report.toMap());
  }

  /// Removes the report once admin has actioned or dismissed it. There's
  /// no separate "resolved" state to keep — once handled, it's gone from
  /// the queue.
  Future<void> dismissReport(String reportId) {
    return _reports.doc(reportId).delete();
  }
}
