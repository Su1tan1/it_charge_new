import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:it_charge/main_navigator.dart';
// import 'package:it_charge/main_navigator.dart';
import ' screens/auth_screens/email_auth_screen.dart';
import ' screens/auth_screens/login_choice_screen.dart';
import ' screens/auth_screens/otp_screen.dart';
import ' screens/auth_screens/phone_auth_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Auth Demo',
      // Начальный маршрут — логин
      initialRoute: '/choice', // Стартуем с выбора
      routes: {
        '/choice': (context) => LoginChoiceScreen(), // Новый старт
        '/phone': (context) => PhoneAuthScreen(),
        '/email': (context) => EmailAuthScreen(),
        '/otp': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          return OtpScreen(
            phoneNumber: args?['phone'] ?? '',
            verificationId: args?['verificationId'] ?? '',
          );
        },
        '/home': (context) => MainNavigator(),
      },
    );
  }
}
