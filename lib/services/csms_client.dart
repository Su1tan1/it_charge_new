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
  final Duration _heartbeatInterval = const Duration(seconds: 20);
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 12;

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
    debugPrint('CSMSClient: Подключение к $endpoint');

    try {
      Map<String, String> headers = {};
      if (Config.apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${Config.apiKey}';
      }
      _channel = WebSocketChannel.connect(Uri.parse(endpoint));
      _setupListener();

      if (Config.apiKey.isNotEmpty) {
        await request('auth', {'apiKey': Config.apiKey});
      }

      _connected = true;
      _reconnectAttempts = 0;
      _connController.add(true);

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
          debugPrint('CSMSClient: Ошибка повтора событий: $e');
        }
      }
    } catch (e) {
      debugPrint('CSMSClient: Ошибка подключения: $e');
      _scheduleReconnect();
      rethrow;
    }
  }

  String _determineEndpoint() {
    if (Config.baseUrl.isNotEmpty &&
        (Config.baseUrl.startsWith('ws') ||
            Config.baseUrl.startsWith('http'))) {
      if (Config.baseUrl.startsWith('http')) {
        return '${Config.baseUrl.replaceFirst('http', 'ws')}/mobile-client';
      }
      return '${Config.baseUrl}/mobile-client';
    }
    return 'ws://193.29.139.202:8081/mobile-client';
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
          // debugPrint('CSMSClient: Получено сообщение: $data'); // Убрано для уменьшения логов

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
        } catch (e, st) {
          debugPrint('CSMSClient: Ошибка разбора сообщения: $e');
          debugPrint('Стек вызовов: $st');
        }
      },
      onDone: () {
        debugPrint('CSMSClient: Поток завершен - соединение закрыто сервером');
        _handleDisconnect();
      },
      onError: (err, st) {
        debugPrint('CSMSClient: Ошибка потока: $err');
        debugPrint('Стек вызовов ошибки: $st');
        _handleDisconnect();
      },
      cancelOnError: true,
    );
  }

  void _handleDisconnect() {
    debugPrint('CSMSClient: Соединение потеряно, попытка переподключения...');
    _connected = false;
    _stopHeartbeat();

    for (final entry in _pending.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(Exception('Соединение потеряно'));
      }
    }
    _pending.clear();

    _connController.add(false);
    _scheduleReconnect();
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
        debugPrint('CSMSClient: Ошибка подключения при запросе: $e');
        rethrow;
      }
    }

    final id = _uuid.v4();
    final msg = <String, dynamic>{'id': id, 'action': action};
    if (params != null) msg['params'] = params;

    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    final out = json.encode(msg);
    // debugPrint('CSMSClient OUT RAW: $out'); // Убрано для уменьшения логов

    try {
      _channel!.sink.add(out);
    } catch (e) {
      _pending.remove(id);
      debugPrint('CSMSClient: Не удалось отправить сообщение: $e');
      rethrow;
    }

    try {
      final res = await completer.future.timeout(timeout);
      if (res.containsKey('error')) {
        throw Exception(res['error'].toString());
      }
      final result = res['result'];
      if (result is Map<String, dynamic>) return result;
      return <String, dynamic>{'value': result};
    } catch (e) {
      _pending.remove(id);
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
      debugPrint('CSMSClient: Ошибка подписки: $e');
      rethrow;
    }
  }

  Future<void> unsubscribe(String subscriptionId) async {
    try {
      await request('unsubscribe', {'subscriptionId': subscriptionId});
    } catch (e) {
      debugPrint('CSMSClient: Ошибка отписки: $e');
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      try {
        await request('ping', null, const Duration(seconds: 5));
      } catch (e) {
        debugPrint('CSMSClient: Ошибка пинга Heartbeat: $e');
        _handleDisconnect();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint(
        'CSMSClient: Достигнуто максимальное количество попыток переподключения ($_maxReconnectAttempts)',
      );
      return;
    }
    _reconnectAttempts++;
    final delayMs = 500 * (1 << (_reconnectAttempts - 1));
    debugPrint(
      'CSMSClient: Планируется попытка переподключения $_reconnectAttempts через $delayMsмс',
    );
    Future.delayed(Duration(milliseconds: delayMs), () async {
      try {
        debugPrint('CSMSClient: Попытка переподключения...');
        await connect();
      } catch (e) {
        debugPrint(
          'CSMSClient: Попытка переподключения $_reconnectAttempts не удалась: $e',
        );
        _scheduleReconnect();
      }
    });
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
      debugPrint('CSMSClient: Сессия истекла, попытка переподключения...');
      _channel?.sink.close(ws_status.goingAway);
    }

    if (data['event'] == 'connection.status') {
      final status = data['data']?.toString();
      debugPrint('CSMSClient: Событие статуса соединения: $status');
    }

    _eventsController.add(data);
  }

  void sendRaw(Map<String, dynamic> msg) {
    final out = json.encode(msg);
    // debugPrint('CSMSClient RAW SEND: $out'); // Убрано для уменьшения логов
    _channel?.sink.add(out);
  }

  Future<void> close() async {
    debugPrint('CSMSClient: Закрытие соединения...');
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
