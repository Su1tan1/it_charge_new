// ignore_for_file: avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  _EmailAuthScreenState createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistered = false; // Флаг успеха регистрации
  bool _isLogin = true; // Toggle: true = логин, false = регистрация
  bool _isLoading = false;

  Future<void> _authAction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential? user;
        if (_isLogin) {
          user = await AuthService.signInWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
          );
          if (user != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Вход успешен!')));
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ); // <-- Редирект сразу для логина
          }
        } else {
          user = await AuthService.createUserWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
          );
          if (user != null) {
            await AuthService.sendEmailVerification(); // Отправляем письмо
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Аккаунт создан! Проверьте $_emailController.text для подтверждения.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
            _isRegistered = true;
            setState(() {});
          }
        }
      } on FirebaseAuthException catch (e) {
        // Твой switch для ошибок (email-already-in-use и т.д.)
        String errorMsg = 'Неизвестная ошибка';
        switch (e.code) {
          case 'email-already-in-use':
            errorMsg = 'Эта почта уже зарегистрирована. Перейдите к входу.';
            setState(() => _isLogin = true); // Авто-переключение
            break;
          case 'weak-password':
            errorMsg = 'Пароль слишком слабый (минимум 6 символов).';
            break;
          case 'invalid-email':
            errorMsg = 'Неверный формат email.';
            break;
          case 'user-not-found':
            errorMsg = 'Пользователь не найден. Проверьте email.';
            break;
          case 'wrong-password':
            errorMsg = 'Неверный пароль.';
            break;
          default:
            errorMsg = e.message ?? 'Неизвестная ошибка';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Неверный email или пароль')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Вход по почте' : 'Регистрация')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ||
                        !RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)
                    ? 'Неверный email'
                    : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'Пароль <6 символов'
                    : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _authAction,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
              ),
              if (_isRegistered) ...[
                SizedBox(height: 20),
                Text(
                  'Аккаунт создан! Проверьте ${_emailController.text} для подтверждения.',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await AuthService.reloadUser(); // Обновит verified
                      if (AuthService.currentUser?.emailVerified == true) {
                        Navigator.pushReplacementNamed(
                          context,
                          '/home',
                        ); // Теперь редирект
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Email ещё не подтверждён. Проверьте почту.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                    }
                  },
                  child: Text('Проверить подтверждение'),
                ),
              ],
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin
                      ? 'Нет аккаунта? Зарегистрироваться'
                      : 'Уже есть аккаунт? Войти',
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (_emailController.text.isNotEmpty) {
                    await AuthService.sendPasswordResetEmail(
                      _emailController.text,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ссылка на сброс отправлена')),
                    );
                  }
                },
                child: Text('Забыли пароль?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
