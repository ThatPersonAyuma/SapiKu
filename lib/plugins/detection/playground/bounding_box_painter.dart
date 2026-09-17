import 'package:flutter/material.dart';
import 'cascade_pipeline.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> results;
  final Size originalImageSize;

  BoundingBoxPainter({required this.results, required this.originalImageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (originalImageSize.width == 0 || originalImageSize.height == 0) return;

    final double scaleX = size.width / originalImageSize.width;
    final double scaleY = size.height / originalImageSize.height;

    final Paint boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint bgPaint = Paint()..color = Colors.black.withOpacity(0.7);

    for (var res in results) {
      Rect scaledBox = Rect.fromLTRB(
        res.boundingBox.left * scaleX,
        res.boundingBox.top * scaleY,
        res.boundingBox.right * scaleX,
        res.boundingBox.bottom * scaleY,
      );

      // Gambar Bounding Box
      canvas.drawRect(scaledBox, boxPaint);

      // Label Teks
      String text = "${res.label} (${(res.classificationScore * 100).toStringAsFixed(1)}%)";
      TextSpan span = TextSpan(
        text: text, 
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
      );
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      // Background untuk teks
      Rect bgRect = Rect.fromLTWH(scaledBox.left, scaledBox.top - 20, tp.width + 8, tp.height + 4);
      canvas.drawRect(bgRect, bgPaint);
      tp.paint(canvas, Offset(scaledBox.left + 4, scaledBox.top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}