import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/report_model.dart';

/// In-memory reports queue for this session — feeds the Admin
/// Moderation screen (Phase 9).
/// TODO Phase 11 (post-auth Firestore pass): persist to Firestore
/// under reports/{reportId}, tied to the real reporting user id.
class ReportsNotifier extends Notifier<List<Report>> {
  @override
  List<Report> build() => [];

  void addReport(Report report) {
    state = [report, ...state];
  }

  void dismiss(String reportId) {
    state = state.where((r) => r.id != reportId).toList();
  }
}

final reportsProvider = NotifierProvider<ReportsNotifier, List<Report>>(
  ReportsNotifier.new,
);