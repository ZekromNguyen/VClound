import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../shared/models/ticket.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/ticket_controller.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});
  final String ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  Ticket? _ticket;
  Object? _error;
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _myId = currentUserId();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(ticketRepositoryProvider);
      final t = await repo.one(widget.ticketId);
      if (mounted) setState(() => _ticket = t);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _changeStatus(TicketStatus s) async {
    final id = _ticket?.id;
    if (id == null) return;
    setState(() => _ticket = _ticket!.copyWith(status: s));
    try {
      await ref.read(ticketActionsProvider).updateStatus(id, s);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
      _load();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete ticket?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(ticketActionsProvider).delete(widget.ticketId);
      if (mounted) context.go('/tickets');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: ErrorView(error: _error!));
    }
    if (_ticket == null) {
      return const Scaffold(body: LoadingView());
    }
    final t = _ticket!;
    final canDelete = t.createdBy == _myId;

    return AppScaffold(
      title: 'Ticket',
      actions: [
        if (canDelete)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 4),
          Text('Created ${Dates.relativeShort(t.createdAt)} · '
              'Updated ${Dates.relativeShort(t.updatedAt)}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12)),
          if (t.description != null && t.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t.description!),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<TicketStatus>(
            segments: [
              for (final s in TicketStatus.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {t.status},
            onSelectionChanged: (set) =>
                set.isNotEmpty ? _changeStatus(set.first) : null,
          ),
        ],
      ),
    );
  }
}
