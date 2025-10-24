import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:it_charge/services/csms_client.dart';
import 'package:it_charge/models/station_model.dart';
import 'package:it_charge/config.dart';
import 'package:it_charge/models/transaction_model.dart';

class OcppService {
  static String get _baseUrl => Config.baseUrl;
  static String get _apiKey => Config.apiKey;

  // HTTP-запрос с ретраями
  static Future<http.Response> _httpRequest({
    required Future<http.Response> Function() requestFn,
    required String method,
    required String endpoint,
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final res = await requestFn();
        if (res.statusCode != 200) {
          final errMsg = res.statusCode.toString();
          debugPrint('⚠️ HTTP $method $endpoint: $errMsg');
        }
        return res;
      } catch (e) {
        if (attempts >= Config.maxRetries) {
          final errMsg = e.toString().length > 40
              ? e.toString().substring(0, 40) + '...'
              : e.toString();
          debugPrint('❌ $method $endpoint: $errMsg');
          rethrow;
        }
        final delayMs = Config.retryBaseDelayMs * (1 << (attempts - 1));
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  // Унифицированный метод для разбора ответа (станции, транзакции и т.д.)
  static List<T> _parseListResponse<T>(
    dynamic decoded,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (decoded is List) {
      return decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    if (decoded is Map) {
      final list =
          decoded['data'] ??
          decoded['result'] ??
          decoded['stations'] ??
          decoded['transactions'] ??
          decoded['items'] ??
          decoded['sessions'];
      if (list is List) {
        return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    throw Exception('Неожиданная форма ответа');
  }

  // Получение станций только через HTTP (для pull-to-refresh)
  static Future<List<Station>> fetchStationsHTTPOnly() async {
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
      try {
        final res = await http
            .get(Uri.parse('$_baseUrl$path'), headers: headers)
            .timeout(const Duration(seconds: 10));

        if (res.statusCode != 200) {
          errors.add('[$path] ${res.statusCode}');
          continue;
        }
        final decoded = jsonDecode(res.body);
        return _parseListResponse<Station>(decoded, Station.fromJson);
      } catch (e) {
        errors.add('[$path] $e');
      }
    }
    throw Exception('Все HTTP-эндпоинты провалились: ${errors.join('; ')}');
  }

  // Получение станций
  static Future<List<Station>> fetchStations() async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      if (!ws.connected) await ws.connect();
      final resp = await ws.request('getStations');
      debugPrint('✅ WS getStations');
      return _parseListResponse<Station>(resp, Station.fromJson);
    } catch (e) {
      debugPrint('⚠️ WS getStations → HTTP');
    }

    // Фоллбек на HTTP
    return fetchStationsHTTPOnly();
  }

  // Получение транзакций для станции
  static Future<List<Transaction>> getTransactionsForStation(
    String chargePointId,
  ) async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      if (!ws.connected) await ws.connect();
      final res = await ws.request('getRecentTransactions', {
        'limit': 50,
        'stationId': chargePointId,
      });
      debugPrint('✅ WS getRecentTransactions');
      return _parseListResponse<Transaction>(res, Transaction.fromJson);
    } catch (e) {
      debugPrint('⚠️ WS getRecentTransactions → HTTP');
    }

    // Фоллбек на HTTP
    final candidates = [
      '/api/transactions?chargePointId=${Uri.encodeComponent(chargePointId)}',
      '/api/transactions?stationId=${Uri.encodeComponent(chargePointId)}',
      '/api/user/transactions?stationId=${Uri.encodeComponent(chargePointId)}',
      '/api/user/my-sessions?stationId=${Uri.encodeComponent(chargePointId)}',
      '/api/user/sessions?stationId=${Uri.encodeComponent(chargePointId)}',
    ];
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    for (final p in candidates) {
      try {
        final res = await _httpRequest(
          method: 'GET',
          endpoint: p,
          requestFn: () => http
              .get(Uri.parse('$_baseUrl$p'), headers: headers)
              .timeout(const Duration(seconds: 10)),
        );
        if (res.statusCode != 200) continue;
        final decoded = jsonDecode(res.body);
        debugPrint('✅ HTTP getRecentTransactions');
        return _parseListResponse<Transaction>(decoded, Transaction.fromJson);
      } catch (e) {
        continue;
      }
    }
    throw Exception('Все HTTP-эндпоинты провалились');
  }

