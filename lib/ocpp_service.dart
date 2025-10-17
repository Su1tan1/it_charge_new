import 'package:http/http.dart' as http;
import 'dart:convert';

class OcppService {
  static String baseUrl =
      'http://localhost:3000'; // Симулятор; для реала: 'https://your-api.com'
  static int?
  transactionId; // Глобальный, но в реале — по станции (используй Map<chargePointId, int> для multi)

  static Future<String> getStatus(String chargePointId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status?chargePointId=$chargePointId'))
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['status'] ?? 'Unknown';
      } else {
        throw Exception('Ошибка статуса: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Нет связи: $e');
    }
  }

  static Future<bool> remoteStart(
    String chargePointId,
    int connectorId,
    String idTag,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/remote-start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chargePointId': chargePointId,
              'connectorId': connectorId,
              'idTag': idTag,
            }),
          )
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        // В реале: transactionId = jsonDecode(response.body)['transactionId'];
        return true;
      } else {
        throw Exception('Ошибка Start: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка Start: $e');
    }
  }

  static Future<bool> remoteStop(String chargePointId) async {
    // В реале: transactionId из локального хранилища по chargePointId
    final localTransactionId = 123; // Симуляция; в реале — из состояния
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/remote-stop'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chargePointId': chargePointId,
              'transactionId': localTransactionId,
            }),
          )
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Ошибка Stop: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка Stop: $e');
    }
  }
}
