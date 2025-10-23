import 'package:flutter/foundation.dart';
import 'package:it_charge/models/transaction_model.dart';
import 'package:it_charge/services/ocpp_service.dart';
import 'package:it_charge/services/csms_client.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _items = [];
  bool _loading = false;
  String? _error;

  List<Transaction> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  TransactionProvider() {
    // subscribe to CSMS events
    CSMSClient.instance.events.listen((ev) {
      try {
        final name = ev['event']?.toString() ?? '';
        if (name == 'transaction.started' && ev['data'] is Map) {
          final t = Transaction.fromJson(ev['data'] as Map<String, dynamic>);
          _items.insert(0, t);
          notifyListeners();
        } else if (name == 'transaction.stopped' && ev['data'] is Map) {
          final stopped = Transaction.fromJson(
            ev['data'] as Map<String, dynamic>,
          );
          final idx = _items.indexWhere(
            (i) => i.transactionId == stopped.transactionId,
          );
          if (idx >= 0) {
            _items[idx] = stopped;
          } else {
            _items.insert(0, stopped);
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('TransactionProvider event handler error: $e');
      }
    });
  }

  /// Load user's sessions
  Future<void> loadMySessions({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    CSMSClient.instance.events.listen((ev) {
      try {
        final name = ev['event']?.toString() ?? '';
        if (name == 'transaction.started' && ev['data'] is Map) {
          final t = Transaction.fromJson(ev['data'] as Map<String, dynamic>);
          _items.insert(0, t);
          notifyListeners();
        } else if (name == 'transaction.stopped' && ev['data'] is Map) {
          final stopped = Transaction.fromJson(
            ev['data'] as Map<String, dynamic>,
          );
          final idx = _items.indexWhere(
            (i) => i.transactionId == stopped.transactionId,
          );
          if (idx >= 0) {
            _items[idx] = stopped;
          } else {
            _items.insert(0, stopped);
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('TransactionProvider event handler error: $e');
      }
    });
    try {
      final res = await OcppService.getMySessions();
      _items = res;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Загрузка транзакций для конкретной станции
  Future<void> loadForStation(String stationId, {bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await OcppService.getTransactionsForStation(stationId);
      _items = res;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadMySessions(force: true);
  }

  void clear() {
    _items = [];
    _error = null;
    notifyListeners();
  }
}
