// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:it_charge/services/auth_service.dart';

import '../../main_navigator.dart';
import 'login_choice_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        print('Auth state: ${snapshot.connectionState}'); // Лог: waiting/active
        print('Has user: ${snapshot.hasData}'); // Лог: true/false на старте
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        User? user = snapshot.data;
        if (user != null) {
          print(
            'User email: ${user.email}, Verified: ${user.emailVerified}, Phone: ${user.phoneNumber}',
          ); // Лог статуса
          if (user.emailVerified || user.phoneNumber != null) {
            print('Redirect to MainNavigator'); // Лог редиректа
            return MainNavigator(); // <-- Сразу главный экран
          } else {
            // Не verified — экран ожидания
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Подтвердите email'),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await AuthService.sendEmailVerification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Email отправлено повторно'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                        }
                      },
                      child: Text('Отправить повторно'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await AuthService.reloadUser(); // Обновляем статус
                          // Stream обновится, редирект автоматом
                          print('Checked verification');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка проверки: $e')),
                          );
                        }
                      },
                      child: Text('Проверить email'),
                    ),
                    ElevatedButton(
                      onPressed: () => AuthService.signOut(),
                      child: Text('Выйти'),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        print('No user - to LoginChoice'); // Лог для не-залогиненного
        return LoginChoiceScreen(); // Выбор метода
      },
    );
  }
}
