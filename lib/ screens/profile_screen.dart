import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkThemeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Мой профиль', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Текущий баланс:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                'об оплате',
                style: TextStyle(color: Colors.orange, fontSize: 16),
              ),
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '0,00 ₽',
            style: TextStyle(
              color: Colors.red,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Статус профиля:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Нужна авторизация',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Логика входа (подключите к auth API позже)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Войти', style: TextStyle(color: Colors.black)),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Прочее',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text(
                  'Пользовательское соглашение',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.orange),
                onTap: () {
                  // Переход на страницу соглашения
                },
              ),
              ListTile(
                title: const Text(
                  'Правила зарядки',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.orange),
                onTap: () {
                  // Переход
                },
              ),
              ListTile(
                title: const Text(
                  'Политика конфиденциальности',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.orange),
                onTap: () {
                  // Переход
                },
              ),
              ListTile(
                title: const Text(
                  'Служба поддержки',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.orange),
                onTap: () {
                  // Переход
                },
              ),
              ListTile(
                title: const Text(
                  'Платежи',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.orange),
                onTap: () {
                  // Переход
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Темная тема',
                  style: TextStyle(color: Colors.white),
                ),
                value: _darkThemeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkThemeEnabled = value;
                    // Логика смены темы (используйте ThemeProvider)
                  });
                },
                activeColor: Colors.orange,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Логика входа
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Войти',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Версия 5.21',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
