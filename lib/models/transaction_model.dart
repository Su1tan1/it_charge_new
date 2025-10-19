class Transaction {
  final String transactionId;
  final String chargePointId;
  final int connectorId;
  final String? userId;
  final DateTime? startTime;
  final DateTime? stopTime;
  final double? energy;
  final String? status;
  final double? meterStart;
  final double? meterStop;
  final double? cost;

  Transaction({
    required this.transactionId,
    required this.chargePointId,
    required this.connectorId,
    this.userId,
    this.startTime,
    this.stopTime,
    this.energy,
    this.status,
    this.meterStart,
    this.meterStop,
    this.cost,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Transaction(
      transactionId:
          json['transactionId']?.toString() ?? json['id']?.toString() ?? '',
      chargePointId:
          json['chargePointId']?.toString() ??
          json['stationId']?.toString() ??
          '',
      connectorId: (json['connectorId'] is int)
          ? json['connectorId']
          : int.tryParse(json['connectorId']?.toString() ?? '') ?? 0,
      userId: json['userId']?.toString(),
      startTime: parseDt(json['startTime']),
      stopTime: parseDt(json['stopTime']),
      energy: (json['energy'] is num)
          ? (json['energy'] as num).toDouble()
          : null,
      status: json['status']?.toString(),
      meterStart: (json['meterStart'] is num)
          ? (json['meterStart'] as num).toDouble()
          : null,
      meterStop: (json['meterStop'] is num)
          ? (json['meterStop'] as num).toDouble()
          : null,
      cost: (json['cost'] is num) ? (json['cost'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'chargePointId': chargePointId,
    'connectorId': connectorId,
    'userId': userId,
    'startTime': startTime?.toIso8601String(),
    'stopTime': stopTime?.toIso8601String(),
    'energy': energy,
    'status': status,
    'meterStart': meterStart,
    'meterStop': meterStop,
    'cost': cost,
  };
}
