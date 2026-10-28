import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/utils/utils.dart';

class PenjualanDetailPage extends StatefulWidget {
  final Transaction transaction;
  const PenjualanDetailPage({super.key, required this.transaction});

  @override
  State<PenjualanDetailPage> createState() => _PenjualanDetailPageState();
}

class _PenjualanDetailPageState extends State<PenjualanDetailPage> {
  bool _loading = true;
  bool _deleting = false;
  List<TransactionDetail> _details = [];
  final Map<int, Product> _productCache = {};
  String? _error;

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
    final details = await widget.transaction.getAllTransactionDetails();
    if (!mounted) return;
    if (details == null) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat detail transaksi';
      });
      return;
    }
    _details = details;
    for (final d in _details) {
      if (!_productCache.containsKey(d.productId)) {
        final p = await Product.getById(d.productId);
        if (p != null) _productCache[d.productId] = p;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _fmtTime(DateTime d) {
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm - ${d.day} ${months[d.month]} ${d.year}';
  }

  String _rp(int v) => 'Rp ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Future<void> _handleDelete() async {
    final confirm = await PopUpMessage.showYesNoMessage(
      'Apakah anda yakin ingin menghapus penjualan #${widget.transaction.id}?',
      title: PopUpTitle.confirmation,
    );
    if (!confirm) return;
    
    setState(() => _deleting = true);
    try {
      await widget.transaction.destroy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Penjualan #${widget.transaction.id} berhasil dihapus')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
      setState(() => _deleting = false);
    }
  }
  Widget build(BuildContext context) {
    int grandTotal = 0;
    for (final d in _details) {
      final p = _productCache[d.productId];
      if (p != null) grandTotal += p.price.toInt() * d.quantity;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Detail Penjualan'),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.only(top: 140), child: Text(_error!)))
                : Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 14),
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 1.5), borderRadius: BorderRadius.circular(12)),
                              child: IntrinsicHeight(
                                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('ID #${widget.transaction.id}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                                            Text(_fmtTime(widget.transaction.datetime), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (_details.isEmpty)
                                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tidak ada item', style: TextStyle(fontSize: 13, color: Colors.black54)))
                                        else
                                          ..._details.map((d) {
                                            final p = _productCache[d.productId];
                                            final name = p?.name ?? 'Produk #${d.productId}';
                                            final unit = p?.price.toInt() ?? 0;
                                            final subtotal = unit * d.quantity;
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                Expanded(child: Text('$name : ${d.quantity}x', style: const TextStyle(fontSize: 14, color: Colors.black87))),
                                                const SizedBox(width: 12),
                                                Text(_rp(subtotal), style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                              ]),
                                            );
                                          }),
                                        const Divider(height: 16, thickness: 1, color: Color(0xFFE0E0E0)),
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          Text(_rp(grandTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        ]),
                                      ]),
                                    ),
                                  ),
                                  Container(width: 10, color: AppColors.greenBorder),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: _deleting ? null : _handleDelete,
                          child: _deleting
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
