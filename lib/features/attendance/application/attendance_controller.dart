import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/attendance.dart';
import '../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (_) => AttendanceRepository(),
);

final attendanceStreamProvider =
    StreamProvider.autoDispose<List<Attendance>>(
  (ref) => ref.read(attendanceRepositoryProvider).watchRecent(),
);

class AttendanceActions {
  AttendanceActions(this._repo, this._ref);
  final AttendanceRepository _repo;
  final Ref _ref;

  Future<void> checkIn() async {
    await _repo.checkIn();
    _ref.invalidate(attendanceStreamProvider);
  }

  Future<void> checkOut() async {
    await _repo.checkOut();
    _ref.invalidate(attendanceStreamProvider);
  }
}

final attendanceActionsProvider = Provider(
  (ref) => AttendanceActions(ref.read(attendanceRepositoryProvider), ref),
);

/// Derived view: today's open row (if any). Used by the home dashboard
/// status card.
final openSessionProvider = Provider<Attendance?>((ref) {
  final list = ref.watch(attendanceStreamProvider).value ?? const <Attendance>[];
  if (list.isEmpty) return null;
  for (final a in list) {
    if (a.isOpen) return a;
  }
  return null;
});
