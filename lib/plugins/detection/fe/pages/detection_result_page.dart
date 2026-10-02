import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';
import 'package:sapiku/plugins/detection/fe/widgets/bounding_box_painter.dart';

class DetectionResultPage extends StatelessWidget {
  final File imageFile;
  final List<DetectionResult> results;
  final ProfilingMetrics metrics;
  final Size imageSize;

  const DetectionResultPage({
    super.key,
    required this.imageFile,
    required this.results,
    required this.metrics,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Deteksi Penyakit'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(
            left: 14,
            right: 14,
            top: 100,
            bottom: 14,
          ),
          children: [
            const SizedBox(height: 48),
            _ImageWithBoxes(
              imageFile: imageFile,
              results: results,
              imageSize: imageSize,
            ),
            const SizedBox(height: 16),
            _ResultSection(results: results),
            const SizedBox(height: 12),
            _MetricsCard(metrics: metrics),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        color: Color(0xFF2E2E2E),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E2E2E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.popUntil(
                      context,
                      (r) => r.settings.name == '/detection' || r.isFirst,
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}

class _ImageWithBoxes extends StatelessWidget {
  final File imageFile;
  final List<DetectionResult> results;
  final Size imageSize;
  const _ImageWithBoxes({
    required this.imageFile,
    required this.results,
    required this.imageSize,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: imageSize.width == 0 || imageSize.height == 0
            ? 1
            : imageSize.width / imageSize.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(imageFile, fit: BoxFit.cover),
            CustomPaint(
              painter: BoundingBoxPainter(
                results: results,
                originalImageSize: imageSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final List<DetectionResult> results;
  const _ResultSection({required this.results});
  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Tidak ada lesi terdeteksi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return Column(
      children: results
          .map(
            (r) => Card(
              color: Colors.white,
              child: ListTile(
                title: Text(
                  r.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'YOLO ${(r.yoloScore * 100).toStringAsFixed(1)}% • Klasifikasi ${(r.classificationScore * 100).toStringAsFixed(1)}%',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(r.classificationScore * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final ProfilingMetrics metrics;
  const _MetricsCard({required this.metrics});
  @override
  Widget build(BuildContext context) {
    TextStyle s = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontFamily: 'monospace',
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metrik',
            style: TextStyle(
              color: Colors.yellowAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('YOLO     : ${metrics.yoloTimeMs} ms', style: s),
          Text('Crop     : ${metrics.cropTimeMs} ms', style: s),
          Text('MobileNet: ${metrics.mobileNetTimeMs} ms', style: s),
          const Divider(color: Colors.white24),
          Text(
            'Total    : ${metrics.totalTimeMs} ms',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
