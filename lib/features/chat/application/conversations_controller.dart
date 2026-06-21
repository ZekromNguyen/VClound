import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/conversation.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (_) => ChatRepository(),
);

final conversationsProvider =
    StreamProvider.autoDispose<List<ConversationSummary>>((ref) {
  return ref.read(chatRepositoryProvider).watchConversations();
});

class ConversationActions {
  ConversationActions(this._repo);
  final ChatRepository _repo;

  Future<String> openDirect(String otherUserId) => _repo.openDirect(otherUserId);

  Future<String> createGroup(String name, List<String> memberIds) =>
      _repo.createGroup(name, memberIds);
}

final conversationActionsProvider = Provider<ConversationActions>(
  (ref) => ConversationActions(ref.read(chatRepositoryProvider)),
);
