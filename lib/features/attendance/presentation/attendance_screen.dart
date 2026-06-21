import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../shared/models/attendance.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/attendance_controller.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _handle(bool checkIn) async {
    setState(() => _busy = true);
    try {
      if (checkIn) {
        await ref.read(attendanceActionsProvider).checkIn();
      } else {
        await ref.read(attendanceActionsProvider).checkOut();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Failure(', '').replaceFirst(')', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(attendanceStreamProvider);
    Attendance? open;
    Attendance? todayLatest;
    final today = DateTime(_now.year, _now.month, _now.day);

    rows.whenData((list) {
      for (final a in list) {
        final created = DateTime(
            a.createdAt.toLocal().year,
            a.createdAt.toLocal().month,
            a.createdAt.toLocal().day);
        if (created == today) {
          todayLatest ??= a;
        }
        if (a.isOpen) open ??= a;
      }
    });

    final canCheckIn = open == null;
    final canCheckOut = open != null;

    return AppScaffold(
      title: 'Attendance',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(Dates.date(_now),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(Dates.hms(
                      _now.difference(DateTime(_now.year, _now.month, _now.day))),
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontFeatures: const [])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.flag),
            onPressed: canCheckIn && !_busy ? () => _handle(true) : null,
            label: const Text('Check In'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.outbond),
            onPressed: canCheckOut && !_busy ? () => _handle(false) : null,
            label: const Text('Check Out'),
          ),
          const SizedBox(height: 24),
          if (open != null) _openRow(open!),
          if (todayLatest != null) _todaySummary(todayLatest!),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/attendance/history'),
            label: const Text('View history'),
          ),
        ],
      ),
    );
  }

  Widget _openRow(Attendance open) {
    final elapsed = open.elapsed ?? Duration.zero;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: const Text('Currently checked in'),
        subtitle: Text(
            'Started ${Dates.time(open.checkinTime!)} · ${Dates.humanDuration(elapsed)}'),
      ),
    );
  }

  Widget _todaySummary(Attendance latest) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.today_outlined),
        title: Text('Last action today: ${Dates.time(latest.createdAt)}'),
        subtitle: Text(
          latest.checkoutTime != null
              ? 'Checked out at ${Dates.time(latest.checkoutTime!)}'
              : (latest.checkinTime != null
                  ? 'Checked in at ${Dates.time(latest.checkinTime!)}'
                  : ''),
        ),
      ),
    );
  }
}
