// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Импорт сервиса

class OtpScreen extends StatefulWidget {
  final String phoneNumber; // Номер из предыдущего экрана
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required verificationId,
  });

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Здесь можно добавить таймер для resend (позже)
  }

  // Верификация при вводе 6 цифр
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return; // Ждем 6 символов
    setState(() => _isLoading = true);
    try {
      await AuthService.verifyOtp(_otpController.text); // Вызов сервиса
      // Успех: идем на home
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Код из SMS')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Код отправлен на ${widget.phoneNumber}'), // Показываем номер
            SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6, // Только 6 цифр
              decoration: InputDecoration(
                labelText: 'Введите 6-значный код',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  _verifyOtp(), // Срабатывает при каждом вводе
            ),
            if (_isLoading) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
