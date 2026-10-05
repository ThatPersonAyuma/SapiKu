import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Source - https://stackoverflow.com/a/72848135
// Posted by MendelG
// Retrieved 2026-09-24, License - CC BY-SA 4.0

final GlobalKey qrKey = GlobalKey();

Widget buildQRImage(String idStr) {
  return RepaintBoundary(
    key: qrKey,
    child: QrImageView(
      data: int.parse(idStr).toRadixString(36).toUpperCase(),
      version: 1,
      size: 80.0,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      backgroundColor: Colors.white,
    ),
  );
}

Future<Uint8List?> getQrPngbyId(int id) async {
  try {
    final painter = QrPainter(
      data: id.toRadixString(36).toUpperCase(),
      version: 1,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: false,
      eyeStyle: const QrEyeStyle(
        color: Color(0xFF000000)
      ),
    );

    // Render ke bentuk Image dengan ukuran tertentu (misal: 300x300)
    final byteData = await painter.toImageData(
      300.0,
      format: ui.ImageByteFormat.png,
    );

    return byteData?.buffer.asUint8List();
  } catch (e) {
    print("Gagal membuat gambar QR: $e");
    return null;
  }
}


Future<Uint8List?> getQrPng() async {
  final boundary =
      qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

  if (boundary == null) return null;

  final ui.Image image = await boundary.toImage(pixelRatio: 10);

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData?.buffer.asUint8List();
}

/// Use this to save QR to Gallery
Future<bool> saveQrToGallery() async {
  try {
    if (!await Gal.hasAccess()) {
      final granted = await Gal.requestAccess();

      if (!granted) {
        return false;
      }
    }

    final bytes = await getQrPng();

    if (bytes == null) {
      return false;
    }

    await Gal.putImageBytes(
      bytes,
      name: 'qr_${DateTime.now().millisecondsSinceEpoch}',
    );

    return true;
  } catch (e) {
    debugPrint('Save QR error: $e');
    return false;
  }
}
Future<bool> saveQr() async {
  Uint8List? imageInUnit8List = await getQrPng();
  if (imageInUnit8List == null) {
    return false;
  }
  final tempDir = await getTemporaryDirectory();
  File file = await File('${tempDir.path}/image.png').create();
  file.writeAsBytesSync(imageInUnit8List);
  return true;
}

int? convertIdScanned(String? idStr) {
  if (idStr == null || idStr.isEmpty) {
    return null;
  }

  return int.tryParse(idStr, radix: 36);
}


class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;
    final id = convertIdScanned(rawValue);

    if (id == null) {
      debugPrint('Invalid QR');
      return;
    }

    _isProcessing = true;

    Navigator.pop(context, id);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: MobileScannerController(
          formats: const [
            BarcodeFormat.qrCode,
          ],
        ),
        onDetect: _onDetect,
      ),
    );
  }
}

// class GenerateScreen extends StatelessWidget {
//   final int id;
//   const GenerateScreen({required this.id, super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Buat QR Code')),
//       body: Center(
//         child: QrImageView(
//           data: this.id
//               .toRadixString(36)
//               .toUpperCase(), // Data yang ingin di-encode
//           version: 1,
//           size: 80.0,
//           errorCorrectionLevel: QrErrorCorrectLevel.Q,
//           backgroundColor: Colors.white,
//         ),
//       ),
//     );
//   }
// }
