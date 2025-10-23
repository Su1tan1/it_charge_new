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

  // Унифицированный метод для выполнения HTTP-запросов с ретраями и логами
  static Future<http.Response> _httpRequest({
    required Future<http.Response> Function() requestFn,
    required String method,
    required String endpoint,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('Попытка $method-запроса по HTTP к: ${uri.toString()}');
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final res = await requestFn();
        debugPrint(
          '$method-запрос по HTTP к $endpoint успешен: статус ${res.statusCode}',
        );
        return res;
      } catch (e) {
        debugPrint(
          'Ошибка $method-запроса по HTTP к $endpoint (попытка $attempts): $e',
        );
        if (attempts >= Config.maxRetries) {
          rethrow;
        }
        final delayMs = Config.retryBaseDelayMs * (1 << (attempts - 1));
        debugPrint('Повторная попытка через $delayMs мс');
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

  // Получение станций
  static Future<List<Station>> fetchStations() async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      debugPrint('Попытка подключения WebSocket...');
      if (!ws.connected) await ws.connect();
      debugPrint('WebSocket успешно подключен');
      final resp = await ws.request('getStations');
      debugPrint('Ответ от WebSocket для getStations: $resp');
      return _parseListResponse<Station>(resp, Station.fromJson);
    } catch (e) {
      debugPrint('Ошибка WebSocket для fetchStations: $e. Переход к HTTP.');
    }

    // Фоллбек на HTTP с несколькими эндпоинтами
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
        final res = await _httpRequest(
          method: 'GET',
          endpoint: path,
          requestFn: () => http
              .get(Uri.parse('$_baseUrl$path'), headers: headers)
              .timeout(const Duration(seconds: 10)),
        );
        if (res.statusCode != 200) {
          errors.add('[$path] HTTP ${res.statusCode}');
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

  // Получение транзакций для станции
  static Future<List<Transaction>> getTransactionsForStation(
    String chargePointId,
  ) async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      debugPrint('Попытка подключения WebSocket...');
      if (!ws.connected) await ws.connect();
      debugPrint('WebSocket успешно подключен');
      final res = await ws.request('getRecentTransactions', {
        'limit': 50,
        'stationId': chargePointId,
      });
      debugPrint('Ответ от WebSocket для getRecentTransactions: $res');
      return _parseListResponse<Transaction>(res, Transaction.fromJson);
    } catch (e) {
      debugPrint(
        'Ошибка WebSocket для getTransactionsForStation: $e. Переход к HTTP.',
      );
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

    List<String> errors = [];
    for (final p in candidates) {
      try {
        final res = await _httpRequest(
          method: 'GET',
          endpoint: p,
          requestFn: () => http
              .get(Uri.parse('$_baseUrl$p'), headers: headers)
              .timeout(const Duration(seconds: 10)),
        );
        if (res.statusCode != 200) {
          errors.add('[$p] HTTP ${res.statusCode}');
          continue;
        }
        final decoded = jsonDecode(res.body);
        return _parseListResponse<Transaction>(decoded, Transaction.fromJson);
      } catch (e) {
        errors.add('[$p] $e');
      }
    }
    throw Exception('Все HTTP-эндпоинты провалились: ${errors.join('; ')}');
  }

  // Получение статуса коннектора
  static Future<Map<String, dynamic>> getConnectorStatus(
    String stationId,
    int connectorId,
  ) async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      debugPrint('Попытка подключения WebSocket...');
      if (!ws.connected) await ws.connect();
      debugPrint('WebSocket успешно подключен');
      final res = await ws.request('getConnectorStatus', {
        'stationId': stationId,
        'connectorId': connectorId,
      });
      debugPrint('Ответ от WebSocket для getConnectorStatus: $res');
      return res;
    } catch (e) {
      debugPrint(
        'Ошибка WebSocket для getConnectorStatus: $e. Переход к HTTP.',
      );
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
      debugPrint('Попытка подключения WebSocket...');
      if (!ws.connected) await ws.connect();
      debugPrint('WebSocket успешно подключен');
      final res = await ws.request('startCharging', {
        'stationId': stationId,
        'connectorId': connectorId,
        'idTag': idTag,
      });
      debugPrint('Ответ от WebSocket для startCharging: $res');
      return res;
    } catch (e) {
      debugPrint('Ошибка WebSocket для userStartCharging: $e. Переход к HTTP.');
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
    debugPrint('Тело запроса для startCharging: $body');

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
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Остановка зарядки
  static Future<Map<String, dynamic>> userStopCharging(
    String transactionId, {
    String? chargePointId,
    int? connectorId,
  }) async {
    // Попытка WebSocket
    try {
      final ws = CSMSClient.instance;
      debugPrint('Попытка подключения WebSocket...');
      if (!ws.connected) await ws.connect();
      debugPrint('WebSocket успешно подключен');
      final res = await ws.request('stopCharging', {
        'transactionId': transactionId,
        'chargePointId': chargePointId,
        'connectorId': connectorId,
      });
      debugPrint('Ответ от WebSocket для stopCharging: $res');
      return res;
    } catch (e) {
      debugPrint('Ошибка WebSocket для userStopCharging: $e. Переход к HTTP.');
    }

    // Фоллбек на HTTP с несколькими эндпоинтами
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

    final bodyMap = <String, dynamic>{'transactionId': transactionId};
    if (chargePointId != null) bodyMap['chargePointId'] = chargePointId;
    if (connectorId != null) bodyMap['connectorId'] = connectorId;
    final body = jsonEncode(bodyMap);
    debugPrint('Тело запроса для stopCharging: $body');

    List<String> errors = [];
    for (final p in candidates) {
      try {
        final res = await _httpRequest(
          method: 'POST',
          endpoint: p,
          requestFn: () => http
              .post(Uri.parse('$_baseUrl$p'), headers: headers, body: body)
              .timeout(const Duration(seconds: 10)),
        );
        if (res.statusCode != 200 && res.statusCode != 201) {
          errors.add('[$p] HTTP ${res.statusCode}');
          continue;
        }
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e) {
        errors.add('[$p] $e');
      }
    }
    throw Exception('Все HTTP-эндпоинты провалились: ${errors.join('; ')}');
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
