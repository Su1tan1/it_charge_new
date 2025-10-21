import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Панель поиска
        Container(
          padding: _searchPadding,
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
          child: _isMapMode
              ? _buildMapView()
              : Consumer<StationProvider>(
                  builder: (context, provider, child) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        try {
                          await provider.fetchStations();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка обновления: $e')),
                          );
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
                          : _buildListScreen(context, provider),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        _buildBottomButtons(),
        const SizedBox(height: 10),
      ],
    );
  }

  //Кнопки переключения карта/список
  Widget _buildToggleButton(
    String label,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF00C6A7), Color(0xFF70E000)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[300]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(8), // настроить под ваш дизайн
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // прозрачный фон
          shadowColor: Colors.transparent, // убрать тень
          foregroundColor: isActive
              ? Colors.white
              : Colors.black87, // цвет текста
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

  // Построение карты
  Widget _buildMapView() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: const Stack(children: [Placeholder()]),
    );
  }

  //Список станций
  Widget _buildListScreen(BuildContext context, StationProvider provider) {
    final stations = provider.stations;
    debugPrint(provider.isLoading.toString());
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
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton(Icons.location_on, '5', 'Рядом', Colors.blue[400]!),
          _buildButton(
            Icons.fiber_manual_record,
            '12',
            'Доступно',
            Colors.green[400]!,
          ),
          _buildButton(Icons.arrow_forward, '0.5', 'KM', Colors.orange[400]!),
        ],
      ),
    );
  }

  //Построение нижних кнопок
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
    final provider = this.provider;
    final station = this.station;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StationModal(
        station: station,
        chargePointId: chargePointId,
        provider: provider,
      ),
    );
  }
}

// Модалка (Bottom sheet)
class _StationModal extends StatefulWidget {
  final Station station;
  final String chargePointId;
  final StationProvider provider;

  const _StationModal({
    required this.station,
    required this.chargePointId,
    required this.provider,
  });

  @override
  State<_StationModal> createState() => _StationModalState();
}

class _StationModalState extends State<_StationModal> {
  @override
  Widget build(BuildContext context) {
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
                    widget.station.name.isNotEmpty
                        ? widget.station.name
                        : 'Неизвестно',
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
                    Text((widget.station.rating).toString()),
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
                    widget.station.address,
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
                  label: Text(widget.station.available),
                  backgroundColor: Colors.green[100],
                ),
                Chip(
                  label: Text(widget.station.distance),
                  backgroundColor: Colors.grey[200],
                ),
                Chip(
                  label: Text(widget.station.time),
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
          Expanded(child: _buildConnectorsList(context)),
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
  Widget _buildConnectorsList(BuildContext context) {
    final connectors = widget.station.connectors;
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
                      station: widget.station,
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
