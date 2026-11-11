import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';
import 'package:sapiku/utils/utils.dart';

class ProductScanQrPage extends StatefulWidget {
  final bool returnProduct;
  final String? title;

  const ProductScanQrPage({
    super.key,
    this.returnProduct = false,
    this.title,
  });

  @override
  State<ProductScanQrPage> createState() => _ProductScanQrPageState();
}

class _ProductScanQrPageState extends State<ProductScanQrPage> {
  late MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _showingDialog = false;

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

  void _showErrorDialog(String message) async {
    setState(() => _showingDialog = true);
    await showDialog(
      context: context,
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
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _showingDialog = false);
      }
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty || _showingDialog) return;

    final rawValue = capture.barcodes.first.rawValue;
    final id = convertIdScanned(rawValue);

    if (id == null) {
      debugPrint('I/flutter (31273): Invalid QR');
      _showErrorDialog('Produk Tidak Ditemukan');
      return;
    }

    _isProcessing = true;

    try {
      final product = await Product.getById(id);
      if (!mounted) return;

      if (product == null) {
        _isProcessing = false;
        _showErrorDialog('Produk Tidak Ditemukan');
        return;
      }

      if (widget.returnProduct) {
        // Return product to caller (for sales page)
        Navigator.pop(context, product);
      } else {
        // Navigate to product detail
        await Navigator.pushNamed(
          context,
          '/management/product/detail',
          arguments: {'product': product},
        );

        if (mounted) {
          _isProcessing = false;
        }
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
      appBar: SapikuAppBar(title: widget.title ?? 'Scan QR Produk'),
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
