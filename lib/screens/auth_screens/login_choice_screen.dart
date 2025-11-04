import 'package:flutter/material.dart';

class LoginChoiceScreen extends StatelessWidget {
  const LoginChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color gradientStart = Color(0xFF00C6A7);
    const Color gradientEnd = Color(0xFF70E000);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientStart.withAlpha((255 * 0.1).toInt()),
              gradientEnd.withAlpha((255 * 0.05).toInt()),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип/Брендинг
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradientStart, gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.electric_car,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'IT Charge',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Зарядные станции',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 60),
                // Заголовок
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Выберите способ входа',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Кнопка по телефону
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [gradientStart, gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradientStart.withAlpha((255 * 0.3).toInt()),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/phone'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_in_talk,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'По номеру телефона',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Кнопка по почте
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: gradientStart, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/email'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mail_outline,
                                color: gradientStart,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'По почте и паролю',
                                style: TextStyle(
                                  color: gradientStart,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
