import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:it_charge/config.dart';
import 'package:it_charge/models/site_model.dart';

/// Сервис для работы с Sites API (группировка станций по локациям)
class SitesService {
  static String get _baseUrl => Config.stationsUrl;

  /// Получить список всех локаций
  static Future<List<Site>> getSites() async {
    final url = '$_baseUrl/sites';
    final headers = <String, String>{'Content-Type': 'application/json'};

    try {
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      List<Site> sites = [];

      if (decoded is List) {
        sites = decoded
            .map((e) => Site.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (decoded is Map) {
        final list = decoded['data'] ?? decoded['sites'] ?? decoded['items'];
        if (list is List) {
          sites = list
              .map((e) => Site.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      debugPrint('✅ getSites: ${sites.length} локаций');
      return sites;
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ getSites: $errMsg');
      rethrow;
    }
  }

  /// Получить детали конкретной локации
  static Future<Site> getSiteById(String siteId) async {
    final url = '$_baseUrl/sites/$siteId';
    final headers = <String, String>{'Content-Type': 'application/json'};

    try {
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      debugPrint('✅ getSiteById: $siteId');
      return Site.fromJson(decoded as Map<String, dynamic>);
    } catch (e) {
      final errMsg = e.toString().length > 40
          ? '${e.toString().substring(0, 40)}...'
          : e.toString();
      debugPrint('❌ getSiteById $siteId: $errMsg');
      rethrow;
    }
  }
}
