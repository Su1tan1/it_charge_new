import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:it_charge/config.dart';

/// Настройки уведомлений пользователя
class NotificationPreferences {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool chargingStarted;
  final bool chargingCompleted;
  final bool chargingError;
  final bool lowBalance;

  NotificationPreferences({
    required this.emailNotifications,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.chargingStarted,
    required this.chargingCompleted,
    required this.chargingError,
    required this.lowBalance,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailNotifications: json['emailNotifications'] as bool? ?? false,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? false,
      chargingStarted: json['chargingStarted'] as bool? ?? true,
      chargingCompleted: json['chargingCompleted'] as bool? ?? true,
      chargingError: json['chargingError'] as bool? ?? true,
      lowBalance: json['lowBalance'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'chargingStarted': chargingStarted,
      'chargingCompleted': chargingCompleted,
      'chargingError': chargingError,
      'lowBalance': lowBalance,
    };
  }
}

/// История уведомления
class NotificationHistory {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;

  NotificationHistory({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }
}

/// Сервис для работы с Notifications API
class NotificationsService {
  static String get _baseUrl => Config.notificationsUrl;

  /// Получить настройки уведомлений
  static Future<NotificationPreferences> getPreferences() async {
    final url = '$_baseUrl/preferences';
    final headers = <String, String>{'Content-Type': 'application/json'};

    try {
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      debugPrint('✅ getNotificationPreferences');
      return NotificationPreferences.fromJson(decoded as Map<String, dynamic>);
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ getNotificationPreferences: $errMsg');
      rethrow;
    }
  }

  /// Обновить настройки уведомлений
  static Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final url = '$_baseUrl/preferences';
    final headers = <String, String>{'Content-Type': 'application/json'};

    final body = jsonEncode(preferences.toJson());

    try {
      final res = await http
          .patch(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      debugPrint('✅ updateNotificationPreferences');
      return NotificationPreferences.fromJson(decoded as Map<String, dynamic>);
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ updateNotificationPreferences: $errMsg');
      rethrow;
    }
  }

  /// Получить историю уведомлений
  static Future<List<NotificationHistory>> getHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final url = '$_baseUrl/history?limit=$limit&offset=$offset';
    final headers = <String, String>{'Content-Type': 'application/json'};

    try {
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      List<NotificationHistory> notifications = [];

      if (decoded is List) {
        notifications = decoded
            .map((e) => NotificationHistory.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (decoded is Map) {
        final list =
            decoded['data'] ?? decoded['notifications'] ?? decoded['items'];
        if (list is List) {
          notifications = list
              .map(
                (e) => NotificationHistory.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
      }

      debugPrint(
        '✅ getNotificationHistory: ${notifications.length} уведомлений',
      );
      return notifications;
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ getNotificationHistory: $errMsg');
      rethrow;
    }
  }
}
