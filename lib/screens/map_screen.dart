// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/station_provider.dart';
import '../models/station_model.dart';
import 'charging_session_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isMapMode = true;
  final MapController _mapController = MapController();
  LatLng? _currentLocation; // Текущее местоположение пользователя
  bool _isLoadingLocation = false;

  // Константы для стилей
  static const EdgeInsets _searchPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );
  static const EdgeInsets _togglePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );
  static const EdgeInsets _listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets _modalHorizontalPadding = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const EdgeInsets _modalVerticalPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );
  static const EdgeInsets _connectorPadding = EdgeInsets.symmetric(
    vertical: 8,
    horizontal: 16,
  );
  static const BorderRadius _cardBorder = BorderRadius.all(
    Radius.circular(15.0),
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Получить текущее местоположение пользователя
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Проверка разрешений
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Разрешение на геолокацию отклонено');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Разрешение на геолокацию отклонено навсегда');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Получение текущей позиции
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      debugPrint(
        '✅ Местоположение: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения местоположения: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Переместить карту к текущему местоположению
  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      _getCurrentLocation().then((_) {
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, 15.0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isMapMode
        ? Consumer<StationProvider>(
            builder: (context, provider, child) {
              return Stack(
                children: [
                  _buildMapView(context, provider),
                  // Панель поиска поверх карты
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск станций...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  // Кнопки переключения карта/список поверх карты
                  Positioned(
                    top: 72,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            'Карта',
                            _isMapMode,
                            () => _setMode(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildToggleButton(
                            'Список',
                            !_isMapMode,
                            () => _setMode(false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Кнопки статистики внизу
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: _buildBottomButtons(),
                  ),
                  // Кнопка "Моё местоположение" справа снизу над кнопками статистики
                  Positioned(
                    right: 16,
                    bottom: 90,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _moveToCurrentLocation,
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.my_location,
                              color: _currentLocation != null
                                  ? const Color(0xFF00C6A7)
                                  : Colors.grey,
                            ),
                    ),
                  ),
                  // Кнопки масштабирования справа по центру
                  Positioned(
                    right: 16,
                    top: MediaQuery.of(context).size.height * 0.4,
                    child: Column(
                      children: [
                        // Кнопка "+"
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(
                                  _mapController.camera.center,
                                  currentZoom + 1,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.add,
                                  color: Color(0xFF00C6A7),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Разделитель
                        Container(
                          width: 44,
                          height: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        // Кнопка "-"
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(
                                  _mapController.camera.center,
                                  currentZoom - 1,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.remove,
                                  color: Color(0xFF00C6A7),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          )
        : Column(
            children: [
              // Панель поиска
              Container(
                padding: _searchPadding,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск станций...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              // Кнопки переключения карта/список
              Padding(
                padding: _togglePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        'Карта',
                        _isMapMode,
                        () => _setMode(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildToggleButton(
                        'Список',
                        !_isMapMode,
                        () => _setMode(false),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<StationProvider>(
                  builder: (context, provider, child) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        try {
                          // Пытаемся загрузить через WebSocket с fallback на HTTP
                          // Добавляем общий timeout для всей операции
                          await provider.fetchStationsWithWebSocket().timeout(
                            const Duration(seconds: 10),
                            onTimeout: () {
                              throw TimeoutException(
                                'Загрузка станций заняла слишком много времени',
                              );
                            },
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка обновления: $e'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      child: provider.isLoading
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ],
                            )
                          : (provider.stations.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.6,
                                        child: const Center(
                                          child: Text(
                                            'Станции не найдены',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : _buildListScreen(context, provider)),
                    );
                  },
                ),
              ),
            ],
          );
  }

  //Кнопки переключения карта/список
  Widget _buildToggleButton(
    String label,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF00C6A7), Color(0xFF70E000)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.90),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: isActive ? Colors.white : Colors.black87,
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  void _setMode(bool isMap) {
    setState(() => _isMapMode = isMap);
    debugPrint('Выбран: ${isMap ? 'Карта' : 'Список'}');
  }

  List<Marker> _createMarkers(List<Station> stations) {
    return stations
        .where((station) => station.lat != null && station.lng != null)
        .map((station) {
          return Marker(
            point: LatLng(station.lat!, station.lng!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // Показать информацию о станции
                _showStationInfo(context, station);
              },
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          );
        })
        .toList();
  }

  void _showStationInfo(BuildContext context, Station station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(station.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.address),
            const SizedBox(height: 8),
            Text('Доступно: ${station.available}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  // Построение карты
  Widget _buildMapView(BuildContext context, StationProvider provider) {
    final stations = provider.stations;
    final markers = _createMarkers(stations);

    // Добавляем маркер текущего местоположения если доступен
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 3),
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
          ),
        ),
      );
    }

    // Начальная позиция: Махачкала (Дагестан)
    LatLng initialPosition;
    if (_currentLocation != null) {
      // Если есть текущее местоположение, используем его
      initialPosition = _currentLocation!;
    } else if (stations.isNotEmpty &&
        stations.first.lat != null &&
        stations.first.lng != null) {
      // Если есть станции, используем первую
      initialPosition = LatLng(stations.first.lat!, stations.first.lng!);
    } else {
      // По умолчанию - Махачкала
      initialPosition = const LatLng(42.9849, 47.5047);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialPosition,
        initialZoom: 13.0,
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
          rotate: false, // Маркеры не вращаются вместе с картой
        ),
      ],
    );
  }

  //Список станций
  Widget _buildListScreen(BuildContext context, StationProvider provider) {
    final stations = provider.stations;
    // debugPrint(provider.isLoading.toString());
    if (provider.isLoading) {
      // Should not reach here when wrapped by RefreshIndicator (we handle loading above)
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }
    if (stations.isEmpty) {
      return Center(
        child: Text(
          'Станции не найдены',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: stations.length,
      itemBuilder: (context, index) =>
          _StationListItem(station: stations[index], provider: provider),
    );
  }

  //Нижние кнопки рядом/доступно/км
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              Icons.location_on,
              '5',
              'Рядом',
              const Color(0xFF00C6A7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              Icons.fiber_manual_record,
              '12',
              'Доступно',
              const Color(0xFF70E000),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              Icons.route,
              '0.5',
              'KM',
              const Color(0xFF00C6A7),
            ),
          ),
        ],
      ),
    );
  }

  //Построение нижних кнопок
  Widget _buildButton(IconData icon, String number, String label, Color color) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.95), color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Элемент списка
class _StationListItem extends StatelessWidget {
  final Station station;
  final StationProvider provider;

  const _StationListItem({required this.station, required this.provider});

  @override
  Widget build(BuildContext context) {
    final chargePointId = station.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: _MapScreenState._cardBorder,
        ),
        child: InkWell(
          onTap: () => _showStationModal(context, chargePointId),
          child: Padding(
            padding: _MapScreenState._listItemPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        station.name.isNotEmpty ? station.name : 'Неизвестно',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        station.available,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  station.address,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        station.distance,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow[700], size: 16),
                        const SizedBox(width: 4),
                        Text(station.rating.toString()),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              station.favorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: const Color.fromARGB(255, 23, 108, 255),
                              size: 20,
                            ),
                            onPressed: () =>
                                provider.toggleFavorite(station.id),
                          ),
                          Flexible(
                            child: Text(
                              station.id,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: station.status
                                .map(
                                  (color) =>
                                      Icon(Icons.circle, size: 8, color: color),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: station.connectors
                      .map<Widget>(
                        (conn) => Chip(
                          label: Text(conn.type),
                          backgroundColor: Colors.grey[200],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Нижнее всплывающее окно
  void _showStationModal(BuildContext context, String chargePointId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<StationProvider>(
        builder: (context, provider, child) =>
            _StationModal(chargePointId: chargePointId, provider: provider),
      ),
    );
  }
}

// Модалка (Bottom sheet)
class _StationModal extends StatefulWidget {
  final String chargePointId;
  final StationProvider provider;

  const _StationModal({required this.chargePointId, required this.provider});

  @override
  State<_StationModal> createState() => _StationModalState();
}

class _StationModalState extends State<_StationModal> {
  @override
  Widget build(BuildContext context) {
    final station = widget.provider.stations.firstWhere(
      (s) => s.id == widget.chargePointId,
      orElse: () => Station.empty(),
    );
    if (station.id.isEmpty) {
      return const Center(child: Text('Станция не найдена'));
    }
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Column(
        children: [
          // Верхняя панель (кнопки назад и меню)
          Padding(
            padding: _MapScreenState._modalVerticalPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ),
          // Название и рейтинг
          Padding(
            padding: _MapScreenState._modalHorizontalPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    station.name.isNotEmpty ? station.name : 'Неизвестно',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow[700], size: 20),
                    const SizedBox(width: 4),
                    Text((station.rating).toString()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Адрес
          Padding(
            padding: _MapScreenState._modalHorizontalPadding,
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    station.address,
                    style: TextStyle(color: Colors.grey[700]),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Чипы (маленькие карточки с инфо)
          Padding(
            padding: _MapScreenState._modalHorizontalPadding,
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(station.available),
                  backgroundColor: Colors.green[100],
                ),
                Chip(
                  label: Text(station.distance),
                  backgroundColor: Colors.grey[200],
                ),
                Chip(
                  label: Text(station.time),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
          ),
          // Заголовок разъёмов
          SizedBox(height: 10),
          Padding(
            padding: _MapScreenState._modalHorizontalPadding,
            child: const Text(
              'Доступные разъёмы',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // Доступные коннекторы
          Expanded(child: _buildConnectorsList(context, station)),
          // Кнопка маршрута
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Построить маршрут',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Доступные коннекторы
  Widget _buildConnectorsList(BuildContext context, Station station) {
    final connectors = station.connectors;
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(), // Плавная прокрутка
      itemCount: connectors.length,
      itemBuilder: (context, connIndex) {
        final connector = connectors[connIndex];
        final connectorId = connIndex + 1;
        // Поиск станции и коннектора в провайдере
        final stationFromProvider = widget.provider.stations.firstWhere(
          (s) => s.id == widget.chargePointId,
          orElse: () => Station.empty(),
        );
        final providerConnector = stationFromProvider.connectors.firstWhere(
          (c) => c.id == connectorId,
          orElse: () => Connector(id: 0, type: '', power: '', price: ''),
        );

        final savedStatus = providerConnector.id != 0
            ? providerConnector.status
            : (connector.status);
        final savedColor = providerConnector.id != 0
            ? providerConnector.statusColor
            : connector.statusColor;
        final isAvailable =
            savedStatus.toLowerCase() == 'available' ||
            savedStatus == 'Доступен';
        final isCharging =
            savedStatus.toLowerCase() == 'charging' || savedStatus == 'Зарядка';
        final isOccupied =
            savedStatus.toLowerCase() == 'occupied' || savedStatus == 'Занят';

        return Padding(
          padding: _MapScreenState._connectorPadding,
          child: Column(
            children: [
              // Инфо о коннекторе
              _buildConnectorRow(connector, savedStatus, savedColor),
              const SizedBox(height: 8),
              //Кнопки коннектора
              _buildActionButton(
                isAvailable,
                isCharging,
                isOccupied,
                connectorId,
                context,
                providerConnector,
                connector,
                station,
              ),
            ],
          ),
        );
      },
    );
  }

  //Инфо коннектора
  Widget _buildConnectorRow(Connector connector, String status, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connector.type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(connector.power),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(connector.price, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  //Кнопки коннектора
  Widget _buildActionButton(
    bool isAvailable,
    bool isCharging,
    bool isOccupied,
    int connectorId,
    BuildContext context,
    Connector providerConnector,
    Connector connector,
    Station station,
  ) {
    return ElevatedButton(
      onPressed: isOccupied
          ? null
          : () async {
              try {
                // Открываем экран сессии зарядки — он выполнит запросы start/stop и будет опрашивать статус
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChargingSessionScreen(
                      station: station,
                      connector: connector,
                      connectorIndex: connectorId,
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isOccupied
            ? Colors.grey[800]
            : (isAvailable ? Colors.green : Colors.red),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(
        isOccupied
            ? 'Занят'
            : (isAvailable ? 'Начать зарядку' : 'Остановить зарядку'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
