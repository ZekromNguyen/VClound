import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/conversations_controller.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convs = ref.watch(conversationsProvider);
    return AppScaffold(
      title: 'Chats',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat/new'),
        child: const Icon(Icons.chat),
      ),
      body: convs.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No conversations yet',
              subtitle:
                  'Tap the chat button to start a direct message or a group.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
              await ref.read(conversationsProvider.future);
            },
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _ConversationTile(item: list[i]),
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = item.lastMessage?.content as String? ?? 'No messages yet';
    return ListTile(
      leading: UserAvatar(
        userId: item.id,
        displayName: item.title,
      ),
      title: Text(item.title,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(preview,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.outline)),
      trailing: Text(
        Dates.chatListLabel(item.updatedAt),
        style: TextStyle(color: scheme.outline, fontSize: 12),
      ),
      onTap: () => context.push('/chat/${item.id}'),
    );
  }
}
