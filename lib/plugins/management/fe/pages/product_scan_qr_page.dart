import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';

class ProductScanQrPage extends StatefulWidget {
  const ProductScanQrPage({super.key});

  @override
  State<ProductScanQrPage> createState() => _ProductScanQrPageState();
}

class _ProductScanQrPageState extends State<ProductScanQrPage> {
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

      // Navigate to product detail
      await Navigator.pushNamed(
        context,
        '/management/product/detail',
        arguments: {'product': product},
      );

      if (mounted) {
        _isProcessing = false;
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Scan QR Produk'),
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
