import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product _product;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  String _rp(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greenBorder, width: 2),
              ),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Hapus Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Apakah anda yakin ingin menghapus data produk ini?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Tidak'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Yakin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -14,
              right: -14,
              child: InkWell(
                onTap: () => Navigator.pop(ctx, false),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    await _product.destroy();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk "${_product.name}" berhasil dihapus')));
    Navigator.pop(context, true);
  }

  void _handleEdit() {
    final nameCtrl = TextEditingController(text: _product.name);
    final priceCtrl = TextEditingController(text: _product.price.toString());
    final stockCtrl = TextEditingController(text: _product.stock.toString());

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greenBorder, width: 2),
              ),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Produk',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Nama Produk',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nama produk',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.8),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Harga',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Harga',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.8),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Stok',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Stok',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.8),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final price = double.tryParse(priceCtrl.text);
                          final stock = int.tryParse(stockCtrl.text);

                          if (name.isEmpty || price == null || stock == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Semua field harus diisi dengan benar')),
                            );
                            return;
                          }

                          try {
                            _product.name = name;
                            _product.price = price;
                            _product.stock = stock;
                            await _product.saveToDb();

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Produk berhasil diperbarui')),
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkCard,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -14,
              right: -14,
              child: InkWell(
                onTap: () => Navigator.pop(ctx),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDownloadQr() async {
    if (_product.qrImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR belum tersedia')));
      return;
    }
    final success = await _product.saveQRtoGallery();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'QR berhasil disimpan ke galeri' : 'Gagal menyimpan QR')),
    );
  }

  Widget _cardBox({required Widget child}) {
    return ClipRRect(
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
              Expanded(child: child),
              Container(width: 10, color: AppColors.greenBorder),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Detail Produk'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 90),
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: AppColors.greenBorder, width: 2),
                        bottom: BorderSide(color: AppColors.greenBorder, width: 2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.blue.shade700, width: 3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.blue.shade700,
                      onPressed: _handleEdit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.red.shade700, width: 3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red.shade700,
                      onPressed: _deleting ? () {} : _handleDelete,
                    ),
                  ),
              ],
            ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(color: AppColors.greenBorder, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: (_product.imagePath != null && File(_product.imagePath!).existsSync())
                            ? Image.file(File(_product.imagePath!), fit: BoxFit.cover)
                            : const Icon(Icons.image, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 140,
                          height: 140,
                          color: Colors.grey.shade200,
                          child: (_product.qrImagePath != null && File(_product.qrImagePath!).existsSync())
                              ? Image.file(File(_product.qrImagePath!), fit: BoxFit.cover)
                              : const Icon(Icons.qr_code_2_rounded, color: Colors.grey, size: 30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleDownloadQr,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkCard,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 14),
                          label: const Text('Download'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _cardBox(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Harga',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        Text(
                          _rp(_product.price),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stok',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        Text(
                          '${_product.stock} unit',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
