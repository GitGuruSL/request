class Conversation {
  final String id;
  final String requestId;
  final String participantA;
  final String participantB;
  final String? lastMessageText;
  final DateTime lastMessageAt;
  final String? requestTitle;

  Conversation({
    required this.id,
    required this.requestId,
    required this.participantA,
    required this.participantB,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.requestTitle,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'],
        requestId: j['request_id'],
        participantA: j['participant_a'],
        participantB: j['participant_b'],
        lastMessageText: j['last_message_text'],
        lastMessageAt: DateTime.parse(j['last_message_at']),
        requestTitle: j['requestTitle'] ?? j['request_title'],
      );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        conversationId: j['conversation_id'],
        senderId: j['sender_id'],
        content: j['content'],
        createdAt: DateTime.parse(j['created_at']),
      );
}
