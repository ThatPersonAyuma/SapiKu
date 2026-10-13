import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/fe/widgets/penjualan_tambah_fab_menu.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';

class PenjualanTambahPage extends StatefulWidget {
  const PenjualanTambahPage({super.key});
  @override
  State<PenjualanTambahPage> createState() => _PenjualanTambahPageState();
}

class _PenjualanTambahPageState extends State<PenjualanTambahPage> {
  DateTime _date = DateTime.now();
  List<Product> _products = [];
  bool _productsLoading = true;
  bool _isSaving = false;
  final List<({Product product, int qty})> _items = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _productsLoading = true);
    final res = await Product.getAll();
    if (!mounted) return;
    setState(() {
      _products = res ?? [];
      _productsLoading = false;
    });
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _rp(int v) => 'Rp ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  int get _total => _items.fold(0, (s, e) => s + e.qty * e.product.price.toInt());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  void _inc(int i) => setState(() => _items[i] = (product: _items[i].product, qty: _items[i].qty + 1));
  void _dec(int i) {
    if (_items[i].qty <= 1) { setState(() => _items.removeAt(i)); return; }
    setState(() => _items[i] = (product: _items[i].product, qty: _items[i].qty - 1));
  }

  void _addProduct(Product product, int qty) {
    final idx = _items.indexWhere((e) => e.product.id == product.id);
    if (idx >= 0) {
      setState(() => _items[idx] = (product: product, qty: _items[idx].qty + qty));
    } else {
      setState(() => _items.add((product: product, qty: qty)));
    }
  }

  Future<void> _handleSave() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambah produk dulu')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final tx = await Transaction.create([for (final it in _items) TransactionDetailInsertComponent(it.product.id, it.qty)]);
      if (!mounted) return;
      if (tx != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Penjualan #${tx.id} berhasil disimpan')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan penjualan')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleScanQr() async {
    final raw = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const _QrDummyScannerPage()));
    if (raw == null || !mounted) return;
    final id = convertIdScanned(raw);
    if (id == null) return;
    final product = await Product.getById(id);
    if (!mounted) return;
    if (product != null) _showQrQtyDialog(product: product);
  }

  Future<void> _handleGalleryQr() async {
    try {
      final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (xfile == null) return;
      final controller = MobileScannerController();
      final capture = await controller.analyzeImage(xfile.path);
      controller.dispose();
      if (!mounted) return;
      if (capture == null || capture.barcodes.isEmpty) return;
      final raw = capture.barcodes.first.rawValue;
      final id = convertIdScanned(raw);
      if (id == null) return;
      final product = await Product.getById(id);
      if (!mounted) return;
      if (product != null) _showQrQtyDialog(product: product);
    } catch (_) {}
  }

  void _showQrQtyDialog({required Product product}) {
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.greenBorder, width: 2)),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tambah Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: AppColors.greenBorder, width: 1.4), borderRadius: BorderRadius.circular(8)),
                child: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
              const SizedBox(height: 14),
              const Text('Qty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 6),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '1',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4)),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyCtrl.text) ?? 0;
                    if (qty <= 0) return;
                    _addProduct(product, qty);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkCard, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  child: const Text('Tambah'),
                ),
              ),
            ]),
          ),
          Positioned(
            top: -14, right: -14,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.darkCard, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]), child: const Icon(Icons.close_rounded, size: 20, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _cardBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 1.5), borderRadius: BorderRadius.circular(12)),
        child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: child), Container(width: 10, color: AppColors.greenBorder)])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Tambah Penjualan'),
      body: Stack(children: [
        AppBackground(
          child: ListView(padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 100), children: [
            _cardBox(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tanggal Penjualan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)), Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey.shade600)]),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade50),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_fmtDate(_date), style: const TextStyle(fontSize: 14, color: Colors.black87)), Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600)]),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Stack(clipBehavior: Clip.none, children: [
              _cardBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 52),
                  child: _items.isEmpty
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Belum ada produk', style: TextStyle(fontSize: 13, color: Colors.black54))))
                      : Column(children: [
                          ..._items.asMap().entries.map((e) {
                            final idx = e.key; final it = e.value; final subtotal = it.qty * it.product.price.toInt();
                            return Padding(padding: EdgeInsets.only(bottom: idx == _items.length - 1 ? 0 : 14), child: Row(children: [
                              Expanded(child: Text('${it.product.name} :', style: const TextStyle(fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                              Row(mainAxisSize: MainAxisSize.min, children: [_qtyBtn(Icons.remove_rounded, () => _dec(idx)), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${it.qty}x', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))), _qtyBtn(Icons.add_rounded, () => _inc(idx))]),
                              const SizedBox(width: 12),
                              SizedBox(width: 92, child: Text(_rp(subtotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                            ]));
                          }),
                          const Divider(height: 20, thickness: 1, color: Color(0xFFE0E0E0)),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)), Text(_rp(_total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))]),
                        ]),
                ),
              ),
              Positioned(
                left: 0, right: 10, bottom: -18,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkCard, foregroundColor: Colors.white, elevation: 4, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            if (_productsLoading) const Center(child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
            if (!_productsLoading && _products.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Belum ada produk di katalog', style: TextStyle(fontSize: 12, color: Colors.black45)))),
          ]),
        ),
        PenjualanTambahFabMenu(onInputManual: () => _showInputManualDialog(), onQrGallery: _handleGalleryQr, onScanQr: _handleScanQr),
      ]),
      bottomNavigationBar: const AppBottomBar(),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 16, color: Colors.white)));
  }

  void _showInputManualDialog() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada produk — tambah produk dulu di katalog')));
      return;
    }
    Product? selected = _products.first;
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(context: context, barrierColor: Colors.black54, builder: (_) => StatefulBuilder(builder: (ctx, setDlg) {
      return Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.symmetric(horizontal: 20), child: Stack(clipBehavior: Clip.none, children: [
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.greenBorder, width: 2)), padding: const EdgeInsets.fromLTRB(18, 22, 18, 18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Input Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          const Text('Produk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.greenBorder, width: 1.4), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Product>(
                value: selected,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} — Rp ${p.price.toInt()}', style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setDlg(() => selected = v),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Qty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '1', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.8)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4)))),
          const SizedBox(height: 18),
          Center(child: ElevatedButton(onPressed: () { final qty = int.tryParse(qtyCtrl.text) ?? 0; if (selected == null || qty <= 0) return; _addProduct(selected!, qty); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkCard, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), child: const Text('Tambah'))),
        ])),
        Positioned(top: -14, right: -14, child: InkWell(onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(20), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.darkCard, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]), child: const Icon(Icons.close_rounded, size: 20, color: Colors.white)))),
      ]));
    }));
  }
}

class _QrDummyScannerPage extends StatefulWidget {
  const _QrDummyScannerPage();
  @override
  State<_QrDummyScannerPage> createState() => _QrDummyScannerPageState();
}

class _QrDummyScannerPageState extends State<_QrDummyScannerPage> {
  bool _done = false;
  void _onDetect(BarcodeCapture c) {
    if (_done || c.barcodes.isEmpty) return;
    _done = true;
    Navigator.pop(context, c.barcodes.first.rawValue ?? '');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Scan QR')), body: MobileScanner(controller: MobileScannerController(formats: const [BarcodeFormat.qrCode]), onDetect: _onDetect));
  }
}
