import 'package:flutter/foundation.dart';
import 'package:it_charge/models/transaction_model.dart';
import 'package:it_charge/services/ocpp_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _items = [];
  bool _loading = false;
  String? _error;

  List<Transaction> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  /// Load user's sessions
  Future<void> loadMySessions({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
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

  void clear() {
    _items = [];
    _error = null;
    notifyListeners();
  }
}
