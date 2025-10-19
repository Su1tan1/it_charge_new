import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:it_charge/models/station_model.dart';
import '../services/ocpp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StationProvider extends ChangeNotifier {
  List<Station> stations = [];
  bool isLoading = false;
  String? errorMessage;
  Timer? _pollingTimer;

  /// Создаёт провайдера. Если [autoStart] == true — сразу сделает initial fetch и запустит polling.
  StationProvider({bool autoStart = false}) {
    if (autoStart) {
      fetchStations();
      startPolling();
    }
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
