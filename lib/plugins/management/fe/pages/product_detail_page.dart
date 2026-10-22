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
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin hapus "${_product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    await _product.destroy();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk "${_product.name}" berhasil dihapus')));
    Navigator.pop(context, true);
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
                       bottom: BorderSide(color: Colors.blue.shade700, width: 2.5),
                     ),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: IconButton(
                     icon: const Icon(Icons.edit),
                     color: Colors.blue.shade700,
                     onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit belum tersedia')));
                     },
                   ),
                 ),
                 const SizedBox(width: 8),
                 Container(
                   decoration: BoxDecoration(
                     color: Colors.white,
                     border: Border(
                       bottom: BorderSide(color: Colors.red.shade700, width: 2.5),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 140,
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
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 120,
                          height: 120,
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
