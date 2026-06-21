import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../shared/models/ticket.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/ticket_controller.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceAsync = ref.watch(ticketsProvider);
    final list = ref.watch(effectiveTicketsProvider);
    return AppScaffold(
      title: 'Tickets',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tickets/new'),
        child: const Icon(Icons.add),
      ),
      body: sourceAsync.when(
        data: (_) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.task_alt_outlined,
              title: 'No tickets yet',
              subtitle:
                  'Create one to track tasks. Tickets are self-assigned in MVP.',
            );
          }
          final byStatus = <TicketStatus, List<Ticket>>{
            for (final s in TicketStatus.values) s: <Ticket>[],
          };
          for (final t in list) {
            byStatus[t.status]!.add(t);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ticketsProvider);
              await ref.read(ticketsProvider.future);
            },
            child: ListView(
              children: [
                for (final s in TicketStatus.values) ...[
                  _SectionHeader(label: s.label, count: byStatus[s]!.length),
                  if (byStatus[s]!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text('Nothing here.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline)),
                    ),
                  for (final t in byStatus[s]!) _tile(context, t),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(ticketsProvider)),
      ),
    );
  }

  Widget _tile(BuildContext context, Ticket t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(t.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(Dates.relativeShort(t.updatedAt)),
        trailing: Chip(
          visualDensity: VisualDensity.compact,
          label: Text(t.status.label, style: const TextStyle(fontSize: 11)),
        ),
        onTap: () => context.push('/tickets/${t.id}'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
