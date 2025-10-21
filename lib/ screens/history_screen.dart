import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:it_charge/providers/transaction_provider.dart';
import 'package:it_charge/models/transaction_model.dart';

class HistoryScreen extends StatefulWidget {
  /// Если передан stationId — показываем транзакции для станции, иначе — мои сессии
  final String? stationId;
  const HistoryScreen({super.key, this.stationId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late TransactionProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = TransactionProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.stationId != null) {
      await _provider.loadForStation(widget.stationId!);
    } else {
      await _provider.loadMySessions();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TransactionProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFF090909),
        body: Consumer<TransactionProvider>(
          builder: (context, prov, _) {
            if (prov.loading && prov.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (prov.error != null && prov.items.isEmpty) {
              return Center(
                child: Text(
                  'Ошибка: ${prov.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (widget.stationId != null) {
                  await prov.loadForStation(widget.stationId!);
                } else {
                  await prov.loadMySessions(force: true);
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: prov.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildSummary(prov.items);
                  final tx = prov.items[index - 1];
                  return _buildTransactionCard(tx);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(List<Transaction> items) {
    final total = items.fold<double>(0.0, (p, e) => p + (e.cost ?? 0.0));
    final sessions = items.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6A7), Color(0xFF70E000)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сессий',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                ),
                const SizedBox(height: 6),
                Text(
                  '$sessions',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Потрачено',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                ),
                const SizedBox(height: 6),
                Text(
                  '₽${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx) {
    final start = tx.startTime != null ? _formatDate(tx.startTime!) : '-';
    final stop = tx.stopTime != null ? _formatDate(tx.stopTime!) : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Text(
                  'TX ${tx.transactionId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(tx.status ?? '', style: TextStyle(color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(start, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(stop, style: const TextStyle(color: Colors.white)),
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
                'Energy: ${tx.energy?.toStringAsFixed(2) ?? '-'} kWh',
                style: TextStyle(color: Colors.grey[300]),
              ),
              Text(
                '₽${tx.cost?.toStringAsFixed(2) ?? '-'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
