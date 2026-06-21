/// Row from `public.messages`.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        senderId: map['sender_id'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
