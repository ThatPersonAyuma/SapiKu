import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/fe/widgets/management_fab_menu.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});
  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll ke produk tertentu (mis. produk yang baru saja ditambahkan)
  Future<void> _scrollToProduct(int id) async {
    BuildContext? ctx;
    for (var attempt = 0; attempt < 5; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      ctx = _itemKeys[id]?.currentContext;
      if (ctx != null) break;
      await Future.delayed(const Duration(milliseconds: 60));
    }
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await Product.getAll();
    if (!mounted) return;
    if (res == null) {
      setState(() {
        _products = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _products = res;
      _loading = false;
      _itemKeys.clear();
    });
  }

  String _rp(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 75;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Pencatatan Produk'),
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
                      : _products.isEmpty
                          ? ListView(padding: const EdgeInsets.only(top: 140), physics: const AlwaysScrollableScrollPhysics(), children: [const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data produk')))])
                          : ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 90),
                              itemCount: _products.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final p = _products[i];
                                final key = _itemKeys.putIfAbsent(p.id, GlobalKey.new);
                                return KeyedSubtree(key: key, child: _buildProductCard(p));
                              },
                            ),
            ),
          ),
           ManagementFabMenu(
             onScan: () async {
               await Navigator.pushNamed(context, '/management/product/scan-qr');
             },
              onUpdateStock: () async {
                await Navigator.pushNamed(context, '/management/product/update-stock');
                await _load();
              },
             onTambah: () async {
               final result = await Navigator.pushNamed(context, '/management/tambah');
               await _load();
               if (result is Product) {
                 await _scrollToProduct(result.id);
               }
             },
             onLaporan: () => print('Laporan'),
           ),
        ],
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }

  Widget _buildProductCard(Product p) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/management/product/detail', arguments: {'product': p});
        if (result == true) {
          await _load();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        const Divider(height: 0, thickness: 0.5),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_rp(p.price), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text('Stok: ${p.stock}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            _buildImageThumbnail(p.imagePath),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 10, color: AppColors.greenBorder),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String? path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        color: Colors.grey[200],
        child: (path != null && File(path).existsSync())
            ? Image.file(File(path), fit: BoxFit.cover)
            : const Icon(Icons.image, color: Colors.grey),
      ),
    );
  }
}
