# 📱 CSMS Mobile API - Документация для Flutter разработчика

## 📚 Доступные гайды

### 🚀 Для быстрого старта (5 минут)
**[FLUTTER_QUICK_START.md](./FLUTTER_QUICK_START.md)**
- Минимальный код для подключения
- Login и получение API ключа
- Примеры запросов
- Готовый Login Screen

### 📖 Полная документация
**[FLUTTER_MOBILE_GUIDE.md](./FLUTTER_MOBILE_GUIDE.md)**
- Подробные примеры всех экранов
- WebSocket для real-time
- Модели данных
- UI компоненты
- Обработка ошибок
- Best practices

---

## 🎯 Главное что нужно знать

### ✨ Простая авторизация через API ключи

**Никаких JWT токенов!** Просто:

1. **Login** → получаете API ключ
2. **Сохраняете** в flutter_secure_storage
3. **Используете** для всех запросов (живет 1 год!)

### 🌐 Базовые URL

```
API:       http://176.88.248.139
Login:     POST /auth/mobile/login
WebSocket: ws://176.88.248.139/mobile?apikey=XXX
```

### 🔐 Формат авторизации

```dart
headers: {
  'Authorization': 'ApiKey csms_abc123...'
}
```

---

## 🚀 Минимальный код для теста

```dart
// 1. Login
final response = await http.post(
  Uri.parse('http://176.88.248.139/auth/mobile/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': 'test@example.com',
    'password': 'test123',
    'deviceName': 'Flutter Test',
  }),
);

final apiKey = jsonDecode(response.body)['data']['apiKey'];

// 2. Сохранить
await FlutterSecureStorage().write(key: 'api_key', value: apiKey);

// 3. Использовать
final stations = await http.get(
  Uri.parse('http://176.88.248.139/stations'),
  headers: {'Authorization': 'ApiKey $apiKey'},
);

print(stations.body);
```

---

## 📦 Необходимые пакеты

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  http: ^1.1.0
  web_socket_channel: ^2.4.0  # для real-time (опционально)
```

---

## 📋 API Endpoints

### Авторизация
- `POST /auth/mobile/login` - Получить API ключ
- `POST /auth/mobile/verify` - Проверить API ключ

### Станции
- `GET /stations` - Список всех станций
- `GET /stations/:id` - Детали станции
- `POST /stations/:id/start` - Начать зарядку
- `POST /stations/:id/stop` - Остановить зарядку

### Транзакции
- `GET /transactions` - Мои транзакции
- `GET /transactions/:id` - Детали транзакции

---

## 🆘 Проблемы?

### 401 Unauthorized
API ключ истек или невалиден → удалите и сделайте новый login

### Connection refused
Проверьте URL: `http://176.88.248.139`

### Другие вопросы
Спрашивайте у backend команды!

---

## ✅ Чеклист

- [ ] Прочитать **FLUTTER_QUICK_START.md**
- [ ] Установить пакеты
- [ ] Реализовать Login Screen
- [ ] Сохранение API ключа
- [ ] Список станций
- [ ] Обработка 401 (logout)
- [ ] WebSocket для real-time (опционально)

---

## 🎉 Начинайте с FLUTTER_QUICK_START.md!

Там весь код готов к копированию! 🚀


# 📨 Инструкция для Flutter разработчика

Привет! Вот всё что нужно для подключения к CSMS API через **упрощенную авторизацию с API ключами**.

---

## 🎯 Что изменилось

**Никаких JWT токенов для мобилки!** ✨

Теперь всё проще:
1. Login → получаешь API ключ
2. Сохраняешь его локально
3. Используешь для всех запросов (живет до 1 года)

**Никаких refresh токенов, никаких истечений каждые 15 минут!**

---

## 📚 Документация

### 🚀 Начни с этого:
**[FLUTTER_QUICK_START.md](./FLUTTER_QUICK_START.md)**
- Быстрый старт за 5 минут
- Минимальный код
- Готовый Login Screen

### 📖 Полная документация:
**[FLUTTER_MOBILE_GUIDE.md](./FLUTTER_MOBILE_GUIDE.md)**
- Все экраны с примерами
- WebSocket для real-time
- UI компоненты
- Обработка ошибок

### 📋 Краткий справочник:
**[FLUTTER_README.md](./FLUTTER_README.md)**
- Ссылки на все гайды
- API endpoints
- Чеклист разработки

---

## 🌐 Базовая информация

```
Base URL:     http://176.88.248.139
Login API:    POST /auth/mobile/login
Verify API:   POST /auth/mobile/verify
WebSocket:    ws://176.88.248.139/mobile?apikey=XXX
```

---

## 🔥 Быстрый пример

