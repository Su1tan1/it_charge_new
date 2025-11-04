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
  bool _isPasswordVisible = false;

  static const Color _gradientStart = Color(0xFF00C6A7);
  static const Color _gradientEnd = Color(0xFF70E000);

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _isLogin ? 'Вход в аккаунт' : 'Создание аккаунта',
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email поле
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
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.mail_outline,
                                color: _gradientStart,
                              ),
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
                            validator: (value) =>
                                value == null ||
                                    !RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)
                                ? 'Неверный email'
                                : null,
                          ),
                        ),
                        SizedBox(height: 20),
                        // Пароль поле
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
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Пароль',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: _gradientStart,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _gradientStart,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _isPasswordVisible =
                                        !_isPasswordVisible,
                                  );
                                },
                              ),
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
                            validator: (value) =>
                                value == null || value.length < 6
                                ? 'Пароль минимум 6 символов'
                                : null,
                          ),
                        ),
                        SizedBox(height: 30),
                        // Кнопка входа/регистрации
                        Container(
                          width: 200,
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
                              onTap: _isLoading ? null : _authAction,
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
                                        _isLogin
                                            ? 'Войти'
                                            : 'Зарегистрироваться',
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
                        SizedBox(height: 16),
                        // Забыли пароль
                        if (_isLogin)
                          TextButton(
                            onPressed: () async {
                              if (_emailController.text.isNotEmpty) {
                                await AuthService.sendPasswordResetEmail(
                                  _emailController.text,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ссылка на сброс отправлена'),
                                    backgroundColor: _gradientStart,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Забыли пароль?',
                              style: TextStyle(color: _gradientStart),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Переключение между логином и регистрацией
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Нет аккаунта? ' : 'Есть аккаунт? ',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _isLogin = !_isLogin);
                        },
                        child: Text(
                          _isLogin ? 'Зарегистрироваться' : 'Войти',
                          style: TextStyle(
                            color: _gradientStart,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Сообщение об успешной регистрации
                  if (_isRegistered) ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Аккаунт создан успешно!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Письмо подтверждения отправлено на ${_emailController.text}. Проверьте почту.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_gradientStart, _gradientEnd],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  try {
                                    await AuthService.reloadUser();
                                    if (AuthService
                                            .currentUser
                                            ?.emailVerified ==
                                        true) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/home',
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Email ещё не подтверждён',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ошибка: $e')),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Center(
                                  child: Text(
                                    'Проверить подтверждение',
                                    style: TextStyle(
                                      color: Colors.white,
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
                  ],
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
