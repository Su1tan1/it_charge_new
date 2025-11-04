/// Модель для Site (локация со станциями)
class Site {
  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> stationIds; // IDs станций на этой локации
  final int totalConnectors;
  final int availableConnectors;

  Site({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    required this.stationIds,
    required this.totalConnectors,
    required this.availableConnectors,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id']?.toString() ?? json['siteId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Site',
      address: json['address']?.toString(),
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng']),
      stationIds:
          (json['stationIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalConnectors: json['totalConnectors'] as int? ?? 0,
      availableConnectors: json['availableConnectors'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'stationIds': stationIds,
      'totalConnectors': totalConnectors,
      'availableConnectors': availableConnectors,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