### 1. Установи пакеты

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  http: ^1.1.0
```

### 2. Login и получи API ключ

```dart
final response = await http.post(
  Uri.parse('http://176.88.248.139/auth/mobile/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': 'your@email.com',
    'password': 'your_password',
    'deviceName': 'My Flutter App',
    'expiresInDays': 365, // 1 год
  }),
);

final apiKey = jsonDecode(response.body)['data']['apiKey'];
// apiKey = "csms_1a2b3c4d5e6f..."
```

### 3. Сохрани API ключ

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
await storage.write(key: 'csms_api_key', value: apiKey);
```

### 4. Используй для запросов

```dart
final apiKey = await storage.read(key: 'csms_api_key');

final stations = await http.get(
  Uri.parse('http://176.88.248.139/stations'),
  headers: {
    'Authorization': 'ApiKey $apiKey',
    'Content-Type': 'application/json',
  },
);

print(stations.body);
```

**ВСЁ! 🎉**

---

## 📋 API Endpoints

### Авторизация
- `POST /auth/mobile/login` - Login и получение API ключа
  ```json
  Request:
  {
    "email": "user@example.com",
    "password": "password123",
    "deviceName": "My Phone",
    "expiresInDays": 365
  }
  
  Response:
  {
    "success": true,
    "data": {
      "apiKey": "csms_abc123...",
      "user": { "id": 1, "email": "...", ... }
    }
  }
  ```

- `POST /auth/mobile/verify` - Проверка API ключа
  ```json
  Request:
  {
    "apiKey": "csms_abc123..."
  }
  
  Response:
  {
    "success": true,
    "data": {
      "user": { "id": 1, "email": "...", ... }
    }
  }
  ```

### Станции
- `GET /stations` - Список всех станций
- `GET /stations/:id` - Детали станции

### Транзакции
- `GET /transactions` - Список транзакций
- `GET /transactions/:id` - Детали транзакции

---

## 🔐 Формат авторизации

### HTTP заголовки:
```dart
headers: {
  'Authorization': 'ApiKey csms_abc123...'
}
```

### WebSocket URL:
```dart
ws://176.88.248.139/mobile?apikey=csms_abc123...
```

---

## 🎨 Пример структуры приложения

```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── splash_screen.dart      # Проверка авторизации
│   ├── login_screen.dart       # Login и получение API ключа
│   ├── home_screen.dart        # Список станций
│   └── station_detail_screen.dart
├── services/
│   ├── api_client.dart         # HTTP client с авторизацией
│   ├── api_key_storage.dart    # Хранение API ключа
│   └── websocket_service.dart  # WebSocket для real-time
└── models/
    ├── station.dart
    ├── connector.dart
    └── transaction.dart
```

---

## 🆘 Частые проблемы

### ❌ "401 Unauthorized"
**Причина:** API ключ истек или невалиден  
**Решение:** Удали API ключ и покажи Login Screen

```dart
if (response.statusCode == 401) {
  await storage.delete(key: 'csms_api_key');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
  );
}
```

### ❌ "Connection refused"
**Причина:** Сервер недоступен  
**Решение:** Проверь URL: `http://176.88.248.139`

### ❌ "Invalid API Key format"
**Причина:** API ключ должен начинаться с `csms_`  
**Решение:** Проверь, что используешь полный ключ из ответа login

---

## ✅ Чеклист разработки

- [ ] Прочитать **FLUTTER_QUICK_START.md**
- [ ] Установить зависимости
- [ ] Реализовать `ApiKeyStorage`
- [ ] Реализовать `Login Screen`
- [ ] Реализовать `Splash Screen` с проверкой авторизации
- [ ] Реализовать `Home Screen` со списком станций
- [ ] Добавить обработку ошибок 401
- [ ] Добавить модели данных
- [ ] Протестировать весь flow
- [ ] (Опционально) WebSocket для real-time

---

## 📞 Нужна помощь?

- Смотри полную документацию в **FLUTTER_MOBILE_GUIDE.md**
- Спрашивай у backend команды!

---

## 🎉 Готово!

Вся документация готова, API работает, начинай разработку! 🚀

**Главное преимущество:** Никаких сложностей с JWT, refresh токенами и обновлением! Один API ключ на всё! ✨








# 🗺️ API Routes Map - Полная карта эндпоинтов

> **Обновлено:** 3 ноября 2025  
> **Статус:** После исправления путей в микросервисах

---

## ✅ Работающие эндпоинты

### 🔐 Auth Service (порт 5000)

