# Руководство по новым API функциям

## 📋 Обзор изменений

Бэкенд перешел на микросервисную архитектуру с разными портами для разных сервисов.

### Новые порты:
- **WebSocket**: `4000` (было 8081)
- **Auth**: `5001`
- **Stations/Sites**: `6000`
- **Transactions**: `7001`
- **Notifications**: `8000`

---

## 🔌 1. WebSocket (Порт 4000)

### Исправление бесконечного переподключения:

**Было:**
```dart
ws://176.88.248.139:8081/mobile-client
```

**Стало:**
```dart
ws://176.88.248.139:4000/api
```

### Использование:
```dart
// Автоматически использует новый URL из Config.wsUrl
await CSMSClient.instance.connect();
```

---

## 🏢 2. Sites API - Группировка станций

### Новая концепция:
Станции теперь группируются по **локациям (Sites)**. Одна локация может содержать несколько станций.

### Модель Site:
```dart
class Site {
  String id;
  String name;
  String? address;
  double? latitude;
  double? longitude;
  List<String> stationIds;  // IDs станций
  int totalConnectors;
  int availableConnectors;
}
```

### Где применить:

#### A) **Экран списка станций** (`map_screen.dart`)
Добавить фильтр/группировку по локациям:

```dart
import 'package:it_charge/services/sites_service.dart';
import 'package:it_charge/models/site_model.dart';

// Загрузить локации
Future<void> _loadSites() async {
  try {
    final sites = await SitesService.getSites();
    setState(() {
      _sites = sites;
    });
  } catch (e) {
    debugPrint('Ошибка загрузки локаций: $e');
  }
}

// Отобразить станции по локациям
Widget _buildSiteGroup(Site site) {
  return ExpansionTile(
    title: Text(site.name),
    subtitle: Text('${site.availableConnectors}/${site.totalConnectors} доступно'),
    children: [
      // Показать только станции из site.stationIds
      ...stations.where((s) => site.stationIds.contains(s.id))
          .map((s) => StationCard(station: s))
    ],
  );
}
```

#### B) **Карта** (`map_screen.dart`)
Группировать маркеры по локациям:

```dart
// Создать кластерные маркеры для локаций
List<Marker> _createSiteMarkers(List<Site> sites) {
  return sites.map((site) {
    return Marker(
      point: LatLng(site.latitude!, site.longitude!),
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => _showSiteStations(site),
        child: Column(
          children: [
            Icon(Icons.location_on, color: Colors.blue, size: 40),
            Text(
              site.name,
              style: TextStyle(fontSize: 10, backgroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }).toList();
}
```

---

## 🔋 3. Stations API - Новые эндпоинты

### Remote Start:
**Было:**
```
POST /api/admin/remote-start-session
Body: { chargePointId, connectorId, idTag }
```

**Стало:**
```
POST /stations/{stationId}/remote-start
Body: { connectorId, idTag }
```

### Remote Stop:
**Было:**
```
POST /api/admin/remote-stop-session
Body: { transactionId, stationId }
```

**Стало:**
```
POST /stations/{stationId}/remote-stop
Body: { transactionId }
```

### Использование:
Автоматически - `OcppService` использует новые эндпоинты с fallback на старые.

---

## 📜 4. Transactions API - История зарядок

### Где применить:

#### A) **Экран истории** (новый экран `history_screen.dart`)

```dart
import 'package:it_charge/services/transactions_service.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaction> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await TransactionsService.getMyHistory(limit: 100);
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки истории: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final tx = _history[index];
        return ListTile(
          title: Text('${tx.stationName ?? 'Station'}'),
          subtitle: Text('${tx.energy ?? 0} kWh - ${tx.cost ?? 0} ₸'),
          trailing: Text(tx.status ?? 'Unknown'),
        );
      },
    );
  }
}
```

#### B) **Профиль пользователя**
Показать статистику:
```dart
Future<void> _loadStats() async {
  final history = await TransactionsService.getMyHistory(limit: 1000);
  
  final totalEnergy = history.fold<double>(
    0, (sum, tx) => sum + (tx.energy ?? 0)
  );
  
  final totalCost = history.fold<double>(
    0, (sum, tx) => sum + (tx.cost ?? 0)
  );
  
  setState(() {
    _stats = {
      'total_sessions': history.length,
      'total_energy': totalEnergy,
      'total_cost': totalCost,
    };
  });
}
```

