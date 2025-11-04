import 'dart:async';
import 'package:flutter/material.dart';
import 'package:it_charge/models/station_model.dart';
import '../services/ocpp_service.dart';
import 'package:it_charge/services/csms_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StationProvider extends ChangeNotifier {
  List<Station> stations = [];
  bool isLoading = false;
  String? errorMessage;
  Timer? _pollingTimer;

  /// Создаёт провайдера. Если [autoStart] == true — сразу сделает initial fetch (без polling).
  StationProvider({bool autoStart = false}) {
    if (autoStart) {
      fetchStations();
    }
    // Слушаем изменения статуса коннекторов
    CSMSClient.instance.events.listen((ev) {
      try {
        final eventName = ev['event']?.toString() ?? '';
        if (eventName == 'connector.status.changed' && ev['data'] is Map) {
          final d = ev['data'] as Map<String, dynamic>;
          final stationId = d['chargePointId']?.toString() ?? '';
          final connectorId =
              int.tryParse(d['connectorId']?.toString() ?? '') ?? 0;
          final status = d['status']?.toString() ?? '';
          final color = status == 'Available' ? Colors.green : Colors.orange;
          updateConnectorStatus(
            stationId,
            connectorId,
            status,
            color,
            transactionId: d['transactionId']?.toString(),
          );
        }
      } catch (e) {
        debugPrint('⚠️ Event error: $e');
      }
    });
  }

  /// Включить автообновление во время работы (вызывать, если нужно динамически включать).
  void enableAutoPolling() {
    fetchStations();
    startPolling();
  }

  /// Отключить автообновление во время работы.
  void disableAutoPolling() {
    stopPolling();
  }

  Future<void> fetchStations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      stations = await OcppService.fetchStations();
      // Загружаем избранное
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? [];
      for (var station in stations) {
        station.favorite = favorites.contains(station.id);
      }
    } catch (e) {
      errorMessage = 'Ошибка: $e';
      debugPrint('❌ fetchStations: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh helper for UI
  Future<void> refresh() async {
    await fetchStations();
  }

  /// Попробовать загрузить станции через WebSocket, с fallback на HTTP
  Future<void> fetchStationsWithWebSocket() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    debugPrint('StationProvider: Начало загрузки станций через WebSocket');

    try {
      // Попытка WebSocket если подключен
      if (CSMSClient.instance.connected) {
        try {
          final resp = await CSMSClient.instance
              .request('getStations', null, const Duration(seconds: 3))
              .timeout(const Duration(seconds: 5));

          // Парсим список станций
          List<Station> wsStations = [];
          if (resp['stations'] is List) {
            wsStations = (resp['stations'] as List)
                .map((e) => Station.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (resp.values.isNotEmpty && resp.values.first is List) {
            wsStations = (resp.values.first as List)
                .map((e) => Station.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          if (wsStations.isNotEmpty) {
            stations = wsStations;
            final prefs = await SharedPreferences.getInstance();
            final favorites = prefs.getStringList('favorites') ?? [];
            for (var station in stations) {
              station.favorite = favorites.contains(station.id);
            }
            debugPrint('✅ WS: ${stations.length} станций');
            return; // Успешно через WebSocket
          }
        } on TimeoutException {
          debugPrint('⏱️ WS timeout → HTTP');
        } catch (e) {
          final errMsg = e.toString().length > 50
              ? '${e.toString().substring(0, 50)}...'
              : e.toString();
          debugPrint('⚠️ WS: $errMsg → HTTP');
        }
      }

      // Fallback на HTTP
      final stationsList = await OcppService.fetchStationsHTTPOnly();
      stations = stationsList;
      debugPrint('✅ HTTP: ${stations.length} станций');

      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? [];
      for (var station in stations) {
        station.favorite = favorites.contains(station.id);
      }
    } catch (e) {
      errorMessage = 'Ошибка: $e';
      debugPrint('❌ fetchStationsWithWebSocket: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String chargePointId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    if (favorites.contains(chargePointId)) {
      favorites.remove(chargePointId);
    } else {
      favorites.add(chargePointId);
    }
    await prefs.setStringList('favorites', favorites);
    final station = stations.firstWhere(
      (s) => s.id == chargePointId,
      orElse: () => Station.empty(),
    );
    if (station.id.isNotEmpty) {
      station.favorite = favorites.contains(chargePointId);
      notifyListeners();
    }
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchStations();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  void updateConnectorStatus(
    String chargePointId,
    int connectorId,
    String newStatus,
    Color newColor, {
    String? transactionId,
  }) {
    final station = stations.firstWhere(
      (s) => s.id == chargePointId,
      orElse: () => Station.empty(),
    );
    if (station.id.isEmpty) return;
    final connector = station.connectors.firstWhere(
      (c) => c.id == connectorId,
      orElse: () => Connector(id: 0, type: '', power: '', price: ''),
    );
    if (connector.id == 0) return;
    connector.status = newStatus;
    connector.statusColor = newColor;
    connector.transactionId = transactionId;
    station.available =
        '${station.connectors.where((c) => c.status == 'Available').length}/${station.connectors.length}';
    station.status = station.connectors.map((c) => c.statusColor).toList();
    notifyListeners();
  }

  void resetConnectorStatus(String chargePointId, int connectorId) {
    final station = stations.firstWhere(
      (s) => s.id == chargePointId,
      orElse: () => Station.empty(),
    );
    if (station.id.isEmpty) return;
    final connector = station.connectors.firstWhere(
      (c) => c.id == connectorId,
      orElse: () => Connector(id: 0, type: '', power: '', price: ''),
    );
    if (connector.id == 0) return;
    connector.status = 'Available';
    connector.statusColor = Colors.green;
    connector.transactionId = null;
    station.available =
        '${station.connectors.where((c) => c.status == 'Available').length}/${station.connectors.length}';
    station.status = station.connectors.map((c) => c.statusColor).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
