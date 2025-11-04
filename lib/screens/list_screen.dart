import 'package:flutter/material.dart';

class ListScreen extends StatelessWidget {
  ListScreen({super.key});

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
      'address': 'Республика Дагестан, г. Махачкала, проспект Имама Шамиля, 9А',
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
    // Добавьте остальные по аналогии из скриншота
    // Для API: используйте FutureBuilder с http.get для загрузки списка
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Зарядные станции',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск (название или адрес)',
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: const Icon(Icons.filter_list, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    station['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    station['address'],
                    style: const TextStyle(color: Colors.orange),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          station['favorite']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          // Логика избранного
                        },
                      ),
                      Text(
                        station['distance'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        station['id'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: station['status']
                            .map<Widget>(
                              (color) =>
                                  Icon(Icons.circle, size: 8, color: color),
                            )
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.orange),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
