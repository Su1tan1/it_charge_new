import 'dart:ui';

class ConnectorStatus {
  final int connectorId;
  String status; // 'Доступен', 'Зарядка' и т.д.
  Color statusColor;

  ConnectorStatus({
    required this.connectorId,
    required this.status,
    required this.statusColor,
  });
}

class StationState {
  final String chargePointId;
  Map<int, ConnectorStatus> connectors; // По connectorId

  StationState({required this.chargePointId, required this.connectors});
}
