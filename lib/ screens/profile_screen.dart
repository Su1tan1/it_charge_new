import 'package:firebase_auth/firebase_auth.dart';
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Если пользователь не авторизован, показываем placeholder или перенаправляем на логин
      return const Center(
        child: CircularProgressIndicator(), // Или кнопку входа
      );
    }

    final initials = user.displayName?.isNotEmpty == true
        ? user.displayName!
              .split(' ')
              .map((name) => name[0].toUpperCase())
              .take(2)
              .join()
        : user.email?.substring(0, 1).toUpperCase() ?? 'U';

    return Scaffold(
      // backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () {
          //       // Логика входа (подключите к auth API позже)
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.blueAccent,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //     ),
          //     child: const Text('Войти', style: TextStyle(color: Colors.white)),
          //   ),
          // ),
          _buildProfileHeader(initials, user),

          _buildBalance(),
          // Добавьте эти виджеты в body Column после BalanceCard, перед Expanded ListView.

          // Раздел способов оплаты
          const SizedBox(height: 24),
          _buildPays(),

          // Раздел избранных станций
          const SizedBox(height: 24),
          _buildFavoritesStations(),
          const SizedBox(height: 16), // Для отступа перед следующим разделом
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Прочее',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text(
                    'Пользовательское соглашение',
                    style: TextStyle(color: Colors.black),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    color: Colors.orange,
                  ),
                  onTap: () {
                    // Переход на страницу соглашения
                  },
                ),
                ListTile(
                  title: const Text(
                    'Правила зарядки',
                    style: TextStyle(color: Colors.black),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    color: Colors.orange,
                  ),
                  onTap: () {
                    // Переход
                  },
                ),
                ListTile(
                  title: const Text(
                    'Политика конфиденциальности',
                    style: TextStyle(color: Colors.black),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    color: Colors.orange,
                  ),
                  onTap: () {
                    // Переход
                  },
                ),
                ListTile(
                  title: const Text(
                    'Служба поддержки',
                    style: TextStyle(color: Colors.black),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    color: Colors.orange,
                  ),
                  onTap: () {
                    // Переход
                  },
                ),
                ListTile(
                  title: const Text(
                    'Платежи',
                    style: TextStyle(color: Colors.black),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    color: Colors.orange,
                  ),
                  onTap: () {
                    // Переход
                  },
                ),
                SwitchListTile(
                  title: const Text(
                    'Темная тема',
                    style: TextStyle(color: Colors.black),
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
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Версия 5.21',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildFavoritesStations() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Избранные станции',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Станция 1
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ТСЛ Мера Белая Дача',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '0.5 км • 3 мин',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Станция 2
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ларковская ОЦС Лентра',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '1.2 км • 2 мин',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildPays() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Способы оплаты',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Логика добавления способа оплаты
                },
                child: const CircleAvatar(
                  radius: 16,
                  // backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(Icons.add, color: Colors.blue, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Карта
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.grey),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '**** **** ****',
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text(
                          '4242',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Apple Pay
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, color: Colors.blue),
                    SizedBox(width: 12),
                    Text(
                      'Apple Pay',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildBalance() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Баланс',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // Логика пополнения
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Пополнить',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '2450.00 ₽',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildProfileHeader(String initials, User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Без имени',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.email ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Логика открытия настроек
              },
              icon: const Icon(Icons.settings, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
