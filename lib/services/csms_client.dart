import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:it_charge/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

/// CSMS WebSocket client implementing the backend spec provided.
class CSMSClient {
  CSMSClient._();
  static final CSMSClient instance = CSMSClient._();

  WebSocketChannel? _channel;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  final Uuid _uuid = const Uuid();

  // heartbeat & reconnect
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer; // Таймер для переподключения
  final Duration _heartbeatInterval = const Duration(seconds: 20);
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3; // Максимум 3 попытки
  bool _reconnectEnabled = false; // По умолчанию отключено

  // last event id for replay
  String? _lastEventId;

  bool _connected = false;
  bool get connected => _connected;

  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController.broadcast();
  final StreamController<bool> _connController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  Stream<bool> get onConnectionChanged => _connController.stream;

  Future<void> connect({
    String? url,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_connected) return;

    final endpoint = url ?? _determineEndpoint();

    try {
      Map<String, String> headers = {};
      if (Config.apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${Config.apiKey}';
      }
      _channel = WebSocketChannel.connect(Uri.parse(endpoint));
      _setupListener();

      _connected = true;
      _reconnectAttempts = 0;
      _connController.add(true);

      if (Config.apiKey.isNotEmpty) {
        try {
          await request('auth', {
            'apiKey': Config.apiKey,
          }, const Duration(seconds: 10));
          debugPrint('✅ WS auth успешна');
        } catch (e) {
          final errMsg = e.toString().length > 45
              ? '${e.toString().substring(0, 45)}...'
              : e.toString();
          debugPrint('⚠️ WS auth: $errMsg');
        }
      } else {
        debugPrint('⚠️ API key пуст');
      }

      _startHeartbeat();

      await _loadLastEventId();
      if (_lastEventId != null) {
        try {
          final replay = await request('getEventsSince', {
            'eventId': _lastEventId!,
            'limit': 200,
          });
          if (replay['events'] is List) {
            for (final ev in (replay['events'] as List)) {
              if (ev is Map<String, dynamic>) {
                _processIncomingEvent(ev);
                final eid = ev['eventId']?.toString();
                if (eid != null) await _saveLastEventId(eid);
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Event replay: ошибка');
        }
      }
    } catch (e) {
      final errMsg = e.toString().length > 45
          ? '${e.toString().substring(0, 45)}...'
          : e.toString();
      debugPrint('❌ WS connect: $errMsg');
      _scheduleReconnect();
      rethrow;
    }
  }

  String _determineEndpoint() {
    // Новый WebSocket URL через Nginx /mobile
    return Config.wsUrl;
  }

  void _setupListener() {
    final ch = _channel;
    if (ch == null) return;
    ch.stream.listen(
      (raw) {
        try {
          final data = raw is String
              ? json.decode(raw) as Map<String, dynamic>
              : (raw as Map<String, dynamic>);

          if (data.containsKey('event')) {
            _eventsController.add(data);
            final eid = data['eventId']?.toString();
            if (eid != null) _saveLastEventId(eid);
          } else if (data.containsKey('id') &&
              (data.containsKey('result') || data.containsKey('error'))) {
            final id = data['id']?.toString() ?? '';
            final completer = _pending.remove(id);
            if (completer != null && !completer.isCompleted) {
              completer.complete(data);
            }
          } else {
            if (data.containsKey('result')) {
              final id = data['id']?.toString();
              if (id != null && _pending.containsKey(id)) {
                final c = _pending.remove(id)!;
                if (!c.isCompleted) c.complete(data);
              }
            }
          }
        } catch (e) {
          debugPrint('❌ WS parse: ошибка');
        }
      },
      onDone: () {
        debugPrint('⚠️ WS stream closed');
        _handleDisconnect();
      },
      onError: (err, st) {
        final errMsg = err.toString().length > 50
            ? '${err.toString().substring(0, 50)}...'
            : err.toString();
        debugPrint('❌ WS stream: $errMsg');
        _handleDisconnect();
      },
      cancelOnError: true,
    );
  }

  void _handleDisconnect() {
    if (!_connected) return; // Уже отключены, не вызываем переподключение

    debugPrint('⚠️ WS отключён');
    _connected = false;
    _stopHeartbeat();

    for (final entry in _pending.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(Exception('Connection lost'));
      }
    }
    _pending.clear();

    _connController.add(false);

    // Переподключение НЕ запускается автоматически
    // Используйте enableReconnect() для включения автопереподключения
  }

  Future<Map<String, dynamic>> request(
    String action, [
    Map<String, dynamic>? params,
    Duration timeout = const Duration(seconds: 30),
  ]) async {
    if (!_connected) {
      try {
        await connect();
      } catch (e) {
        final errMsg = e.toString().length > 45
            ? '${e.toString().substring(0, 45)}...'
            : e.toString();
        debugPrint('❌ WS $action connect: $errMsg');
        rethrow;
      }
    }

    final id = _uuid.v4();
    final msg = <String, dynamic>{'id': id, 'action': action};
    if (params != null) msg['params'] = params;

    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    try {
      _channel!.sink.add(json.encode(msg));
    } catch (e) {
      _pending.remove(id);
      final errMsg = e.toString().length > 45
          ? '${e.toString().substring(0, 45)}...'
          : e.toString();
      debugPrint('❌ WS $action send: $errMsg');
      rethrow;
    }

    try {
      final res = await completer.future.timeout(timeout);
      if (res.containsKey('error')) {
        final error = res['error'];
        throw Exception(error.toString());
      }
      final result = res['result'];
      if (result is Map<String, dynamic>) return result;
      return <String, dynamic>{'value': result};
    } catch (e) {
      _pending.remove(id);
      final errMsg = e.toString();
      debugPrint('❌ WS $action: $errMsg');
      rethrow;
    }
  }

  Future<void> subscribe(Map<String, dynamic> params) async {
    try {
      final res = await request('subscribe', params);
      if (res['snapshot'] is Map) {
        final snap = res['snapshot'] as Map<String, dynamic>;
        if (snap['stations'] is List) {
          _eventsController.add({
            'event': 'snapshot.stations',
            'data': snap['stations'],
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ WS subscribe: $e');
      rethrow;
    }
  }

  Future<void> unsubscribe(String subscriptionId) async {
    try {
      await request('unsubscribe', {'subscriptionId': subscriptionId});
    } catch (e) {
      debugPrint('⚠️ WS unsubscribe: $e');
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      try {
        await request('ping', null, const Duration(seconds: 5));
      } catch (e) {
        debugPrint('⚠️ WS heartbeat: ошибка');
        _handleDisconnect();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (!_reconnectEnabled) {
      debugPrint('⚠️ Автопереподключение отключено');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint(
        '❌ Макс. попыток переподключения ($_maxReconnectAttempts) достигнуто. Остановка.',
      );
      _reconnectEnabled = false;
      _stopReconnect();
      return;
    }

    _reconnectAttempts++;
    final delayMs = 3000 * _reconnectAttempts; // 3s, 6s, 9s

    debugPrint(
      '⏳ Попытка переподключения $_reconnectAttempts через ${delayMs}ms',
    );

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!_reconnectEnabled) return;

      try {
        await connect();
        debugPrint('✅ Переподключение успешно');
      } catch (e) {
        debugPrint('⚠️ Переподключение $_reconnectAttempts: ошибка');
        _scheduleReconnect();
      }
    });
  }

  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Включить автоматическое переподключение
  void enableReconnect() {
    _reconnectEnabled = true;
    _reconnectAttempts = 0;
  }

  /// Отключить автоматическое переподключение
  void disableReconnect() {
    _reconnectEnabled = false;
    _stopReconnect();
  }

  Future<void> _saveLastEventId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('csms_last_event_id', id);
      _lastEventId = id;
    } catch (_) {}
  }

  Future<void> _loadLastEventId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastEventId = prefs.getString('csms_last_event_id');
    } catch (_) {
      _lastEventId = null;
    }
  }

  void _processIncomingEvent(Map<String, dynamic> data) {
    final eid = data['eventId']?.toString();
    if (eid != null) _saveLastEventId(eid);

    if (data['event'] == 'session.expired') {
      debugPrint('⚠️ Сессия истекла, переподключение...');
      _channel?.sink.close(ws_status.goingAway);
    }

    _eventsController.add(data);
  }

  void sendRaw(Map<String, dynamic> msg) {
    final out = json.encode(msg);
    _channel?.sink.add(out);
  }

  Future<void> close() async {
    debugPrint('ℹ️ WS closing connection');
    _reconnectEnabled = false; // Отключаем автопереподключение
    _stopReconnect();
    _stopHeartbeat();
    _reconnectAttempts = 0;

    try {
      _channel?.sink.close(ws_status.normalClosure);
    } catch (e) {
      debugPrint('CSMSClient: Ошибка при закрытии канала: $e');
    }

    _channel = null;
    _connected = false;

    try {
      if (!_eventsController.isClosed) await _eventsController.close();
    } catch (e) {
      debugPrint('CSMSClient: Ошибка при закрытии контроллера событий: $e');
    }

    try {
      if (!_connController.isClosed) await _connController.close();
    } catch (e) {
      debugPrint('CSMSClient: Ошибка при закрытии контроллера соединения: $e');
    }

    debugPrint('CSMSClient: Соединение закрыто');
  }
}
