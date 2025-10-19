import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:it_charge/models/station_model.dart';
import 'package:it_charge/config.dart';
import 'package:it_charge/models/transaction_model.dart';

class OcppService {
  static String get _baseUrl => Config.baseUrl;
  static String get _apiKey => Config.apiKey;

  // Получение станций
  static Future<List<Station>> fetchStations() async {
    final endpoints = [
      '/api/stations',
      '/stations',
      '/api/v1/stations',
      '/api/stations/list',
    ];
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    List<String> errors = [];
    for (final path in endpoints) {
      final uri = Uri.parse('$_baseUrl$path');
      debugPrint('Fetching stations from: ${uri.toString()}');
      try {
        final res = await _withRetry(
          () => http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10)),
        );
        debugPrint('FetchStations Response ($path): ${res.body}');
        if (res.statusCode != 200) {
          errors.add('[$path] HTTP ${res.statusCode}');
          continue;
        }
        final decoded = jsonDecode(res.body);
        // если это массив
        if (decoded is List) {
          return decoded
              .map((s) => Station.fromJson(s as Map<String, dynamic>))
              .toList();
        }
        // если это объект { success: true, data: [...] }
        if (decoded is Map && decoded['data'] is List) {
          if (decoded['success'] == false) {
            // сервер явно отвечает что endpoint отсутствует или требует WS
            final info = decoded['info']?.toString() ?? '';
            if (info.toLowerCase().contains('websocket') ||
                info.toLowerCase().contains('ocpp')) {
              throw Exception('Server indicates OCPP WebSocket only: $info');
            }
          }
          return (decoded['data'] as List)
              .map((s) => Station.fromJson(s as Map<String, dynamic>))
              .toList();
        }
        errors.add('[$path] Unexpected response shape');
      } catch (e) {
        // если ошибка явно говорит про WebSocket — пробрасываем её вверх с полезным сообщением
        final msg = e.toString();
        if (msg.toLowerCase().contains('websocket') ||
            msg.toLowerCase().contains('ocpp')) {
          throw Exception(
            'Server indicates only OCPP WebSocket is available: $msg',
          );
        }
        errors.add('[$path] $e');
      }
    }
    throw Exception('All endpoints failed: ${errors.join('; ')}');
  }

  // GET /api/transactions?chargePointId=...
  static Future<List<Transaction>> getTransactionsForStation(
    String chargePointId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/transactions?chargePointId=${Uri.encodeComponent(chargePointId)}',
    );
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final res = await _withRetry(
      () =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    if (decoded is List)
      return decoded
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    if (decoded is Map && decoded['data'] is List)
      return (decoded['data'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    throw Exception('Unexpected response: ${res.body}');
  }

  // POST /api/transactions/clear
  static Future<Map<String, dynamic>> clearTransactions(int days) async {
    final uri = Uri.parse('$_baseUrl/api/transactions/clear');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final body = jsonEncode({'days': days});
    final res = await _withRetry(
      () => http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // GET /api/user/stations
  static Future<List<Map<String, dynamic>>> getUserStations() async {
    final uri = Uri.parse('$_baseUrl/api/user/stations');
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final res = await _withRetry(
      () =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    if (decoded is Map && decoded['data'] is List)
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    throw Exception('Unexpected response: ${res.body}');
  }

  // GET /api/user/connector-status/{connectorId}
  static Future<Map<String, dynamic>> getConnectorStatus(
    int connectorId,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/user/connector-status/$connectorId');
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final res = await _withRetry(
      () =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // POST /api/user/start-charging
  static Future<String?> userStartCharging(
    String stationId,
    int connectorId,
    String userId, {
    String? authToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/user/start-charging');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    if (authToken != null) headers['X-Auth-Token'] = authToken;
    final body = jsonEncode({
      'stationId': stationId,
      'connectorId': connectorId,
      'userId': userId,
      'authToken': authToken,
    });
    final res = await _withRetry(
      () => http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['transactionId'] != null)
      return decoded['transactionId'].toString();
    return null;
  }

  // POST /api/user/stop-charging
  static Future<Map<String, dynamic>> userStopCharging(
    String transactionId,
    String userId,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/user/stop-charging');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final body = jsonEncode({'transactionId': transactionId, 'userId': userId});
    final res = await _withRetry(
      () => http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // GET /api/user/my-sessions
  static Future<List<Transaction>> getMySessions() async {
    final uri = Uri.parse('$_baseUrl/api/user/my-sessions');
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final res = await _withRetry(
      () =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    if (decoded is List)
      return decoded
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    if (decoded is Map && decoded['data'] is List)
      return (decoded['data'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    throw Exception('Unexpected response: ${res.body}');
  }

  // GET /api/status/{id}
  static Future<Map<String, dynamic>> getStatusById(String id) async {
    final uri = Uri.parse('$_baseUrl/api/status/$id');
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final res = await _withRetry(
      () =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Запуск зарядки
  static Future<String?> remoteStart(
    String chargePointId,
    int connectorId,
    String idTag,
  ) async {
    // map to new admin/user endpoints if available
    final uri = Uri.parse('$_baseUrl/api/admin/remote-start-session');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final body = jsonEncode({
      'stationId': chargePointId,
      'connectorId': connectorId,
      'userId': idTag,
    });

    try {
      final res = await _withRetry(
        () => http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 10)),
      );
      debugPrint('RemoteStart Response: ${res.body}');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final tx =
              decoded['transactionId'] ??
              decoded['transaction_id'] ??
              decoded['data']?['transactionId'];
          if (tx != null) return tx.toString();
          if (decoded['success'] == true) return null; // success without tx
          throw Exception('Start failed: ${res.body}');
        }
        throw Exception('Start failed: ${res.body}');
      }
      throw Exception('HTTP error: ${res.statusCode} - ${res.body}');
    } catch (e) {
      throw Exception('Start error: $e');
    }
  }

  // Остановка зарядки
  static Future<bool> remoteStop(
    String chargePointId,
    int connectorId,
    String? transactionId,
  ) async {
    if (transactionId == null) throw Exception('No transaction ID');
    final uri = Uri.parse('$_baseUrl/api/admin/remote-stop-session');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final body = jsonEncode({
      'stationId': chargePointId,
      'transactionId': transactionId,
    });

    try {
      final res = await _withRetry(
        () => http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 10)),
      );
      debugPrint('RemoteStop Response: ${res.body}');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          if (decoded['success'] == true || decoded['ok'] == true) return true;
        }
        // если server вернул простой текст или пустой объект, считаем OK
        return true;
      }
      throw Exception('HTTP error: ${res.statusCode} - ${res.body}');
    } catch (e) {
      throw Exception('Stop error: $e');
    }
  }

  // Простая обёртка retry с экспоненциальным бэкоффом
  static Future<http.Response> _withRetry(
    Future<http.Response> Function() fn,
  ) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final res = await fn();
        return res;
      } catch (e) {
        if (attempts >= Config.maxRetries) rethrow;
        final delayMs = Config.retryBaseDelayMs * (1 << (attempts - 1));
        debugPrint(
          'Request failed (attempt $attempts), retrying in ${delayMs}ms: $e',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
}
