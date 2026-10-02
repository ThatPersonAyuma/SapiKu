import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_result_page.dart';
import 'package:sapiku/plugins/detection/fe/providers/detection_provider.dart';
import 'package:sapiku/plugins/detection/fe/widgets/history_card.dart';

class DetectionHistoryPage extends StatefulWidget {
  const DetectionHistoryPage({super.key});
  @override
  State<DetectionHistoryPage> createState() => _DetectionHistoryPageState();
}

class _DetectionHistoryPageState extends State<DetectionHistoryPage> {
  final _provider = DetectionProvider();
  String _fmt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} • ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Deteksi Penyakit'),
      body: AppBackground(
        child: ListenableBuilder(
          listenable: _provider,
          builder: (_, __) {
            final h = _provider.history;
            if (h.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 140), child: Text('Belum ada riwayat', style: TextStyle(color: Colors.black))));
            return ListView.separated(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 14),
              itemCount: h.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = h[i];
                return HistoryCard(imageFile: e.imageFile, result: e.primaryLabel, confidence: e.primaryConfidence, dateLabel: _fmt(e.date),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetectionResultPage(imageFile: e.imageFile, results: e.results, metrics: e.metrics, imageSize: e.imageSize))));
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
