import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../shared/models/timesheet.dart';

class TimesheetRepository {
  TimesheetRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<List<TimesheetEntry>> watchRecent({int limit = 100}) {
    final controller = StreamController<List<TimesheetEntry>>();
    RealtimeChannel? ch;

    Future<void> refresh() async {
      try {
        final me = _client.auth.currentUser?.id;
        if (me == null) {
          controller.add(const <TimesheetEntry>[]);
          return;
        }
        final res = await _client
            .from('timesheets')
            .select('*')
            .eq('user_id', me)
            .order('worked_date', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit);
        final list = (res as List)
            .cast<Map<String, dynamic>>()
            .map(TimesheetEntry.fromMap)
            .toList();
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(Failure('Reload failed: $e'));
        }
      }
    }

    controller.onListen = () async {
      await refresh();
      ch = _client
          .channel('ts-${_client.auth.currentUser?.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'timesheets',
            callback: (_) => refresh(),
          )
          .subscribe();
    };
    controller.onCancel = () async {
      final c = ch;
      if (c != null) await _client.removeChannel(c);
    };
    return controller.stream;
  }

  Future<TimesheetEntry> add({
    required String taskName,
    required TimesheetCategory category,
    required TimesheetDuration duration,
    DateTime? workedDate,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw Failure('Not signed in');
    final res = await _client.from('timesheets').insert({
      'user_id': me,
      'task_name': taskName,
      'category': category.dbValue,
      'duration': duration.dbValue,
      if (workedDate != null) 'worked_date': workedDate.toIso8601String().split('T').first,
    }).select().single();
    return TimesheetEntry.fromMap(Map<String, dynamic>.from(res));
  }
}
