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
    if (resp.statusCode != 200) {
      throw Exception('Failed to open conversation');
    }
    final data = jsonDecode(resp.body);
    final convo = Conversation.fromJson(data['conversation']);
    final messages =
        (data['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList();
    return (convo, messages);
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat/messages');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversationId': conversationId,
          'senderId': senderId,
          'content': content,
        }));
    if (resp.statusCode != 200) throw Exception('Failed to send');
    final data = jsonDecode(resp.body);
    return ChatMessage.fromJson(data['message']);
  }
}
