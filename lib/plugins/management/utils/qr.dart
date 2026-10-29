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
    // 1. Buat painter QR seperti biasa
    final painter = QrPainter(
      data: id.toRadixString(36).toUpperCase(),
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      emptyColor: const Color(0xFFFFFFFF),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
    );

    // 2. Tentukan ukuran QR asli (misal: 300x300 pixel)
    const double qrSize = 300.0;
    
    // Tentukan ukuran border putih di sekitar QR (misal: 24 pixel di setiap sisi)
    const double padding = 24.0;
    
    // Total ukuran gambar akhir (QR + padding kiri-kanan & atas-bawah)
    final double totalSize = qrSize + (padding * 2);

    // 3. Render QR menjadi objek ui.Image
    final ui.Image qrImage = await painter.toImage(qrSize);

    // 4. Buat PictureRecorder untuk menggambar ulang dengan tambahan border putih
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // 5. Buat background putih seluas totalSize
    final Paint whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalSize, totalSize),
      whitePaint,
    );

    // 6. Gambar QR code di tengah-tengah (bergeser sejauh nilai padding)
    canvas.drawImage(
      qrImage,
      const Offset(padding, padding),
      Paint(),
    );

    // 7. Selesaikan rekaman canvas menjadi ui.Image baru
    final ui.Image finalImage = await recorder.endRecording().toImage(
          totalSize.toInt(),
          totalSize.toInt(),
        );

    // 8. Konversi ui.Image akhir ke format PNG ByteData
    final ByteData? byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData?.buffer.asUint8List();
  } catch (e) {
    print("Gagal membuat gambar QR dengan border: $e");
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
