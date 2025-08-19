import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

class ChatService {
  ChatService._();
  static final instance = ChatService._();

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<(Conversation, List<ChatMessage>)> openConversation({
    required String requestId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat/open');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestId': requestId,
          'currentUserId': currentUserId,
          'otherUserId': otherUserId,
        }));

    print('🔥 [ChatService] openConversation response: ${resp.statusCode}');
    print('🔥 [ChatService] response body: ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception(
          'Failed to open conversation: ${resp.statusCode} - ${resp.body}');
    }

    try {
      final data = jsonDecode(resp.body);
      print('🔥 [ChatService] parsed data: $data');

      final convo = Conversation.fromJson(data['conversation']);
      final messages = (data['messages'] as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      return (convo, messages);
    } catch (e, stack) {
      print('🔥 [ChatService] JSON parsing error: $e');
      print('🔥 [ChatService] Stack trace: $stack');
      rethrow;
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat/messages');

    print('🔥 [ChatService] sendMessage to: $uri');
    print(
        '🔥 [ChatService] payload: conversationId=$conversationId, senderId=$senderId, content="$content"');

    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversationId': conversationId,
          'senderId': senderId,
          'content': content,
        }));

    print('🔥 [ChatService] sendMessage response: ${resp.statusCode}');
    print('🔥 [ChatService] response body: ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception(
          'Failed to send message: ${resp.statusCode} - ${resp.body}');
    }

    try {
      final data = jsonDecode(resp.body);
      return ChatMessage.fromJson(data['message']);
    } catch (e, stack) {
      print('🔥 [ChatService] sendMessage JSON parsing error: $e');
      print('🔥 [ChatService] Stack trace: $stack');
      rethrow;
    }
  }
}
