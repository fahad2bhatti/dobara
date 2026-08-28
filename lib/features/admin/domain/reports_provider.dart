import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/report_model.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider =
Provider<ReportsRepository>((ref) => ReportsRepository());

/// All open reports, across every buyer — admin moderation queue.
final reportsStreamProvider = StreamProvider<List<Report>>((ref) {
  return ref.watch(reportsRepositoryProvider).watchReports();
});

class ReportsActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> submit(Report report) {
    return ref.read(reportsRepositoryProvider).submitReport(report);
  }

  Future<void> dismiss(String reportId) {
    return ref.read(reportsRepositoryProvider).dismissReport(reportId);
  }
}

final reportsActionsProvider =
NotifierProvider<ReportsActions, void>(ReportsActions.new);
