import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_result_page.dart';
import 'package:sapiku/plugins/detection/fe/providers/detection_provider.dart';
import 'package:sapiku/plugins/detection/fe/widgets/bounding_box_painter.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _provider = DetectionProvider();
  final _picker = ImagePicker();
  File? _preview;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _provider.init();
  }

  Future<void> _pick(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 90);
    if (x == null) return;
    setState(() {
      _preview = File(x.path);
    });
  }

  Future<void> _detect() async {
    if (_preview == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih foto dulu')));
      return;
    }
    setState(() => _busy = true);
    final entry = await _provider.processImage(_preview!);
    setState(() => _busy = false);
    if (!mounted) return;
    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_provider.error ?? 'Deteksi gagal')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectionResultPage(
          imageFile: entry.imageFile,
          results: entry.results,
          metrics: entry.metrics,
          imageSize: entry.imageSize,
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
        child: Padding(
          padding: const EdgeInsets.only(
            left: 14,
            right: 14,
            top: 100,
            bottom: 14,
          ),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Expanded(child: _buildPreview()),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallBtn(
                    icon: Icons.photo_camera,
                    label: 'Kamera',
                    onTap: () => _pick(ImageSource.camera),
                  ),
                  const SizedBox(width: 16),
                  _SmallBtn(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () => _pick(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _detect,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,),
                        )
                      : const Icon(Icons.biotech, size: 26),
                  label: Text(_busy ? 'Memproses...' : 'Deteksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E2E2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }

  Widget _buildPreview() {
    if (_preview == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 48,
                color: Colors.black54,
              ),
              SizedBox(height: 8),
              Text(
                'Belum ada foto sapi',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_preview!, fit: BoxFit.cover),
          if (_provider.results.isNotEmpty && !_busy)
            CustomPaint(
              painter: BoundingBoxPainter(
                results: _provider.results,
                originalImageSize: _provider.imageSize,
              ),
            ),
          if (_busy)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label, style: TextStyle(fontSize: 18),),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
      ),
    );
  }
}