  // Получение статуса коннектора
  static Future<Map<String, dynamic>> getConnectorStatus(
    String stationId,
    int connectorId,
  ) async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      if (!ws.connected) await ws.connect();
      final res = await ws.request('getConnectorStatus', {
        'stationId': stationId,
        'connectorId': connectorId,
      });
      debugPrint('✅ WS getConnectorStatus');
      return res;
    } catch (e) {
      debugPrint('⚠️ WS getConnectorStatus → HTTP');
    }

    // Фоллбек на HTTP
    final endpoint =
        '/api/user/connector-status/${Uri.encodeComponent(stationId)}/$connectorId';
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    final res = await _httpRequest(
      method: 'GET',
      endpoint: endpoint,
      requestFn: () => http
          .get(Uri.parse('$_baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    debugPrint('✅ HTTP getConnectorStatus');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Запуск зарядки
  static Future<Map<String, dynamic>> userStartCharging(
    String stationId,
    int connectorId,
    String idTag, {
    String? authToken,
    int? startValue,
  }) async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      if (!ws.connected) await ws.connect();
      final res = await ws.request('startCharging', {
        'stationId': stationId,
        'connectorId': connectorId,
        'idTag': idTag,
      });
      debugPrint('✅ WS startCharging');
      return res;
    } catch (e) {
      debugPrint('⚠️ WS startCharging → HTTP');
    }

    // Фоллбек на HTTP
    final endpoint = '/api/admin/remote-start-session';
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

    final res = await _httpRequest(
      method: 'POST',
      endpoint: endpoint,
      requestFn: () => http
          .post(Uri.parse('$_baseUrl$endpoint'), headers: headers, body: body)
          .timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('HTTP ${res.statusCode}');
    }
    debugPrint('✅ startCharging через HTTP');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Остановка зарядки
  static Future<Map<String, dynamic>> userStopCharging(
    String transactionId, {
    String? chargePointId,
    int? connectorId,
  }) async {
    final stationId =
        chargePointId; // chargePointId is actually stationId from the backend

    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      if (!ws.connected) await ws.connect();
      final res = await ws.request('stopCharging', {
        'transactionId': transactionId,
        'stationId': stationId,
        'connectorId': connectorId,
      });
      debugPrint('✅ WS stopCharging');
      return res;
    } catch (e) {
      debugPrint('⚠️ WS stopCharging → HTTP');
    }

    // Фоллбек на HTTP с несколькими эндпоинтами
    final candidates = ['/api/admin/remote-stop-session'];
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    final bodyMap = <String, dynamic>{'transactionId': transactionId};
    if (stationId != null) bodyMap['stationId'] = stationId;
    if (connectorId != null) bodyMap['connectorId'] = connectorId;
    final body = jsonEncode(bodyMap);

    for (final p in candidates) {
      try {
        final res = await _httpRequest(
          method: 'POST',
          endpoint: p,
          requestFn: () => http
              .post(Uri.parse('$_baseUrl$p'), headers: headers, body: body)
              .timeout(const Duration(seconds: 10)),
        );
        if (res.statusCode != 200 && res.statusCode != 201) continue;
        debugPrint('✅ HTTP stopCharging');
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e) {
        continue;
      }
    }
    throw Exception('Все HTTP-эндпоинты провалились');
  }

  // Получение сессий (только HTTP, без WS)
  static Future<List<Transaction>> getMySessions() async {
    final endpoint = '/api/transactions/recent';
    final headers = <String, String>{'Accept': 'application/json'};
    if (_apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $_apiKey';

    final res = await _httpRequest(
      method: 'GET',
      endpoint: endpoint,
      requestFn: () => http
          .get(Uri.parse('$_baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    return _parseListResponse<Transaction>(decoded, Transaction.fromJson);
  }
}
