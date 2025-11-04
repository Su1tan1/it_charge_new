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

  static const Color _gradientStart = Color(0xFF00C6A7);
  static const Color _gradientEnd = Color(0xFF70E000);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Подтверждение номера',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _gradientStart.withAlpha((255 * 0.1).toInt()),
              _gradientEnd.withAlpha((255 * 0.05).toInt()),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 80),
                  // Иконка
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_gradientStart, _gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.message, size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 30),
                  // Заголовок
                  Text(
                    'Введите код подтверждения',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Описание
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Код отправлен на номер\n',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: widget.phoneNumber,
                          style: TextStyle(
                            color: _gradientStart,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  // Поле ввода OTP
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.05).toInt()),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '000000',
                        hintStyle: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _gradientStart,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _verifyOtp(),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Кнопка подтверждения
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_gradientStart, _gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _gradientStart.withAlpha((255 * 0.4).toInt()),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _verifyOtp,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Подтвердить',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Ссылка на повторную отправку
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Код отправлен повторно'),
                          backgroundColor: _gradientStart,
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Не получили код? ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: 'Отправить ещё раз',
                            style: TextStyle(
                              color: _gradientStart,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
