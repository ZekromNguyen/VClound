import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../shared/models/timesheet.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/timesheet_controller.dart';

class TimesheetListScreen extends ConsumerWidget {
  const TimesheetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(timesheetStreamProvider);
    return AppScaffold(
      title: 'Timesheets',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/timesheet/new'),
        child: const Icon(Icons.add),
      ),
      body: rows.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.timer_outlined,
              title: 'No entries yet',
              subtitle:
                  'Add your first entry to keep track of how your day went.',
            );
          }
          final byDate = <String, List<TimesheetEntry>>{};
          for (final e in list) {
            final key = Dates.isoDate(e.workedDate);
            byDate.putIfAbsent(key, () => <TimesheetEntry>[]).add(e);
          }
          final groups = byDate.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final g in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(g.key,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final e in g.value) _row(context, e),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Total: ${Dates.humanDuration(_groupTotal(g.value))}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(timesheetStreamProvider)),
      ),
    );
  }

  Duration _groupTotal(List<TimesheetEntry> list) {
    var total = Duration.zero;
    for (final e in list) {
      total += e.duration.duration;
    }
    return total;
  }

  Widget _row(BuildContext context, TimesheetEntry e) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Text(e.category.label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              )),
        ),
        title: Text(e.taskName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(Dates.time(e.createdAt)),
        trailing: Text(e.duration.label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
