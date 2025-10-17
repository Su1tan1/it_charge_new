import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ocpp_service.dart';
import '../providers/station_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isMapMode = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск станций...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
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
        // Toggle buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isMapMode = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMapMode
                        ? Colors.black
                        : Colors.grey[200],
                    foregroundColor: _isMapMode ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Карта'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isMapMode = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isMapMode
                        ? Colors.black
                        : Colors.grey[200],
                    foregroundColor: !_isMapMode ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Список'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isMapMode
              ? Container(
                  color: const Color(0xFFF5F7FA),
                  child: const Stack(
                    children: [Placeholder()], // Карта
                  ),
                )
              : Consumer<StationProvider>(
                  builder: (context, provider, child) =>
                      _buildListScreen(provider),
                ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton(Icons.location_on, '5', 'Рядом', Colors.blue[100]!),
              _buildButton(
                Icons.fiber_manual_record,
                '12',
                'Доступно',
                Colors.green[100]!,
              ),
              _buildButton(
                Icons.arrow_forward,
                '0.5',
                'KM',
                Colors.orange[100]!,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildButton(
    IconData icon,
    String number,
    String label,
    Color bgColor,
  ) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 4),
              Text(
                number,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildListScreen(StationProvider provider) {
    final List<Map<String, dynamic>> stations = [
      {
        'name': 'Кинотеатр "Октябрь" DC150',
        'address': 'Республика Дагестан, Махачкала, ул. Коркмасова, 11',
        'distance': '0.35 km',
        'chargePointId': 'CP1', // Уникальный ID
        'available': '3/3',
        'time': '⏰ 24/7',
        'rating': 4.8,
        'status': [Colors.green, Colors.green, Colors.green],
        'favorite': false,
        'connectors': [
          {'type': 'CCS Type 2', 'power': 'До 150 кВт', 'price': '12 ₽/кВт·ч'},
          {'type': 'CHAdeMO', 'power': 'До 50 кВт', 'price': '10 ₽/кВт·ч'},
          {'type': 'Type 2 AC', 'power': 'До 22 кВт', 'price': '8 ₽/кВт·ч'},
        ],
      },
      {
        'name': 'A3C ULTRA HL DC240 #3',
        'address':
            'Республика Дагестан, г. Махачкала, проспект Имама Шамиля, 9А',
        'distance': '1.52 km',
        'chargePointId': 'CP2', // Уникальный ID
        'available': '3/3',
        'time': '⏰ 24/7',
        'rating': 4.5,
        'status': [Colors.green, Colors.green, Colors.green],
        'favorite': false,
        'connectors': [
          {'type': 'CCS Type 2', 'power': 'До 150 кВт', 'price': '12 ₽/кВт·ч'},
          {'type': 'CHAdeMO', 'power': 'До 50 кВт', 'price': '10 ₽/кВт·ч'},
          {'type': 'Type 2 AC', 'power': 'До 22 кВт', 'price': '8 ₽/кВт·ч'},
        ],
      },
      {
        'name': 'A3C ULTRA HL DC 150 kBt #2',
        'address': 'Республика Дагестан, Махачкала, проспект Имама Шамиля, 9А',
        'distance': '1.53 km',
        'chargePointId': 'CP3', // Уникальный ID
        'available': '2/3',
        'time': '⏰ 24/7',
        'rating': 4.6,
        'status': [Colors.orange, Colors.green, Colors.green],
        'favorite': false,
        'connectors': [
          {'type': 'CCS Type 2', 'power': 'До 150 кВт', 'price': '12 ₽/кВт·ч'},
          {'type': 'CHAdeMO', 'power': 'До 50 кВт', 'price': '10 ₽/кВт·ч'},
          {'type': 'Type 2 AC', 'power': 'До 22 кВт', 'price': '8 ₽/кВт·ч'},
        ],
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final chargePointId = station['chargePointId'] ?? 'CP1';
        return Container(
          margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setModalState) {
                        return FractionallySizedBox(
                          heightFactor: 0.8,
                          child: Column(
                            children: [
                              // Верхняя панель (твой оригинальный код)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                              // Название и рейтинг
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        station['name'] ?? 'Неизвестно',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.yellow[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (station['rating'] ?? 0.0).toString(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Адрес
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        station['address'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Чипы
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(
                                      label: Text(station['available'] ?? ''),
                                      backgroundColor: Colors.green[100],
                                    ),
                                    Chip(
                                      label: Text(station['distance'] ?? ''),
                                      backgroundColor: Colors.grey[200],
                                    ),
                                    Chip(
                                      label: Text(station['time'] ?? ''),
                                      backgroundColor: Colors.grey[200],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: const Text(
                                  'Доступные разъёмы',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount:
                                      (station['connectors'] as List?)
                                          ?.length ??
                                      0,
                                  itemBuilder: (context, connIndex) {
                                    final connector =
                                        station['connectors'][connIndex];
                                    final connectorId = connIndex + 1;
                                    // Чтение из провайдера (глобальное, по chargePointId)
                                    final savedStatus =
                                        provider
                                            .stations[chargePointId]
                                            ?.connectors[connectorId]
                                            ?.status ??
                                        connector['status'] ??
                                        'Доступен';
                                    final savedColor =
                                        provider
                                            .stations[chargePointId]
                                            ?.connectors[connectorId]
                                            ?.statusColor ??
                                        connector['status_color'] ??
                                        Colors.green;
                                    final isAvailable =
                                        savedStatus == 'Доступен';

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.bolt,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      connector['type'] ?? '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                    Text(
                                                      connector['power'] ?? '',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    connector['price'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          savedColor, // Из провайдера
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      savedStatus, // Из провайдера
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () async {
                                              try {
                                                if (isAvailable) {
                                                  await OcppService.remoteStart(
                                                    chargePointId,
                                                    connectorId,
                                                    'TAG123',
                                                  );
                                                  provider
                                                      .updateConnectorStatus(
                                                        chargePointId,
                                                        connectorId,
                                                        'Зарядка',
                                                        Colors.blue,
                                                      );
                                                  setModalState(() {});
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Зарядка начата',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  await OcppService.remoteStop(
                                                    chargePointId,
                                                  );
                                                  provider.resetConnectorStatus(
                                                    chargePointId,
                                                    connectorId,
                                                  );
                                                  setModalState(() {});
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Зарядка остановлена',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Ошибка: $e'),
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isAvailable
                                                  ? Colors.green
                                                  : Colors.red,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(
                                                double.infinity,
                                                48,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                            ),
                                            child: Text(
                                              isAvailable
                                                  ? 'Начать зарядку'
                                                  : 'Остановить зарядку',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
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
                      },
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            station['name'] ?? 'Неизвестно',
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
                            station['available'] ?? '',
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
                      station['address'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            station['distance'] ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.yellow[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text((station['rating'] ?? 0.0).toString()),
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
                                  station['favorite'] == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: const Color.fromARGB(
                                    255,
                                    23,
                                    108,
                                    255,
                                  ),
                                  size: 20,
                                ),
                                onPressed: () {},
                              ),
                              Flexible(
                                child: Text(
                                  station['id'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children:
                                    (station['status'] as List<Color>? ?? [])
                                        .map<Widget>(
                                          (color) => Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: color,
                                          ),
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
                      children: (station['connectors'] as List? ?? [])
                          .map<Widget>(
                            (conn) => Chip(
                              label: Text(conn['type'] ?? ''),
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
      },
    );
  }
}
