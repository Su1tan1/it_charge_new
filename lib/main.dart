import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:it_charge/main_navigator.dart';
import 'package:it_charge/providers/station_provider.dart';
import 'package:provider/provider.dart';
import ' screens/auth_screens/email_auth_screen.dart';
import ' screens/auth_screens/login_choice_screen.dart';
import ' screens/auth_screens/otp_screen.dart';
import ' screens/auth_screens/phone_auth_screen.dart'; // Re-add PhoneAuthScreen import
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:it_charge/services/csms_client.dart'; // Import CSMSClient

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  runApp(
    ChangeNotifierProvider(
      // Enable automatic fetch when app starts (single load, no polling)
      create: (context) => StationProvider(autoStart: true),
      child: const WebSocketInitializer(
        child: MyApp(),
      ), // Wrap MyApp with WebSocketInitializer
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Auth Demo',
      initialRoute: '/choice',
      routes: {
        '/choice': (context) => const LoginChoiceScreen(),
        '/phone': (context) => const PhoneAuthScreen(),
        '/email': (context) => const EmailAuthScreen(),
        '/otp': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          return OtpScreen(
            phoneNumber: args?['phone'] ?? '',
            verificationId: args?['verificationId'] ?? '',
          );
        },
        '/home': (context) => const MainNavigator(),
      },
    );
  }
}

// New widget to handle WebSocket lifecycle with app lifecycle awareness
class WebSocketInitializer extends StatefulWidget {
  final Widget child;
  const WebSocketInitializer({super.key, required this.child});

  @override
  State<WebSocketInitializer> createState() => _WebSocketInitializerState();
}

class _WebSocketInitializerState extends State<WebSocketInitializer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    try {
      await CSMSClient.instance.connect();
      debugPrint('WebSocket connected successfully in main.dart');
    } catch (e) {
      debugPrint('Failed to connect WebSocket in main.dart: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (!CSMSClient.instance.connected) {
          _initWebSocket();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        CSMSClient.instance.close();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CSMSClient.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
