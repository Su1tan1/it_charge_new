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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      } finally {
        setState(() => _isLoading = false); // Скрываем загрузку
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Строит UI
    return Scaffold(
      // Основной каркас экрана
      appBar: AppBar(title: Text('Ввод номера телефона')), // Верхняя панель
      body: Padding(
        // Отступы
        padding: EdgeInsets.all(16.0), // 16px со всех сторон
        child: Form(
          // Форма для валидации
          key: _formKey,
          child: Column(
            // Вертикальный список
            mainAxisAlignment: MainAxisAlignment.center, // По центру экрана
            children: [
              // Поле ввода
              TextFormField(
                controller: _phoneController, // Связь с контроллером
                keyboardType: TextInputType.phone, // Клавиатура с цифрами
                decoration: InputDecoration(
                  // Стиль поля
                  labelText: 'Номер телефона (с кодом страны, напр. +7)',
                  prefixText: '+', // Плюс в начале
                  border: OutlineInputBorder(), // Рамка
                ),
                validator: (value) {
                  // Проверка при отправке
                  if (value == null || value.isEmpty) {
                    return 'Введите номер'; // Обязательное поле
                  }
                  if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                    // Регулярка для цифр 10-15
                    return 'Неверный формат (пример, +7999-***-**-**)';
                  }
                  return null; // OK
                },
              ),
              SizedBox(height: 20), // Пробел
              // Кнопка
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _sendOtp, // Отключаем при загрузке
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white) // Спиннер
                    : Text('Отправить SMS'), // Текст
              ),
            ],
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
