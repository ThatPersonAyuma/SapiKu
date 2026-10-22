import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';

class ProductUpdateStockPage extends StatefulWidget {
  const ProductUpdateStockPage({super.key});

  @override
  State<ProductUpdateStockPage> createState() => _ProductUpdateStockPageState();
}

class _ProductUpdateStockPageState extends State<ProductUpdateStockPage> {
  late MobileScannerController _scannerController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;
    final id = convertIdScanned(rawValue);

    if (id == null) {
      debugPrint('Invalid QR');
      return;
    }

    _isProcessing = true;

    try {
      final product = await Product.getById(id);
      if (!mounted) return;

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk tidak ditemukan')),
        );
        _isProcessing = false;
        return;
      }

      // Show update stock dialog
      _showUpdateStockDialog(product);
    } catch (e) {
      debugPrint('Error scanning QR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        _isProcessing = false;
      }
    }
  }

  void _showUpdateStockDialog(Product product) {
    final stockController = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      barrierDismissible: false,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produk Ditemukan!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: AppColors.greenBorder, width: 1.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Stok',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah stok',
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
                        final newStock = int.tryParse(stockController.text);
                        if (newStock == null || newStock < 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Input stok tidak valid')),
                          );
                          return;
                        }

                        try {
                          await product.updateStock(newStock);
                          if (!ctx.mounted) return;

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Stok produk "${product.name}" berhasil diperbarui')),
                          );

                          // Redirect to management page
                          if (mounted) {
                            Navigator.pop(context);
                          }
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
                      child: const Text('Perbarui Stok'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -14,
              right: -14,
              child: InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _isProcessing = false;
                },
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
    ).then((_) {
      if (mounted) {
        _isProcessing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Perbarui Stok Produk'),
      body: AppBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            ),
            // Green border frame
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 150),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.greenBorder,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const SizedBox.expand(),
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
