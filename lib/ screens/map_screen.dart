import 'package:flutter/material.dart';

import 'list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isMapMode = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 10),
          // Elevated Buttons for Map/List toggle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isMapMode = true;
                      });
                      print('Выбран: Карта');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMapMode
                          ? Colors.black
                          : Colors.grey[200],
                      foregroundColor: _isMapMode ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                    ),
                    child: Text('Карта'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isMapMode = false;
                      });
                      print('Выбран: Список');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isMapMode
                          ? Colors.black
                          : Colors.grey[200],
                      foregroundColor: !_isMapMode
                          ? Colors.white
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15), // Лёгкое заострение
                          bottomRight: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                          topLeft: Radius.circular(15),
                        ),
                      ),
                    ),
                    child: Text('Список'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isMapMode
                ? Container(
                    color: Color(0xFFF5F7FA), // Фон карты
                    child: Stack(
                      children: [
                        Placeholder(), // Замена карты
                        // Имитация меток (синие круги с числами)
                        // Positioned(left: 100, top: 100, child: _buildMapMarker('2')),
                        // Positioned(left: 150, top: 150, child: _buildMapMarker('3')),
                        // Positioned(left: 200, top: 200, child: _buildMapMarker('1')),
                        // Positioned(left: 50, top: 250, child: _buildMapMarker('4')),
                      ],
                    ),
                  )
                : _buildListScreen(), // Показываем список при _isMapMode == false
          ),
          SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(
                  icon: Icons.location_on,
                  number: '5',
                  label: 'Рядом',
                  backgroundColor: Colors.blue[100]!,
                ),
                _buildButton(
                  icon: Icons.fiber_manual_record,
                  number: '12',
                  label: 'Доступно',
                  backgroundColor: Colors.green[100]!,
                ),
                _buildButton(
                  icon: Icons.arrow_forward,
                  number: '0.5',
                  label: 'KM',
                  backgroundColor: Colors.orange[100]!,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String number,
    required String label,
    required Color backgroundColor,
  }) {
    return TextButton(
      onPressed: () {
        // Add your onPressed logic here
      },
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                number,
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildListScreen() {
    // Статические данные (позже замените на API)
    final List<Map<String, dynamic>> stations = [
      {
        'name': 'Кинотеатр "Октябрь" DC150',
        'address': 'Республика Дагестан, Махачкала, ул. Коркмасова, 11',
        'distance': '0.35 km',
        'id': '#8312',
        'status': [Colors.green, Colors.green, Colors.green], // •••
        'favorite': false,
      },
      {
        'name': 'A3C ULTRA HL DC240 #3',
        'address':
            'Республика Дагестан, г. Махачкала, проспект Имама Шамиля, 9А',
        'distance': '1.52 km',
        'id': '#8034',
        'status': [Colors.green, Colors.green, Colors.green],
        'favorite': false,
      },
      {
        'name': 'A3C ULTRA HL DC 150 kBt #2',
        'address': 'Республика Дагестан, Махачкала, проспект Имама Шамиля, 9А',
        'distance': '1.53 km',
        'id': '#8347',
        'status': [Colors.orange, Colors.green, Colors.green],
        'favorite': false,
      },
      // Добавьте остальные по аналогии
    ];

    return Container(
      color: Colors.black, // Фон для списка
      child: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          return ElevatedButton(
            onPressed: () {
              // Логика при нажатии на кнопку (например, открыть детали станции)
              print('Выбрана станция: ${station['name']}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200], // Тёмный фон кнопки
              foregroundColor: Colors.black, // Цвет текста
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Закруглённые углы
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft, // Выравнивание слева
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  station['address'],
                  style: const TextStyle(color: Colors.orange, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            station['favorite']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.orange,
                            size: 20,
                          ),
                          onPressed: () {
                            // Логика избранного
                          },
                        ),
                        Text(station['distance']),
                        const SizedBox(width: 8),
                        Text(station['id']),
                        const SizedBox(width: 8),
                        Row(
                          children: station['status']
                              .map<Widget>(
                                (color) =>
                                    Icon(Icons.circle, size: 8, color: color),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.orange),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
