import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/detection/be/be_app.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';

class DetectionHistoryDetailPage extends StatefulWidget {
  final DeasesDetection detection;
  const DetectionHistoryDetailPage({
    super.key,
    required this.detection,
  });

  @override
  State<DetectionHistoryDetailPage> createState() => _DetectionHistoryDetailPageState();
}

class _DetectionHistoryDetailPageState extends State<DetectionHistoryDetailPage> {
  late Future<List<Scan>?> _scansFuture;
  String? _careMethod;
  bool _loadingCare = true;

  @override
  void initState() {
    super.initState();
    _scansFuture = widget.detection.getScans();
    _loadCareMethod();
  }

  Future<void> _loadCareMethod() async {
    final scans = await widget.detection.getScans();
    if (scans != null && scans.isNotEmpty) {
      final deases = await Deases.getByName(scans.first.detectionResult);
      if (mounted) {
        setState(() {
          _careMethod = deases?.solution ?? 'Tidak ada rekomendasi tersedia';
          _loadingCare = false;
        });
      }
    }
  }

  bool _isDatetimeName(String name) {
    try {
      DateTime.parse(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Detail Riwayat Deteksi'),
      body: AppBackground(
        child: FutureBuilder<List<Scan>?>(
          future: _scansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 140),
                  child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)),
                ),
              );
            }

            final scans = snapshot.data ?? [];
            if (scans.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 140),
                  child: Text('Tidak ada data deteksi', style: TextStyle(color: Colors.black54)),
                ),
              );
            }

            final primaryScan = scans.first;

            return ListView(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 14),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isDatetimeName(widget.detection.name))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.detection.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      Text(
                        _fmt(widget.detection.datetime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (File(widget.detection.imagePath).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.detection.imagePath),
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hasil Deteksi:',
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
                          '${(primaryScan.confident * 100).toStringAsFixed(0)}%',
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
                          value: primaryScan.confident,
                          minHeight: 15,
                          backgroundColor: Colors.lightGreen[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        primaryScan.detectionResult,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF158900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (scans.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deteksi Lainnya:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...scans.skip(1).map((scan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  scan.detectionResult,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '${(scan.confident * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.brown,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Berdasarkan Hasil Deteksi Ditemukan Bahwa Sapi Terdampak penyakit ${primaryScan.detectionResult} Berikut adalah penanganan awal sebelum lebih parah:',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _loadingCare
                            ? const CircularProgressIndicator()
                            : Text(
                                _careMethod ?? 'Tidak ada rekomendasi tersedia',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.6,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