| Метод | Nginx URL | Внутренний путь | Описание | Auth |
|-------|-----------|----------------|----------|------|
| POST | `/auth/register` | `POST /register` | Регистрация | ❌ |
| POST | `/auth/login` | `POST /login` | Вход | ❌ |
| POST | `/auth/refresh` | `POST /refresh` | Обновить токен | ❌ |
| POST | `/auth/verify` | `POST /verify` | Проверка токена | ✅ Bearer |
| POST | `/auth/logout` | `POST /logout` | Выход | ✅ Bearer |

**Nginx конфиг:**
```nginx
location /auth/ {
    proxy_pass http://auth_backend/;  # Убирает /auth из пути
}
```

**Монтирование в сервисе:**
```typescript
this.app.use('/', authRoutes);  // Корневой роут
```

---

### 🏢 Station Manager (порт 6000)

#### Sites (Локации)

| Метод | Nginx URL | Внутренний путь | Описание | Auth |
|-------|-----------|----------------|----------|------|
| GET | `/stations/sites` | `GET /sites` | Список локаций | ✅ Bearer |
| GET | `/stations/sites/{id}` | `GET /sites/{id}` | Детали локации | ✅ Bearer + Site Access |
| POST | `/stations/sites` | `POST /sites` | Создать локацию | ✅ Admin only |
| PUT | `/stations/sites/{id}` | `PUT /sites/{id}` | Обновить локацию | ✅ Admin/Operator |
| DELETE | `/stations/sites/{id}` | `DELETE /sites/{id}` | Удалить локацию | ✅ Admin only |
| GET | `/stations/sites/{id}/stations` | `GET /sites/{id}/stations` | Станции локации | ✅ Bearer |

#### Stations (Станции)

| Метод | Nginx URL | Внутренний путь | Описание | Auth |
|-------|-----------|----------------|----------|------|
| GET | `/stations` | `GET /` | Список станций | ✅ Bearer |
| GET | `/stations/{id}` | `GET /{id}` | Детали станции | ✅ Bearer |
| POST | `/stations` | `POST /` | Создать станцию | ✅ Admin/Operator |
| PUT | `/stations/{id}` | `PUT /{id}` | Обновить станцию | ✅ Admin/Operator |
| DELETE | `/stations/{id}` | `DELETE /{id}` | Удалить станцию | ✅ Admin/Operator |
| PUT | `/stations/{id}/maintenance` | `PUT /{id}/maintenance` | Режим обслуживания | ✅ Admin/Operator |
| POST | `/stations/{id}/remote-start` | `POST /{id}/remote-start` | Начать зарядку | ✅ Bearer |
| POST | `/stations/{id}/remote-stop` | `POST /{id}/remote-stop` | Остановить зарядку | ✅ Bearer |

**Nginx конфиг:**
```nginx
location /stations/ {
    proxy_pass http://station_backend/;  # Убирает /stations из пути
}
```

**Монтирование в сервисе:**
```typescript
this.app.use('/sites', sitesRoutes);     // Для /stations/sites -> /sites
this.app.use('/', stationsRoutes);        // Для /stations -> /
```

---

### 💰 Transaction Service (порт 7000)

| Метод | Nginx URL | Внутренний путь | Описание | Auth | Фильтр по роли |
|-------|-----------|----------------|----------|------|---------------|
| GET | `/transactions` | `GET /` | История транзакций | ✅ Bearer | User: свои, Operator: сайт, Admin: все |
| GET | `/transactions/{id}` | `GET /{id}` | Детали транзакции | ✅ Bearer | ✅ |
| POST | `/transactions/start` | `POST /start` | Начать транзакцию | ✅ Bearer | ❌ |
| POST | `/transactions/{id}/stop` | `POST /{id}/stop` | Остановить транзакцию | ✅ Bearer | ✅ |
| POST | `/transactions/{id}/meter-values` | `POST /{id}/meter-values` | Добавить показания | ✅ Bearer | ❌ |
| GET | `/transactions/stats/summary` | `GET /stats/summary` | Статистика | ✅ Admin/Operator | ✅ |

**Query параметры для GET /transactions:**
- `status` - фильтр по статусу (active, completed, failed)
- `siteId` - фильтр по локации
- `stationId` - фильтр по станции
- `startDate` - от даты
- `endDate` - до даты
- `limit` - лимит результатов (default: 50)
- `skip` - пропустить записей (pagination)

**Nginx конфиг:**
```nginx
location /transactions/ {
    proxy_pass http://transaction_backend/;  # Убирает /transactions из пути
}
```

**Монтирование в сервисе:**
```typescript
app.use('/', transactionsRoutes);  // Корневой роут
```

---

### 🔔 Notification Service (порт 8000)

