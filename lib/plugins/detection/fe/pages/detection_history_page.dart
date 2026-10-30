import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/detection/be/be_app.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_history_detail_page.dart';
import 'package:sapiku/plugins/detection/fe/widgets/history_card.dart';

class DetectionHistoryPage extends StatefulWidget {
  const DetectionHistoryPage({super.key});
  @override
  State<DetectionHistoryPage> createState() => _DetectionHistoryPageState();
}

class _DetectionHistoryPageState extends State<DetectionHistoryPage> {
  late Future<List<DeasesDetection>?> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = DeasesDetection.getAll();
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Riwayat Deteksi'),
      body: AppBackground(
        child: FutureBuilder<List<DeasesDetection>?>(
          future: _historyFuture,
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
            final history = snapshot.data;
            if (history == null || history.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 140),
                  child: Text('Belum ada riwayat deteksi', style: TextStyle(color: Colors.black54)),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 14),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = history[i];
                return FutureBuilder<List<Scan>?>(
                  future: item.getScans(),
                  builder: (context, scansSnapshot) {
                    if (scansSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final scans = scansSnapshot.data ?? [];
                    final label = scans.isNotEmpty ? scans.first.detectionResult : 'Tidak terdeteksi';
                    final confidence = scans.isNotEmpty ? scans.first.confident : 0.0;

                    return HistoryCard(
                      imageFile: File(item.imagePath),
                      result: label,
                      confidence: confidence,
                      dateLabel: _fmt(item.datetime),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetectionHistoryDetailPage(
                              detection: item,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
