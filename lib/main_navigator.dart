// lib/widgets/main_navigator.dart
import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
import ' screens/history_screen.dart';
import ' screens/map_screen.dart';
import ' screens/profile_screen.dart'; // Для signOut в Profile

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int currentIndex = 0;
  final List<Widget> screens = [
    const MapScreen(), // Главная: дашборд зарядки
    const HistoryScreen(),
    const ProfileScreen(), // Профиль с кнопкой выхода
  ];
  final List<String> appBarTitles = const ['Карта', 'История', 'Профиль'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitles[currentIndex],
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: IndexedStack(
        // <-- Добавлено: Сохраняет состояние экранов при смене таба
        index: currentIndex,
        children: screens,
      ),
      backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (value) => setState(() => currentIndex = value),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            label: 'Карта',
            icon: Icon(Icons.map_outlined),
          ),
          BottomNavigationBarItem(
            label: 'История',
            icon: Icon(Icons.energy_savings_leaf_outlined),
          ),
          BottomNavigationBarItem(
            label: 'Профиль',
            icon: Icon(Icons.person_2_outlined),
          ),
        ],
      ),
    );
  }
}
