// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart'; // Базовые виджеты
import '../../services/auth_service.dart'; // Импорт сервиса (создадим на шаге 3)

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  // Stateful — для динамики
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState(); // Создает состояние
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  // Контроллер для поля ввода — управляет текстом
  final _phoneController = TextEditingController();

  // Ключ для формы — для валидации
  final _formKey = GlobalKey<FormState>();

  // Флаг загрузки — чтобы кнопка не кликалась во время отправки
  bool _isLoading = false;

  static const Color _gradientStart = Color(0xFF00C6A7);
  static const Color _gradientEnd = Color(0xFF70E000);

  // Функция отправки OTP (кода)
  Future<void> _sendOtp() async {
    // Проверяем форму на ошибки
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // Показываем загрузку
      try {
        // Вызываем сервис (создадим позже)
        await AuthService.sendOtp(_phoneController.text);
        // Переходим на экран OTP, передавая номер
        Navigator.pushNamed(context, '/otp', arguments: _phoneController.text);
      } catch (e) {
        // Показываем ошибку как уведомление внизу экрана
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false); // Скрываем загрузку
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Строит UI
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Вход через телефон',
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
                    child: Icon(
                      Icons.phone_in_talk,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),
                  // Заголовок
                  Text(
                    'Вход в аккаунт',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Описание
                  Text(
                    'Введите ваш номер телефона,\nи мы отправим вам код подтверждения',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 40),
                  // Форма
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Поле ввода номера
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  (255 * 0.05).toInt(),
                                ),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Номер телефона',
                              prefixIcon: Icon(
                                Icons.phone,
                                color: _gradientStart,
                              ),
                              prefixText: '+  ',
                              prefixStyle: TextStyle(
                                color: _gradientStart,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              hintText: '7 999 000 00 00',
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите номер телефона';
                              }
                              if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                                return 'Номер должен содержать 10-15 цифр';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 30),
                        // Кнопка отправки
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
                                color: _gradientStart.withAlpha(
                                  (255 * 0.4).toInt(),
                                ),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _sendOtp,
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Отправить код',
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
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Информация о конфиденциальности
                  Text(
                    'Продолжая, вы соглашаетесь с нашей\nПолитикой конфиденциальности',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
    // Очистка памяти при закрытии экрана
    _phoneController.dispose();
    super.dispose();
  }
}
