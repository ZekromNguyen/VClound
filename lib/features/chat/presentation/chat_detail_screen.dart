import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/conversations_controller.dart';
import '../application/messages_controller.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  String _title = 'Chat';

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(sendMessageActionProvider)
          .send(widget.conversationId, text);
      _input.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = currentUserId();
    final msgs = ref.watch(messagesProvider(widget.conversationId));

    // Resolve the display title. Cheap and idempotent.
    final conversations = ref.watch(conversationsProvider);
    String? resolvedTitle;
    conversations.whenData((list) {
      for (final c in list) {
        if (c.id == widget.conversationId) {
          resolvedTitle = c.title;
          break;
        }
      }
    });
    if (resolvedTitle != null && resolvedTitle != _title) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _title = resolvedTitle!));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: msgs.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Say hi 👋',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  }
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final mine = m.senderId == myId;
                      return _Bubble(message: m, mine: mine);
                    },
                  );
                },
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(messagesProvider(widget.conversationId)),
                ),
              ),
            ),
            _Composer(
              controller: _input,
              sending: _sending,
              onSubmit: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final dynamic message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final align = mine ? Alignment.centerRight : Alignment.centerLeft;
    final bg = mine ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = mine ? scheme.onPrimary : scheme.onSurface;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.content as String,
                style: TextStyle(color: fg, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              Dates.time(message.createdAt),
              style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                enabled: !sending,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: sending ? null : onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