| Метод | Nginx URL | Внутренний путь | Описание | Auth |
|-------|-----------|----------------|----------|------|
| GET | `/notifications/preferences` | `GET /preferences` | Настройки уведомлений | ✅ Bearer |
| PATCH | `/notifications/preferences` | `PATCH /preferences` | Изменить настройки | ✅ Bearer |
| POST | `/notifications/preferences/device-token` | `POST /preferences/device-token` | Добавить токен устройства | ✅ Bearer |
| DELETE | `/notifications/preferences/device-token/{token}` | `DELETE /preferences/device-token/{token}` | Удалить токен | ✅ Bearer |
| GET | `/notifications/history` | `GET /history` | История уведомлений | ✅ Bearer |
| GET | `/notifications/history/{id}` | `GET /history/{id}` | Детали уведомления | ✅ Bearer |
| GET | `/notifications/stats` | `GET /stats` | Статистика | ✅ Bearer |

**Nginx конфиг:**
```nginx
location /notifications/ {
    proxy_pass http://notification_backend/;  # Убирает /notifications из пути
}
```

**Монтирование в сервисе:**
```typescript
app.use('/', notificationsRoutes);  // Корневой роут
```

---

## 🔧 Health Checks

| URL | Описание |
|-----|----------|
| `/nginx-health` | Nginx работает |
| `/health/auth` | Auth service работает |
| `/health/stations` | Station Manager работает |
| `/health/transactions` | Transaction Service работает |
| `/health/notifications` | Notification Service работает |
| `/health/ocpp` | OCPP Core работает |
| `/health/api` | API Gateway работает |
| `/health/analytics` | Analytics Service работает |

---

## 📊 Диаграмма маршрутизации

```
Клиент (Mobile App)
    ↓
Nginx (порт 80) - маршрутизация по префиксам
    ↓
    ├─ /auth/*          → Auth Service (5000)          → Убирает /auth
    ├─ /stations/*      → Station Manager (6000)       → Убирает /stations
    ├─ /transactions/*  → Transaction Service (7000)   → Убирает /transactions
    ├─ /notifications/* → Notification Service (8000)  → Убирает /notifications
    ├─ /analytics/*     → Analytics Service (9000)     → Убирает /analytics
    ├─ /mobile          → Mobile WebSocket (3001)      → WebSocket
    └─ /ocpp            → OCPP Core WebSocket (8081)   → WebSocket для станций
```

---

## ⚠️ Важные замечания

### 1. Trailing Slash в Nginx
```nginx
location /auth/ {  # ← Со слэшем
    proxy_pass http://auth_backend/;  # ← Со слэшем
}
```
- `/auth/login` → проксируется в → `/login` ✅
- `/authlogin` → НЕ проксируется ❌

### 2. Авторизация
Все эндпоинты (кроме `/auth/register` и `/auth/login`) требуют:
```
Authorization: Bearer <accessToken>
```

### 3. Роли пользователей
- `user` - видит только свои данные
- `operator` - видит данные своей локации (siteId)
- `admin` - видит все данные

### 4. Фильтрация по ролям
Transaction Service автоматически фильтрует результаты:
```javascript
// User роль
GET /transactions → только транзакции пользователя

// Operator роль
GET /transactions → только транзакции его локации

// Admin роль
GET /transactions → все транзакции
```

---

## 🧪 Тестирование

### Проверка доступности
```bash
# Nginx
curl http://176.88.248.139/nginx-health

# Сервисы
curl http://176.88.248.139/health/auth
curl http://176.88.248.139/health/stations
curl http://176.88.248.139/health/transactions
curl http://176.88.248.139/health/notifications
```

### Регистрация и вход
```bash
# Регистрация
curl -X POST http://176.88.248.139/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123456","name":"Test User"}'

# Вход
curl -X POST http://176.88.248.139/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123456"}'

# Получить токен из ответа
# {"success":true,"data":{"accessToken":"...","refreshToken":"..."}}
```

### Запросы с авторизацией
```bash
TOKEN="your-access-token"

# Список станций
curl http://176.88.248.139/stations \
  -H "Authorization: Bearer $TOKEN"

# История транзакций
curl http://176.88.248.139/transactions \
  -H "Authorization: Bearer $TOKEN"

# Локации
curl http://176.88.248.139/stations/sites \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📝 История изменений

### 2025-11-03
- ✅ Исправлены дублирующиеся пути в микросервисах
- ✅ Auth: `/auth` + `/register` → `/` + `/register`
- ✅ Stations: `/stations` + `/` → `/` + `/`
- ✅ Transactions: `/transactions` + `/` → `/` + `/`
- ✅ Notifications: `/notifications` + `/` → `/` + `/`
- ✅ Обновлена документация ENDPOINTS_MOBILE.md
- ✅ `/auth/verify` изменен с GET на POST
- ✅ `/transactions/my-history` заменен на `/transactions` с авто-фильтром
