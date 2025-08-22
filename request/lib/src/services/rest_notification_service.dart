import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'api_client.dart';

class RestNotificationService {
  RestNotificationService._();
  static RestNotificationService? _inst;
  static RestNotificationService get instance =>
      _inst ??= RestNotificationService._();

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<List<NotificationModel>> fetchMyNotifications() async {
    final token = await ApiClient.instance.getToken();
    final resp =
        await http.get(Uri.parse('$_baseUrl/api/notifications'), headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (resp.statusCode != 200) return [];
    final list = (jsonDecode(resp.body)['data'] as List?) ?? [];
    return list.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> markAllRead() async {
    final token = await ApiClient.instance.getToken();
    await http
        .post(Uri.parse('$_baseUrl/api/notifications/mark-all-read'), headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<void> markRead(String id) async {
    final token = await ApiClient.instance.getToken();
    await http
        .post(Uri.parse('$_baseUrl/api/notifications/$id/read'), headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<void> delete(String id) async {
    final token = await ApiClient.instance.getToken();
    await http.delete(Uri.parse('$_baseUrl/api/notifications/$id'), headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  NotificationModel _fromJson(Map<String, dynamic> j) {
    final typeStr = (j['type'] as String?) ?? 'systemMessage';
    final statusStr = (j['status'] as String?) ?? 'unread';
    return NotificationModel(
      id: j['id'].toString(),
      recipientId: j['recipient_id']?.toString() ?? '',
      senderId: j['sender_id']?.toString() ?? '',
      senderName: null,
      type: NotificationType.values.firstWhere(
        (t) => t.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => NotificationType.systemMessage,
      ),
      title: j['title']?.toString() ?? '',
      message: j['message']?.toString() ?? '',
      data: (j['data'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ??
          <String, dynamic>{},
      status: NotificationStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      readAt: j['read_at'] != null
          ? DateTime.tryParse(j['read_at'].toString())
          : null,
    );
  }
}
