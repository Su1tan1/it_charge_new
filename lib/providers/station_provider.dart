import 'package:flutter/material.dart';
import '../models/station_model.dart';

class StationProvider extends ChangeNotifier {
  final Map<String, StationState> _stations = {}; // По chargePointId

  Map<String, StationState> get stations => _stations;

  void updateConnectorStatus(
    String chargePointId,
    int connectorId,
    String newStatus,
    Color newColor,
  ) {
    if (!_stations.containsKey(chargePointId)) {
      // Инициализируй, если нет
      _stations[chargePointId] = StationState(
        chargePointId: chargePointId,
        connectors: {},
      );
    }
    _stations[chargePointId]!.connectors[connectorId] = ConnectorStatus(
      connectorId: connectorId,
      status: newStatus,
      statusColor: newColor,
    );
    notifyListeners(); // Обнови UI везде
  }

  void resetConnectorStatus(String chargePointId, int connectorId) {
    updateConnectorStatus(chargePointId, connectorId, 'Доступен', Colors.green);
  }
}
