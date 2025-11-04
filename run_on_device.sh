#!/bin/bash

# Скрипт для запуска на физическом устройстве с исправлением типичных проблем

echo "🔍 Очистка кэша Xcode..."
rm -rf ~/Library/Developer/Xcode/DerivedData

echo "🔧 Очистка Flutter build..."
flutter clean

echo "📦 Получение зависимостей..."
flutter pub get

echo "🍎 Переустановка iOS pods..."
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

echo "🚀 Запуск на физическом устройстве..."
flutter run --release

echo "✅ Готово!"
