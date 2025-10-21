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
      '/api/user/stations',
      '/user/stations',
      '/api/v1/stations',
      '/api/stations/list',
      '/api/stations',
    ];
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    List<String> errors = [];
    for (final path in endpoints) {
      final uri = Uri.parse('$_baseUrl$path');
      debugPrint('Извлечение станций из: ${uri.toString()}');
      try {
        final res = await _withRetry(
          () => http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10)),
        );
        debugPrint('Ответ FetchStations ($path): ${res.body}');
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
              throw Exception('Сервер показывает только OCPP WebSocket: $info');
            }
          }
          return (decoded['data'] as List)
              .map((s) => Station.fromJson(s as Map<String, dynamic>))
              .toList();
        }
        errors.add('[$path] Неожиданная форма ответа');
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
  // static Future<List<Transaction>> getTransactionsForStation(
  //   String chargePointId,
  // ) async {
  //   final uri = Uri.parse(
  //     '$_baseUrl/api/transactions?chargePointId=${Uri.encodeComponent(chargePointId)}',
  //   );
  //   final headers = <String, String>{'Accept': 'application/json'};
  //   if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
  //   final res = await _withRetry(
  //     () =>
  //         http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
  //   );
  //   if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  //   final decoded = jsonDecode(res.body);
  //   if (decoded is List) {
  //     return decoded
  //         .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
  //         .toList();
  //   }
  //   if (decoded is Map && decoded['data'] is List) {
  //     return (decoded['data'] as List)
  //         .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
  //         .toList();
  //   }
  //   throw Exception('Unexpected response: ${res.body}');
  // }

  static Future<List<Transaction>> getTransactionsForStation(
    String chargePointId,
  ) async {
    final candidates = [
      '/api/transactions?chargePointId=${Uri.encodeComponent(chargePointId)}',
      '/api/transactions?stationId=${Uri.encodeComponent(chargePointId)}',
      '/api/user/transactions?stationId=${Uri.encodeComponent(chargePointId)}',
      '/api/user/my-sessions?stationId=${Uri.encodeComponent(chargePointId)}',
      '/api/user/sessions?stationId=${Uri.encodeComponent(chargePointId)}',
    ];

    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    List<String> errors = [];
    for (final p in candidates) {
      final uri = Uri.parse('$_baseUrl$p');
      debugPrint('Fetching transactions for station from: ${uri.toString()}');
      try {
        final res = await _withRetry(
          () => http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10)),
        );
        debugPrint('getTransactionsForStation (${p}): HTTP ${res.statusCode}');
        if (res.statusCode != 200) {
          errors.add('[$p] HTTP ${res.statusCode}');
          continue;
        }
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // sometimes server wraps in { transactions: [...] }
        if (decoded is Map) {
          final list =
              decoded['transactions'] ??
              decoded['items'] ??
              decoded['sessions'];
          if (list is List) {
            return list
                .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
        errors.add('[$p] Unexpected body');
      } catch (e) {
        final msg = e.toString();
        if (msg.toLowerCase().contains('websocket') ||
            msg.toLowerCase().contains('ocpp')) {
          throw Exception(
            'Server indicates only OCPP WebSocket is available: $msg',
          );
        }
        errors.add('[$p] $e');
      }
    }
    throw Exception('All endpoints failed: ${errors.join('; ')}');
  }

  // POST /api/transactions/clear
  // static Future<Map<String, dynamic>> clearTransactions(int days) async {
  //   final uri = Uri.parse('$_baseUrl/api/transactions/clear');
  //   final headers = <String, String>{'Content-Type': 'application/json'};
  //   if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
  //   final body = jsonEncode({'days': days});
  //   // debugPrint('Clearing transactions older than $days days');
  //   final res = await _withRetry(
  //     () => http
  //         .post(uri, headers: headers, body: body)
  //         .timeout(const Duration(seconds: 10)),
  //   );
  //   if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  //   return jsonDecode(res.body) as Map<String, dynamic>;
  // }

  // GET /api/user/stations
  // static Future<List<Map<String, dynamic>>> getUserStations() async {
  //   final uri = Uri.parse('$_baseUrl/api/user/stations');
  //   debugPrint(uri.toString());
  //   final headers = <String, String>{'Accept': 'application/json'};
  //   if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
  //   final res = await _withRetry(
  //     () =>
  //         http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
  //   );
  //   if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  //   final decoded = jsonDecode(res.body);
  //   if (decoded is List) return decoded.cast<Map<String, dynamic>>();
  //   if (decoded is Map && decoded['data'] is List) {
  //     return (decoded['data'] as List).cast<Map<String, dynamic>>();
  //   }
  //   throw Exception('Unexpected response: ${res.body}');
  // }

  // GET /api/user/connector-status/{stationId}/{connectorId}
  static Future<Map<String, dynamic>> getConnectorStatus(
    String stationId,
    int connectorId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/user/connector-status/${Uri.encodeComponent(stationId)}/$connectorId',
    );
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final res = await _withRetry(
      () =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // POST start/stop handlers
  static Future<Map<String, dynamic>> userStartCharging(
    String stationId,
    int connectorId,
    String idTag, {
    String? authToken,
    int? startValue,
  }) async {
    // try several possible endpoints (some backends use different paths)
    final candidates = ['/api/admin/remote-start-session'];

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    if (authToken != null) headers['X-Auth-Token'] = authToken;

    final bodyMap = <String, dynamic>{
      'chargePointId': stationId,
      'connectorId': connectorId,
      'idTag': idTag,
    };
    if (startValue != null) bodyMap['startValue'] = startValue;
    final body = jsonEncode(bodyMap);

    List<String> errors = [];
    for (final p in candidates) {
      final uri = Uri.parse('$_baseUrl$p');
      debugPrint('POST start -> $uri');
      debugPrint('Body: $body');
      try {
        final res = await _withRetry(
          () => http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10)),
        );
        debugPrint('start response (${p}): HTTP ${res.statusCode}');
        debugPrint('body: ${res.body}');
        if (res.statusCode != 200 && res.statusCode != 201) {
          errors.add('[$p] HTTP ${res.statusCode}');
          continue;
        }
        final decoded = jsonDecode(res.body);
        if (decoded is Map) return decoded as Map<String, dynamic>;
        errors.add('[$p] Unexpected body');
      } catch (e) {
        errors.add('[$p] $e');
      }
    }
    throw Exception('Start failed. Tried endpoints: ${errors.join('; ')}');
  }

  static Future<Map<String, dynamic>> userStopCharging(
    String transactionId, {
    String? chargePointId,
    int? connectorId,
  }) async {
    final candidates = [
      '/api/transactions/stop',
      '/api/stations/stop',
      '/api/stations/${Uri.encodeComponent(transactionId)}/stop',
      '/api/user/stop',
      '/api/user/transactions/stop',
      '/api/admin/remote-stop-session',
    ];

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    List<String> errors = [];
    for (final p in candidates) {
      final uri = Uri.parse('$_baseUrl$p');
      final bodyMap = <String, dynamic>{'transactionId': transactionId};
      if (chargePointId != null) bodyMap['chargePointId'] = chargePointId;
      if (connectorId != null) bodyMap['connectorId'] = connectorId;
      final body = jsonEncode(bodyMap);
      debugPrint('POST stop -> $uri');
      debugPrint('Body: $body');
      try {
        final res = await _withRetry(
          () => http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10)),
        );
        debugPrint('stop response (${p}): HTTP ${res.statusCode}');
        debugPrint('body: ${res.body}');
        if (res.statusCode != 200 && res.statusCode != 201) {
          errors.add('[$p] HTTP ${res.statusCode}');
          continue;
        }
        final decoded = jsonDecode(res.body);
        if (decoded is Map) return decoded as Map<String, dynamic>;
        errors.add('[$p] Unexpected body');
      } catch (e) {
        errors.add('[$p] $e');
      }
    }
    throw Exception('Stop failed. Tried endpoints: ${errors.join('; ')}');
  }

  // GET /api/user/my-sessions
  static Future<List<Transaction>> getMySessions() async {
    final uri = Uri.parse('$_baseUrl/api/transactions/recent');
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
    final res = await _withRetry(
      () =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected response: ${res.body}');
  }

  // GET /api/status/{stationId}/{connectorId}
  // static Future<Map<String, dynamic>> getStatusById(
  //   String stationId,
  //   int connectorId,
  // ) async {
  //   final uri = Uri.parse(
  //     '$_baseUrl/api/status/${Uri.encodeComponent(stationId)}/$connectorId',
  //   );
  //   final headers = <String, String>{'Accept': 'application/json'};
  //   if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
  //   final res = await _withRetry(
  //     () =>
  //         http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
  //   );
  //   if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  //   return jsonDecode(res.body) as Map<String, dynamic>;
  // }

  // Запуск зарядки
  // static Future<String?> remoteStart(
  //   String chargePointId,
  //   int connectorId,
  //   String idTag,
  // ) async {
  //   // map to new admin/user endpoints if available
  //   final uri = Uri.parse('$_baseUrl/api/admin/remote-start-session');
  //   final headers = <String, String>{'Content-Type': 'application/json'};
  //   if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
  //   final body = jsonEncode({
  //     'stationId': chargePointId,
  //     'connectorId': connectorId,
  //     'userId': idTag,
  //   });

  //   try {
  //     final res = await _withRetry(
  //       () => http
  //           .post(uri, headers: headers, body: body)
  //           .timeout(const Duration(seconds: 10)),
  //     );
  //     debugPrint('RemoteStart Response: ${res.body}');
  //     if (res.statusCode == 200) {
  //       final decoded = jsonDecode(res.body);
  //       if (decoded is Map) {
  //         final tx =
  //             decoded['transactionId'] ??
  //             decoded['transaction_id'] ??
  //             decoded['data']?['transactionId'];
  //         if (tx != null) return tx.toString();
  //         if (decoded['success'] == true) return null; // success without tx
  //         throw Exception('Start failed: ${res.body}');
  //       }
  //       throw Exception('Start failed: ${res.body}');
  //     }
  //     throw Exception('HTTP error: ${res.statusCode} - ${res.body}');
  //   } catch (e) {
  //     throw Exception('Start error: $e');
  //   }
  // }

  // Остановка зарядки
  // static Future<bool> remoteStop(
  //   String chargePointId,
  //   int connectorId,
  //   String? transactionId,
  // ) async {
  //   if (transactionId == null) throw Exception('No transaction ID');
  //   final uri = Uri.parse('$_baseUrl/api/admin/remote-stop-session');
  //   final headers = <String, String>{'Content-Type': 'application/json'};
  //   if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';
  //   final body = jsonEncode({
  //     'stationId': chargePointId,
  //     'transactionId': transactionId,
  //   });

  //   try {
  //     final res = await _withRetry(
  //       () => http
  //           .post(uri, headers: headers, body: body)
  //           .timeout(const Duration(seconds: 10)),
  //     );
  //     debugPrint('RemoteStop Response: ${res.body}');
  //     if (res.statusCode == 200) {
  //       final decoded = jsonDecode(res.body);
  //       if (decoded is Map) {
  //         if (decoded['success'] == true || decoded['ok'] == true) return true;
  //       }
  //       // если server вернул простой текст или пустой объект, считаем OK
  //       return true;
  //     }
  //     throw Exception('HTTP error: ${res.statusCode} - ${res.body}');
  //   } catch (e) {
  //     throw Exception('Stop error: $e');
  //   }
  // }

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
