import 'package:flutter/material.dart';

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
    // Сохранённые карточки станций из вашего предыдущего кода, адаптированные под структуру
    final List<Map<String, dynamic>> stations = [
      {
        'name': 'Кинотеатр "Октябрь" DC150',
        'address': 'Республика Дагестан, Махачкала, ул. Коркмасова, 11',
        'distance': '0.35 km',
        // 'id': '#8312',
        'available': '3/3', // Адаптировано на основе status (все green)
        'time': '⏰ 24/7', // Добавлено для соответствия стилю
        'rating': 4.8, // Добавлено для соответствия стилю
        'status': [
          Colors.green,
          Colors.green,
          Colors.green,
        ], // Оригинальное поле
        'favorite': false,
        'connectors': [
          {
            'type': 'CCS Type 2',
            'power': 'До 150 кВт',
            'price': '12 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
          {
            'type': 'CHAdeMO',
            'power': 'До 50 кВт',
            'price': '10 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
          {
            'type': 'Type 2 AC',
            'power': 'До 22 кВт',
            'price': '8 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
        ],
      },
      {
        'name': 'A3C ULTRA HL DC240 #3',
        'address':
            'Республика Дагестан, г. Махачкала, проспект Имама Шамиля, 9А',
        'distance': '1.52 km',
        // 'id': '#8034',
        'available': '3/3', // Адаптировано на основе status (все green)
        'time': '⏰ 24/7',
        'rating': 4.5,
        'status': [
          Colors.green,
          Colors.green,
          Colors.green,
        ], // Оригинальное поле
        'favorite': false,
        'connectors': [
          {
            'type': 'CCS Type 2',
            'power': 'До 150 кВт',
            'price': '12 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
          {
            'type': 'CHAdeMO',
            'power': 'До 50 кВт',
            'price': '10 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
          {
            'type': 'Type 2 AC',
            'power': 'До 22 кВт',
            'price': '8 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
        ],
      },
      {
        'name': 'A3C ULTRA HL DC 150 kBt #2',
        'address': 'Республика Дагестан, Махачкала, проспект Имама Шамиля, 9А',
        'distance': '1.53 km',
        // 'id': '#8347',
        'available': '2/3', // Адаптировано на основе status (2 green, 1 orange)
        'time': '⏰ 24/7',
        'rating': 4.6,
        'status': [
          Colors.orange,
          Colors.green,
          Colors.green,
        ], // Оригинальное поле
        'favorite': false,
        'connectors': [
          {
            'type': 'CCS Type 2',
            'power': 'До 150 кВт',
            'price': '12 ₽/кВт·ч',
            'status': 'Занят',
            'status_color': Colors.orange,
          },
          {
            'type': 'CHAdeMO',
            'power': 'До 50 кВт',
            'price': '10 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
          {
            'type': 'Type 2 AC',
            'power': 'До 22 кВт',
            'price': '8 ₽/кВт·ч',
            'status': 'Доступен',
            'status_color': Colors.green,
          },
        ],
      },
      // Можно добавить больше станций
    ];

    return Container(
      child: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (BuildContext context) {
                      return FractionallySizedBox(
                        heightFactor: 0.8,
                        child: Column(
                          children: [
                            // Верхняя панель
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
                                    icon: Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.more_vert),
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
                                      style: TextStyle(
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
                                      SizedBox(width: 4),
                                      Text(
                                        (station['rating'] ?? 0.0).toString(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
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
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      station['address'] ?? '',
                                      style: TextStyle(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
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
                            SizedBox(height: 16),
                            // Доступные разъёмы
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'Доступные разъемы',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount:
                                    (station['connectors'] as List?)?.length ??
                                    0,
                                itemBuilder: (context, connIndex) {
                                  final connector =
                                      station['connectors'][connIndex];
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
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.bolt,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    connector['type'] ?? '',
                                                    style: TextStyle(
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
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        connector['status_color'] ??
                                                        Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    connector['status'] ?? '',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            minimumSize: Size(
                                              double.infinity,
                                              48,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: Text(
                                            'Начать зарядку',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Кнопка Построить маршрут
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  minimumSize: Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              station['available'] ?? '',
                              style: TextStyle(
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
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
                              SizedBox(width: 4),
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
                                    color: Color.fromARGB(255, 23, 108, 255),
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
      ),
    );
  }
}
