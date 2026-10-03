import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/widgets/plugin_card.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';

class DetectionMenuPage extends StatelessWidget {
  const DetectionMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Deteksi Penyakit'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
          children: [
            PluginCard(
              title: 'Foto',
              subtitle: 'Ambil foto sapi untuk deteksi',
              route: '/detection/camera',
              icon: Icons.photo_camera,
              subIcon: Icons.camera_alt_rounded,
            ),
            const SizedBox(height: 8),
            PluginCard(
              title: 'Riwayat Deteksi',
              subtitle: 'Lihat hasil deteksi sebelumnya',
              route: '/detection/history',
              icon: Icons.history_rounded,
              subIcon: Icons.receipt_long_rounded,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
