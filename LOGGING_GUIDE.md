# Справка по логированию (Logging Guide)

## Формат логов

Все логи используют emoji префиксы для быстрой идентификации:

- **✅** - Успешная операция (с указанием источника WS/HTTP)
- **⚠️** - Предупреждение, fallback или переход на другой канал
- **❌** - Критическая ошибка
- **⏱️** - Timeout события
- **ℹ️** - Информационные сообщения (редко)

## Примеры логов при загрузке станций

### Успешная загрузка через WebSocket:
```
✅ WS: 15 станций
```

### Успешная загрузка через HTTP (fallback):
```
⏱️ WS timeout → HTTP
✅ HTTP: 15 станций
```

### Ошибка WebSocket с fallback:
```
⚠️ WS: Parse error occurred... → HTTP
✅ HTTP: 15 станций
```

## Примеры логов для операций

### Запрос данных:
- `✅ WS getStations` - успех через WebSocket
- `✅ HTTP getRecentTransactions` - успех через HTTP
- `⚠️ WS getConnectorStatus → HTTP` - перешли на HTTP
- `❌ WS startCharging: timeout` - ошибка WebSocket

## Ограничение длины логов

Длинные сообщения об ошибках ограничены до 40-50 символов с суффиксом `...`:

```
❌ WS: SocketException: Network unreachable... → HTTP
```

Вместо полного:
```
❌ WS: SocketException: Network is unreachable (os error 101), address = 176.88.248.139, port = 8081
```

## Где найти логи

- **station_provider.dart** - логи загрузки станций и fallback логика
- **ocpp_service.dart** - логи API запросов (getStations, startCharging и т.д.)
- **csms_client.dart** - логи WebSocket подключения и heartbeat

## Отключение логов (если нужно)

Добавить в `main.dart`:
```dart
if (kReleaseMode) {
  debugPrint = (_) {};
}
```

## Типовые последовательности логов

### Обычная сессия:
```
✅ WS: 12 станций
✅ WS getConnectorStatus
✅ WS startCharging
```

### С timeout на WebSocket:
```
⏱️ WS timeout → HTTP
✅ HTTP: 12 станций
⚠️ WS getConnectorStatus → HTTP
✅ HTTP getConnectorStatus
```

### С reconnect:
```
❌ WS connect: Connection refused...
⚠️ Переподключение 1: ошибка
✅ WS auth успешна
✅ WS: 12 станций
```
