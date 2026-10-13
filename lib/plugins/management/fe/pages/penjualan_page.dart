import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/fe/widgets/penjualan_card.dart';
import 'package:sapiku/plugins/management/fe/widgets/penjualan_fab_menu.dart';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});
  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  List<Transaction> _txs = [];
  bool _loading = true;
  String? _error;
  final Map<int, int> _totals = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await Transaction.getAll();
    if (!mounted) return;
    if (res == null) {
      setState(() {
        _txs = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _txs = res;
      _loading = false;
    });
    for (final tx in res) {
      _loadTotal(tx);
    }
  }

  Future<void> _loadTotal(Transaction tx) async {
    final details = await tx.getAllTransactionDetails();
    if (details == null || details.isEmpty) {
      if (!mounted) return;
      setState(() => _totals[tx.id] = 0);
      return;
    }
    int total = 0;
    for (final d in details) {
      final p = await Product.getById(d.productId);
      if (p != null) total += (p.price.toInt() * d.quantity);
    }
    if (!mounted) return;
    setState(() => _totals[tx.id] = total);
  }

  String _fmtTime(DateTime d) {
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm - ${d.day} ${months[d.month]} ${d.year}';
  }

  String _rp(int v) => 'Rp ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 75;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Daftar Penjualan'),
      body: Stack(
        children: [
          AppBackground(
            child: RefreshIndicator(
              edgeOffset: topOffset + 8,
              displacement: 40,
              onRefresh: _load,
              child: _loading
                  ? ListView(padding: const EdgeInsets.only(top: 140), physics: const AlwaysScrollableScrollPhysics(), children: const [Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))])
                  : _error != null
                      ? ListView(padding: const EdgeInsets.only(top: 140), physics: const AlwaysScrollableScrollPhysics(), children: [Center(child: Text(_error!))])
                      : _txs.isEmpty
                          ? ListView(padding: const EdgeInsets.only(top: 140), physics: const AlwaysScrollableScrollPhysics(), children: [const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada penjualan')))])
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 90),
                              itemCount: _txs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final tx = _txs[i];
                                final total = _totals[tx.id];
                                return PenjualanCard(
                                  idLabel: 'ID #${tx.id}',
                                  timeLabel: _fmtTime(tx.datetime),
                                  totalLabel: total == null ? 'Memuat...' : _rp(total),
                                  onDetailTap: () async {
                                    await Navigator.pushNamed(context, '/management/penjualan/detail', arguments: {'transaction': tx});
                                    _load();
                                  },
                                );
                              },
                            ),
            ),
          ),
          PenjualanFabMenu(
            onTambah: () async {
              await Navigator.pushNamed(context, '/management/penjualan/tambah');
              _load();
            },
            onLaporan: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan Penjualan')));
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
