import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:it_charge/config.dart';
import 'package:it_charge/models/transaction_model.dart';

/// Сервис для работы с Transactions API (история зарядок)
class TransactionsService {
  static String get _baseUrl => Config.transactionsUrl;

  /// Получить историю зарядок пользователя
  static Future<List<Transaction>> getMyHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final url = '$_baseUrl/my-history?limit=$limit&offset=$offset';
    final headers = <String, String>{'Content-Type': 'application/json'};

    try {
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      List<Transaction> transactions = [];

      if (decoded is List) {
        transactions = decoded
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (decoded is Map) {
        final list =
            decoded['data'] ?? decoded['transactions'] ?? decoded['items'];
        if (list is List) {
          transactions = list
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      debugPrint('✅ getMyHistory: ${transactions.length} транзакций');
      return transactions;
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ getMyHistory: $errMsg');
      rethrow;
    }
  }

  /// Альтернативный способ запуска зарядки через Transactions API
  static Future<Map<String, dynamic>> startTransaction({
    required String stationId,
    required int connectorId,
    required String idTag,
  }) async {
    final url = '$_baseUrl/start';
    final headers = <String, String>{'Content-Type': 'application/json'};

    final bodyMap = <String, dynamic>{
      'stationId': stationId,
      'connectorId': connectorId,
      'idTag': idTag,
    };
    final body = jsonEncode(bodyMap);

    try {
      final res = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('HTTP ${res.statusCode}');
      }

      debugPrint('✅ startTransaction через Transactions API');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ startTransaction: $errMsg');
      rethrow;
    }
  }

  /// Альтернативный способ остановки зарядки через Transactions API
  static Future<Map<String, dynamic>> stopTransaction(
    String transactionId,
  ) async {
    final url = '$_baseUrl/$transactionId/stop';
    final headers = <String, String>{'Content-Type': 'application/json'};

    try {
      final res = await http
          .post(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('HTTP ${res.statusCode}');
      }

      debugPrint('✅ stopTransaction через Transactions API');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ stopTransaction: $errMsg');
      rethrow;
    }
  }
}
