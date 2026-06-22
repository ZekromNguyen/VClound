import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/home_summary_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);

    return AppScaffold(
      title: 'VCloud',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Today'),
          _Grid(
            children: [
              _AttendanceCard(
                isCheckedIn: summary?.isCheckedIn ?? false,
                elapsedLabel: summary == null
                    ? '—'
                    : Dates.humanDuration(summary.openAttendanceElapsed),
                lastCheckout: summary?.lastCheckout,
                onTap: () => context.go('/attendance'),
              ),
              _HoursCard(
                minutes: summary?.todayMinutes ?? 0,
                onTap: () => context.go('/timesheet'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle('Engagement'),
          _Grid(
            children: [
              _TicketsCard(
                open: summary?.openTickets ?? 0,
                onTap: () => context.go('/tickets'),
              ),
              _ChatCard(
                count: summary?.recentConversationCount ?? 0,
                onTap: () => context.go('/chat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final wide = c.maxWidth > 360;
      if (wide) {
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      }
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.isCheckedIn,
    required this.elapsedLabel,
    required this.lastCheckout,
    required this.onTap,
  });
  final bool isCheckedIn;
  final String elapsedLabel;
  final DateTime? lastCheckout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text('Check-in',
                style: TextStyle(
                    color: scheme.outline, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isCheckedIn
              ? 'Active · $elapsedLabel'
              : (lastCheckout != null
                  ? 'Out at ${Dates.time(lastCheckout!)}'
                  : 'Not checked in'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: body),
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.minutes, required this.onTap});
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text("Today's hours",
                      style: TextStyle(
                          color: scheme.outline,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                Dates.humanDuration(Duration(minutes: minutes)),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketsCard extends StatelessWidget {
  const _TicketsCard({required this.open, required this.onTap});
  final int open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.task_alt_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Open tickets',
                      style: TextStyle(
                          color: scheme.outline,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text('$open',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Conversations',
                      style: TextStyle(
                          color: scheme.outline,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text('$count',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
