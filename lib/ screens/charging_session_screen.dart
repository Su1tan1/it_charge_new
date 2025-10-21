import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:it_charge/models/station_model.dart';
import 'package:it_charge/services/ocpp_service.dart';
import 'package:it_charge/models/transaction_model.dart';
import 'package:provider/provider.dart';
import 'package:it_charge/providers/station_provider.dart';

class ChargingSessionScreen extends StatefulWidget {
  final Station station;
  final Connector connector;
  final int connectorIndex; // 1-based id

  const ChargingSessionScreen({
    super.key,
    required this.station,
    required this.connector,
    required this.connectorIndex,
  });

  @override
  State<ChargingSessionScreen> createState() => _ChargingSessionScreenState();
}

class _ChargingSessionScreenState extends State<ChargingSessionScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _status; // raw status from server
  Transaction? _currentTx;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await OcppService.getConnectorStatus(
        widget.station.id,
        widget.connector.id,
      );
      Transaction? tx;
      try {
        if (status['transaction'] != null && status['transaction'] is Map) {
          tx = Transaction.fromJson(
            Map<String, dynamic>.from(status['transaction'] as Map),
          );
        }
      } catch (_) {}
      setState(() {
        _status = Map<String, dynamic>.from(status);
        _currentTx = tx;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _startCharging() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final resp = await OcppService.userStartCharging(
        widget.station.id,
        widget.connectorIndex,
        userId,
      );

      final respMap = Map<String, dynamic>.from(resp);
      // Robustly extract transaction info from many possible server shapes
      Map<String, dynamic> txMap = {};
      // 1) direct transaction object
      if (respMap['transaction'] is Map) {
        txMap = Map<String, dynamic>.from(respMap['transaction'] as Map);
      }
      // 2) data.transaction
      else if (respMap['data'] is Map &&
          respMap['data']['transaction'] is Map) {
        txMap = Map<String, dynamic>.from(
          respMap['data']['transaction'] as Map,
        );
      }
      // 3) top-level fields
      else {
        final idCandidates = [
          respMap['transactionId'],
          respMap['transaction_id'],
          respMap['id'],
          respMap['txId'],
          respMap['result']?['transactionId'],
        ];
        String txId = '';
        for (final c in idCandidates) {
          if (c != null) {
            txId = c.toString();
            break;
          }
        }
        txMap['transactionId'] = txId;
        txMap['chargePointId'] =
            respMap['chargePointId']?.toString() ?? widget.station.id;
        txMap['connectorId'] = (respMap['connectorId'] is int)
            ? respMap['connectorId']
            : int.tryParse(respMap['connectorId']?.toString() ?? '') ??
                  widget.connectorIndex;
        txMap['status'] = respMap['status']?.toString() ?? 'charging';
        txMap['startTime'] = DateTime.now().toIso8601String();
      }

      // Immediately update UI: set current transaction and raw status from response
      try {
        final tx = Transaction.fromJson(txMap);
        setState(() {
          _currentTx = tx;
          _status = respMap;
        });
        // Update global provider so other UI (map/modal) sees change immediately
        try {
          final provider = context.read<StationProvider>();
          provider.updateConnectorStatus(
            widget.station.id,
            widget.connectorIndex,
            'Charging',
            Colors.blue,
            transactionId: tx.transactionId,
          );
        } catch (_) {}
      } catch (_) {
        // If parsing fails, still set raw status so statusText() may detect 'charging'
        setState(() => _status = respMap);
        try {
          final provider = context.read<StationProvider>();
          provider.updateConnectorStatus(
            widget.station.id,
            widget.connectorIndex,
            'Charging',
            Colors.blue,
            transactionId: respMap['transactionId']?.toString(),
          );
        } catch (_) {}
      }

      final message = respMap['message'] != null
          ? respMap['message'].toString()
          : 'Зарядка запрошена';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      // Refresh status from server to get authoritative data
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка старта: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _stopCharging() async {
    if (_currentTx == null && widget.connector.transactionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет активной транзакции')));
      return;
    }
    final txId = _currentTx?.transactionId ?? widget.connector.transactionId!;
    setState(() => _loading = true);
    try {
      final resp = await OcppService.userStopCharging(
        txId,
        chargePointId: widget.station.id,
        connectorId: widget.connectorIndex,
      );

      final respMap = Map<String, dynamic>.from(resp);
      // Merge existing transaction data with stop response
      final currentMap = _currentTx?.toJson() ?? {};
      if (respMap['status'] != null) currentMap['status'] = respMap['status'];
      if (respMap['totalKWh'] != null)
        currentMap['energy'] = respMap['totalKWh'];
      if (respMap['cost'] != null) currentMap['cost'] = respMap['cost'];
      currentMap['stopTime'] = DateTime.now().toIso8601String();

      try {
        final updated = Transaction.fromJson(
          Map<String, dynamic>.from(currentMap),
        );
        setState(() {
          _currentTx = updated;
          _status = respMap;
        });
      } catch (_) {
        setState(() => _status = respMap);
      }
      // Update provider to mark connector available/cleared transaction
      try {
        final provider = context.read<StationProvider>();
        provider.resetConnectorStatus(widget.station.id, widget.connectorIndex);
      } catch (_) {}

      final message = respMap['message'] != null
          ? respMap['message'].toString()
          : 'Завершение зарядки запрошено';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка остановки: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusText() {
      if (_status != null) {
        final keys = [
          'status',
          'state',
          'stateName',
          'statusText',
          'connectorStatus',
          'message',
        ];
        for (final k in keys) {
          final v = _status![k];
          if (v != null && v.toString().isNotEmpty) return v.toString();
        }
      }
      return widget.connector.status;
    }

    bool isCharging() {
      final s = statusText().toLowerCase();
      if (s.contains('charg') || s.contains('заряд')) return true;
      if (_currentTx != null) {
        final st = _currentTx!.status?.toLowerCase() ?? '';
        if (st.contains('charg') || st.contains('заряд')) return true;
        // if transaction exists and no stopTime — treat as active
        if (_currentTx!.stopTime == null) return true;
      }
      final cs = widget.connector.status.toLowerCase();
      if (cs.contains('charg') || cs.contains('заряд')) return true;
      return false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.station.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1113),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.connector.type,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.connector.power,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.connector.price,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.connector.statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null)
                      Text(
                        'Ошибка: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSessionDetails(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : (isCharging() ? _stopCharging : _startCharging),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCharging() ? Colors.red : Colors.green,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isCharging() ? 'Остановить зарядку' : 'Начать зарядку',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionDetails() {
    final tx = _currentTx;
    if (tx == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1113),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Транзакция не активна',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 6),
            Text(
              'ID: ${widget.connector.transactionId ?? '-'}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1113),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Транзакция', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(
            'ID: ${tx.transactionId}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Начало',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      tx.startTime != null ? _fmt(tx.startTime!) : '-',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Окончание',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      tx.stopTime != null ? _fmt(tx.stopTime!) : '-',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Энергия: ${tx.energy?.toStringAsFixed(2) ?? '-'} kWh',
                style: TextStyle(color: Colors.grey[300]),
              ),
              Text(
                '₽${tx.cost?.toStringAsFixed(2) ?? '-'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
