# Миграция с Google Maps на OpenStreetMap (flutter_map)

## ✅ Выполненные изменения

### 1. Зависимости (pubspec.yaml)
**Удалено:**
```yaml
google_maps_flutter: ^2.13.1
```

**Добавлено:**
```yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1
```

### 2. Код карты (lib/screens/map_screen.dart)

**Было (Google Maps):**
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

GoogleMap(
  mapType: MapType.normal,
  initialCameraPosition: CameraPosition(
    target: LatLng(lat, lng),
    zoom: 14.0,
  ),
  markers: markers,
  onMapCreated: (controller) => _controller.complete(controller),
)
```

**Стало (OpenStreetMap):**
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

final MapController _mapController = MapController();

FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: LatLng(lat, lng),
    initialZoom: 14.0,
    minZoom: 5.0,
    maxZoom: 18.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.it_charge',
      maxZoom: 19,
    ),
    MarkerLayer(
      markers: markers,
    ),
  ],
)
```

### 3. Маркеры

**Было:**
```dart
Set<Marker> _createMarkers(List<Station> stations) {
  return stations.map((station) {
    return Marker(
      markerId: MarkerId(station.id),
      position: LatLng(station.lat!, station.lng!),
      infoWindow: InfoWindow(title: station.name),
      onTap: () => ...,
    );
  }).toSet();
}
```

**Стало:**
```dart
List<Marker> _createMarkers(List<Station> stations) {
  return stations.map((station) {
    return Marker(
      point: LatLng(station.lat!, station.lng!),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showStationInfo(context, station),
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
        ),
      ),
    );
  }).toList();
}
```

### 4. Android (AndroidManifest.xml)

**Удалено:**
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### 5. iOS (AppDelegate.swift)

**Удалено:**
```swift
import GoogleMaps
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 6. iOS (Podfile)

**Удалено:**
```ruby
pod 'GoogleMaps', '8.4.0'
```

---

## 🎯 Преимущества OpenStreetMap

1. **Полностью бесплатно** - нет квот, нет биллинга
2. **Нет API ключей** - не нужна регистрация в Google Cloud
3. **Открытый исходный код** - community-driven карты
4. **Гибкость** - можно использовать разные tile providers
5. **Меньше зависимостей** - не нужны нативные SDK

---

## 🔄 Дополнительные tile providers

Можно использовать другие карты, изменив `urlTemplate`:

### Mapbox (требует API ключ):
```dart
urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
additionalOptions: {
  'accessToken': 'YOUR_MAPBOX_TOKEN',
  'id': 'mapbox/streets-v11',
},
```

### CartoDB (темная тема):
```dart
urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
```

### Satellite (Esri):
```dart
urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
```

---

## 🛠️ Следующие шаги (если нужно)

### Переустановить iOS зависимости:
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Очистить кэш и пересобрать:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Дополнительные возможности flutter_map

### Интерактивные флаги:
```dart
MapOptions(
  interactionOptions: InteractionOptions(
    flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Все кроме вращения
  ),
)
```

### Слои:
```dart
children: [
  TileLayer(...),
  MarkerLayer(...),
  PolylineLayer(...),  // Маршруты
  PolygonLayer(...),   // Зоны
  CircleLayer(...),    // Радиусы
]
```

### Кластеризация маркеров:
Добавить пакет `flutter_map_marker_cluster`

### Офлайн карты:
Добавить пакет `flutter_map_tile_caching`

---

## ⚠️ Важно

- OpenStreetMap имеет [Usage Policy](https://operations.osmfoundation.org/policies/tiles/)
- Для production приложений рекомендуется использовать собственный tile server или коммерческий сервис
- Текущая настройка подходит для разработки и небольших приложений