---

## 🔔 5. Notifications API - Управление уведомлениями

### Где применить:

#### A) **Экран настроек** (`settings_screen.dart`)

```dart
import 'package:it_charge/services/notifications_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationPreferences? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await NotificationsService.getPreferences();
      setState(() {
        _prefs = prefs;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки настроек: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _updatePreferences() async {
    if (_prefs == null) return;
    
    try {
      await NotificationsService.updatePreferences(_prefs!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Настройки сохранены')),
      );
    } catch (e) {
      debugPrint('Ошибка сохранения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _prefs == null) return CircularProgressIndicator();
    
    return ListView(
      children: [
        SwitchListTile(
          title: Text('Push-уведомления'),
          value: _prefs!.pushNotifications,
          onChanged: (val) {
            setState(() {
              _prefs = NotificationPreferences(
                emailNotifications: _prefs!.emailNotifications,
                pushNotifications: val,
                smsNotifications: _prefs!.smsNotifications,
                chargingStarted: _prefs!.chargingStarted,
                chargingCompleted: _prefs!.chargingCompleted,
                chargingError: _prefs!.chargingError,
                lowBalance: _prefs!.lowBalance,
              );
            });
            _updatePreferences();
          },
        ),
        SwitchListTile(
          title: Text('Зарядка началась'),
          value: _prefs!.chargingStarted,
          onChanged: (val) {
            setState(() {
              _prefs = NotificationPreferences(
                emailNotifications: _prefs!.emailNotifications,
                pushNotifications: _prefs!.pushNotifications,
                smsNotifications: _prefs!.smsNotifications,
                chargingStarted: val,
                chargingCompleted: _prefs!.chargingCompleted,
                chargingError: _prefs!.chargingError,
                lowBalance: _prefs!.lowBalance,
              );
            });
            _updatePreferences();
          },
        ),
        // ... другие переключатели
      ],
    );
  }
}
```

#### B) **Экран уведомлений** (`notifications_screen.dart`)

```dart
class NotificationsHistoryScreen extends StatefulWidget {
  @override
  _NotificationsHistoryScreenState createState() => _NotificationsHistoryScreenState();
}

class _NotificationsHistoryScreenState extends State<NotificationsHistoryScreen> {
  List<NotificationHistory> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationsService.getHistory(limit: 50);
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки уведомлений: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        return ListTile(
          leading: Icon(
            notif.read ? Icons.mail_outline : Icons.mail,
            color: notif.read ? Colors.grey : Colors.blue,
          ),
          title: Text(
            notif.title,
            style: TextStyle(
              fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(notif.message),
          trailing: Text(
            _formatTime(notif.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}м назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    return '${diff.inDays}д назад';
  }
}
```

---

## 🎯 Приоритеты внедрения

### Немедленно (критично):
1. ✅ **WebSocket на порт 4000** - исправляет бесконечное переподключение
2. ✅ **Stations API на порт 6000** - основной функционал

### Высокий приоритет:
3. **Sites API** - улучшает UX группировкой станций
4. **Transactions History** - важная функция для пользователей

### Средний приоритет:
5. **Notifications Settings** - удобство, но не критично
6. **Notifications History** - nice-to-have

---

## 🔧 Тестирование

### 1. Проверка WebSocket:
```bash
# Консоль должна показать:
✅ WS auth успешна
✅ WS: 12 станций
```

### 2. Проверка Sites:
```dart
final sites = await SitesService.getSites();
print('Локаций: ${sites.length}');
```

### 3. Проверка History:
```dart
final history = await TransactionsService.getMyHistory();
print('Зарядок: ${history.length}');
```

### 4. Проверка Notifications:
```dart
final prefs = await NotificationsService.getPreferences();
print('Push: ${prefs.pushNotifications}');
```

---

## ⚠️ Важные замечания

1. **Обратная совместимость**: Все методы имеют fallback на старые эндпоинты
2. **Логирование**: Все новые сервисы используют компактные логи с emoji
3. **Timeout**: Все запросы имеют timeout 10 секунд
4. **Ошибки**: Длинные сообщения обрезаются до 40 символов

---

## 📱 Навигация

Добавить новые экраны в `main_navigator.dart`:

```dart
'/history': (context) => HistoryScreen(),
'/notifications': (context) => NotificationsHistoryScreen(),
'/notification-settings': (context) => NotificationSettingsScreen(),
```
