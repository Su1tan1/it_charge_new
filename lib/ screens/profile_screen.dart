// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'history_screen.dart';

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
      // Если пользователь не загружен — показать индикатор
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials = user.displayName?.isNotEmpty == true
        ? user.displayName!
              .split(' ')
              .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
              .where((s) => s.isNotEmpty)
              .take(2)
              .join()
        : (user.email?.isNotEmpty == true
              ? user.email!.substring(0, 1).toUpperCase()
              : 'U');

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildProfileHeader(initials, user),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildGradientBalance(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionCard('Платежи', [
                _buildSectionItem(Icons.credit_card, 'Способы оплаты', '2'),
                _buildSectionItem(Icons.history, 'История транзакций', null),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionCard('Избранное', [
                _buildSectionItem(
                  Icons.favorite_border,
                  'Избранные станции',
                  '5',
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionCard('Настройки', [
                _buildSectionItem(
                  Icons.notifications_none,
                  'Уведомления',
                  null,
                ),
                _buildSectionItem(Icons.settings, 'Настройки', null),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildOtherSection(),
            ),
            // const SizedBox(height: 24),
          ],
        ),
      ),
      // bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Аккаунт
  Widget _buildProfileHeader(String initials, User user) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              backgroundColor: const Color(0xFF1F2933),
              child: user.photoURL == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Без имени',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBalance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6A7), Color(0xFF70E000)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Баланс',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '₽2,450',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Row(
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('Пополнить', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> items) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1113),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSectionItem(IconData icon, String label, String? badge) {
    return InkWell(
      onTap: () {
        if (label == 'История транзакций') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
          return;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF111418),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00D3C0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B8A0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white)),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1113),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ElevatedButton(
          //   onPressed: () {},
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Colors.transparent,
          //     elevation: 0,
          //     padding: const EdgeInsets.symmetric(vertical: 8),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: const [
          //       Text(
          //         'Уведомления',
          //         style: TextStyle(color: Colors.white, fontSize: 16),
          //       ),
          //       Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Темная тема',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Switch(
                  value: _darkThemeEnabled,
                  onChanged: (v) => setState(() => _darkThemeEnabled = v),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              // выйти из аккаунта
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Выйти',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                Icon(Icons.exit_to_app, size: 16, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildBottomNav() {
  //   return Container(
  //     height: 72,
  //     decoration: BoxDecoration(
  //       color: Colors.black,
  //       boxShadow: [
  //         BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
  //       ],
  //     ),
  //     // child: Row(
  //     //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     //   children: [
  //     //     Column(
  //     //       mainAxisSize: MainAxisSize.min,
  //     //       children: [
  //     //         Icon(Icons.place, color: Colors.grey),
  //     //         const SizedBox(height: 4),
  //     //         Text('Карта', style: TextStyle(color: Colors.grey, fontSize: 12)),
  //     //       ],
  //     //     ),
  //     //     Column(
  //     //       mainAxisSize: MainAxisSize.min,
  //     //       children: [
  //     //         Icon(Icons.history, color: Colors.grey),
  //     //         const SizedBox(height: 4),
  //     //         Text(
  //     //           'История',
  //     //           style: TextStyle(color: Colors.grey, fontSize: 12),
  //     //         ),
  //     //       ],
  //     //     ),
  //     //     Container(
  //     //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     //       decoration: BoxDecoration(
  //     //         gradient: const LinearGradient(
  //     //           colors: [Color(0xFF00C6A7), Color(0xFF70E000)],
  //     //         ),
  //     //         borderRadius: BorderRadius.circular(16),
  //     //       ),
  //     //       child: Column(
  //     //         mainAxisSize: MainAxisSize.min,
  //     //         children: [
  //     //           const Icon(Icons.person, color: Colors.white),
  //     //           const SizedBox(height: 4),
  //     //           const Text(
  //     //             'Профиль',
  //     //             style: TextStyle(color: Colors.white, fontSize: 12),
  //     //           ),
  //     //         ],
  //     //       ),
  //     //     ),
  //     //   ],
  //     // ),
  //   );
  // }
}
