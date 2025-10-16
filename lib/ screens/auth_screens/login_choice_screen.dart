import 'package:flutter/material.dart';

class LoginChoiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('Выберите способ входа'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/phone'),
              icon: Icon(Icons.phone),
              label: Text('По номеру телефона'),
              style: ElevatedButton.styleFrom(minimumSize: Size(200, 50)),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/email'),
              icon: Icon(Icons.email),
              label: Text('По почте и паролю'),
              style: ElevatedButton.styleFrom(minimumSize: Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
