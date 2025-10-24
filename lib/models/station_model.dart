import 'package:flutter/material.dart';

class Station {
  final String id;
  final String name;
  final String address;
  final String distance;
  String available; // made mutable so providers can update computed value
  final String time;
  final double rating;
  List<Color> status; // made mutable
  bool favorite; // Не final для SharedPreferences
  final List<Connector> connectors;
  final double? lat;
  final double? lng;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.available,
    required this.time,
    required this.rating,
    required this.status,
    required this.favorite,
    required this.connectors,
    this.lat,
    this.lng,
  });

  /// Пустая/заглушечная станция для orElse
  factory Station.empty() => Station(
    id: '',
    name: '',
    address: '',
    distance: '0 km',
    available: '0/0',
    time: '24/7',
    rating: 0.0,
    status: [Colors.grey],
    favorite: false,
    connectors: [],
  );

  factory Station.fromJson(Map<String, dynamic> json) {
    // Поддерживаем JSON от сервера, пример:
    // {
    //  "stationId": "CP_001",
    //  "name": "Parking Lot A",
    //  "location": { "lat": 55.7, "lng": 37.6, "address": "..." },
    //  "connectors": [ ... ]
    // }
    final connectors =
        (json['connectors'] as List?)
            ?.map((c) => Connector.fromJson(c))
            .toList() ??
        [];

    // available: показываем количество доступных/всего
    final available = connectors.isNotEmpty
        ? '${connectors.where((c) => c.status.toLowerCase() == 'available').length}/${connectors.length}'
        : '${json['activeConnectors'] ?? 0}/${json['totalConnectors'] ?? connectors.length}';

    // статус станции как список цветов по коннекторам
    final statusColors = connectors.isNotEmpty
        ? connectors.map((c) => c.statusColor).toList()
        : [Colors.grey];

    // адрес берем из location.address если есть
    final location = json['location'] as Map<String, dynamic>?;
    final address = location != null
        ? (location['address']?.toString() ?? '')
        : (json['address']?.toString() ?? '');

    final lat = location != null
        ? (location['lat'] as num?)?.toDouble()
        : (json['lat'] as num?)?.toDouble();
    final lng = location != null
        ? (location['lng'] as num?)?.toDouble()
        : (json['lng'] as num?)?.toDouble();

    return Station(
      id:
          json['stationId']?.toString() ??
          json['id']?.toString() ??
          'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name:
          json['name']?.toString() ??
          'Станция ${json['stationId'] ?? json['id'] ?? 'N/A'}',
      address: address.isNotEmpty ? address : 'Адрес неизвестен',
      distance: json['distance']?.toString() ?? '—',
      available: available,
      time: json['lastSeen']?.toString() ?? json['time']?.toString() ?? '24/7',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      status: statusColors,
      favorite: json['favorite'] as bool? ?? false,
      connectors: connectors,
      lat: lat,
      lng: lng,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'distance': distance,
    'chargePointId': id,
    'available': available,
    'time': time,
    'rating': rating,
    'status': status,
    'favorite': favorite,
    'connectors': connectors.map((c) => c.toJson()).toList(),
    'lat': lat,
    'lng': lng,
  };
}

class Connector {
  final int id;
  String status; // Убрали final
  Color statusColor; // Убрали final
  String? transactionId; // Уже не final
  double? lastMeterValue;
  DateTime? lastMeterTimestamp;
  bool? isReserved;
  String? reservationId;
  String? errorCode;
  final String type;
  final String power;
  final String price;

  Connector({
    required this.id,
    required this.type,
    required this.power,
    required this.price,
    this.status = 'Available',
    this.statusColor = Colors.green,
    this.transactionId,
    this.lastMeterValue,
    this.lastMeterTimestamp,
    this.isReserved,
    this.reservationId,
    this.errorCode,
  });

  factory Connector.fromJson(Map<String, dynamic> json) {
    // Поддерживаем поле connectorId и разные форматы
    final id = (json['connectorId'] ?? json['id']) as dynamic;
    final status = json['status']?.toString() ?? 'Available';
    final tx =
        json['transactionId']?.toString() ?? json['transaction_id']?.toString();
    final lastMeterValue = (json['lastMeterValue'] is num)
        ? (json['lastMeterValue'] as num).toDouble()
        : (json['last_meter_value'] is num
              ? (json['last_meter_value'] as num).toDouble()
              : null);
    DateTime? lastMeterTs;
    try {
      final ts = json['lastMeterTimestamp'] ?? json['last_meter_timestamp'];
      if (ts != null) lastMeterTs = DateTime.parse(ts.toString());
    } catch (_) {
      lastMeterTs = null;
    }

    return Connector(
      id: (id is int) ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      type:
          json['type']?.toString() ??
          json['connectorType']?.toString() ??
          'Unknown',
      power: json['power']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      status: status,
      statusColor: _colorFromString(status),
      transactionId: tx,
      lastMeterValue: lastMeterValue,
      lastMeterTimestamp: lastMeterTs,
      isReserved: json['isReserved'] as bool? ?? json['is_reserved'] as bool?,
      reservationId:
          json['reservationId']?.toString() ??
          json['reservation_id']?.toString(),
      errorCode:
          json['errorCode']?.toString() ?? json['error_code']?.toString(),
    );
  }

  set deltaKWh(double deltaKWh) {}

  set currentKWh(double currentKWh) {}

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'power': power,
    'price': price,
    'status': status,
    'status_color': statusColor.toString(),
    'transactionId': transactionId,
    'lastMeterValue': lastMeterValue,
    'lastMeterTimestamp': lastMeterTimestamp?.toIso8601String(),
    'isReserved': isReserved,
    'reservationId': reservationId,
    'errorCode': errorCode,
  };

  static Color _colorFromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.orange;
      case 'charging':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
