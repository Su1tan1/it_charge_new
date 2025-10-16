import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;

  // Общий хелпер для ошибок
  static Exception _handleError(dynamic e) => Exception('$e');

  // Отправка OTP
  static Future<void> sendOtp(String phoneNumber) async {
    final fullNumber = '+${phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';

    await _auth.verifyPhoneNumber(
      phoneNumber: fullNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw _handleError('Ошибка верификации: ${e.message ?? 'Неизвестно'}');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Верификация OTP
  static Future<UserCredential?> verifyOtp(String otp) async {
    if (_verificationId == null) throw Exception('Нет ID верификации');
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    return await _auth
        .signInWithCredential(credential)
        .catchError(_handleError);
  }

  // Выход
  static Future<void> signOut() async {
    await _auth.signOut().catchError(_handleError);
  }

  // Регистрация по email/password
  static Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .catchError(_handleError);
  }

  // Логин по email/password
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .catchError(_handleError);
  }

  // Отправка email-верификации
  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) {
      throw Exception('Пользователь не залогинен или email уже verified');
    }
    await user.sendEmailVerification().catchError(_handleError);
  }

  // Проверка verified email
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Сброс пароля по email
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email).catchError(_handleError);
  }

  // Перезагрузка пользователя
  static Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не залогинен');
    await user.reload().catchError(_handleError);
    return _auth.currentUser!.emailVerified;
  }

  // Текущий пользователь
  static User? get currentUser => _auth.currentUser;

  // Поток изменений auth
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
