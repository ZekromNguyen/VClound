import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/timesheet.dart';
import '../data/timesheet_repository.dart';

final timesheetRepositoryProvider = Provider<TimesheetRepository>(
  (_) => TimesheetRepository(),
);

final timesheetStreamProvider =
    StreamProvider.autoDispose<List<TimesheetEntry>>(
  (ref) => ref.read(timesheetRepositoryProvider).watchRecent(),
);

/// Sum of today's durations. Used by the home dashboard.
final todayTotalMinutesProvider = Provider<int>((ref) {
  final list = ref.watch(timesheetStreamProvider).value ?? const <TimesheetEntry>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var total = 0;
  for (final e in list) {
    final wd = DateTime(e.workedDate.year, e.workedDate.month, e.workedDate.day);
    if (wd == today) total += e.duration.duration.inMinutes;
  }
  return total;
});

class TimesheetActions {
  TimesheetActions(this._repo, this._ref);
  final TimesheetRepository _repo;
  final Ref _ref;

  Future<void> add({
    required String taskName,
    required TimesheetCategory category,
    required TimesheetDuration duration,
  }) async {
    await _repo.add(taskName: taskName, category: category, duration: duration);
    _ref.invalidate(timesheetStreamProvider);
  }
}

final timesheetActionsProvider = Provider(
  (ref) => TimesheetActions(ref.read(timesheetRepositoryProvider), ref),
);
