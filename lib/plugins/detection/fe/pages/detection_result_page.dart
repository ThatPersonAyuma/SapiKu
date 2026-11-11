import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_recommendation_page.dart';
import 'package:sapiku/plugins/detection/be/be_app.dart';
import 'package:sapiku/plugins/detection/fe/widgets/bounding_box_painter.dart';

class DetectionResultPage extends StatefulWidget {
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
  State<DetectionResultPage> createState() => _DetectionResultPageState();
}

class _DetectionResultPageState extends State<DetectionResultPage> {
  Future<void> _handleSave() async {
    final nameCtrl = TextEditingController();

    await showDialog(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simpan Hasil Deteksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nama Hasil (Opsional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama hasil deteksi',
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
                        try {
                          String? name = nameCtrl.text.trim().isEmpty
                              ? null
                              : nameCtrl.text.trim();

                          await DeasesDetection.create(
                            XFile(widget.imageFile.path),
                            widget.results,
                            name,
                          );

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hasil deteksi berhasil disimpan')),
                          );
                          
                          if (mounted) {
                            Navigator.popUntil(
                              context,
                              (r) => r.settings.name == '/detection' || r.isFirst,
                            );
                          }
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan: $e')),
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
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
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
                'Simpan Hasil?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apakah Anda ingin menyimpan hasil deteksi ini?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.popUntil(
                        context,
                        (r) => r.settings.name == '/detection' || r.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Tidak'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleSave();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCard,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Ya'),
                  ),
                ],
              ),
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
              imageFile: widget.imageFile,
              results: widget.results,
              imageSize: widget.imageSize,
            ),
            const SizedBox(height: 16),
            _ResultSection(results: widget.results),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetectionRecommendationPage(
                            results: widget.results,
                            imageFile: XFile(widget.imageFile.path),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Detail',
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
                    onPressed: _showConfirmDialog,
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
    final primary = results.first;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Deteksi :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Text(
              '${(primary.classificationScore * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: primary.classificationScore,
              minHeight: 15,
              backgroundColor: Colors.lightGreen[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Result text
          Text(
            CascadePipeline.getTextResult(primary),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF158900),
              height: 1.5,
            ),
          ),
        ],
      ),
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
