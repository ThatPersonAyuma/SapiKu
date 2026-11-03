import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';
import 'package:sapiku/plugins/detection/be/be_app.dart';

class DetectionRecommendationPage extends StatefulWidget {
  final List<DetectionResult> results;
  final XFile? imageFile;
  const DetectionRecommendationPage({
    super.key,
    required this.results,
    this.imageFile,
  });

  @override
  State<DetectionRecommendationPage> createState() => _DetectionRecommendationPageState();
}

class _DetectionRecommendationPageState extends State<DetectionRecommendationPage> {
  String? _careMethod;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCareMethod();
  }

  Future<void> _loadCareMethod() async {
    if (widget.results.isNotEmpty) {
      final method = await CascadePipeline.getCareMethod(widget.results.first);
      if (mounted) {
        setState(() {
          _careMethod = method;
          _loading = false;
        });
      }
    }
  }

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

                          if (widget.imageFile != null) {
                            await DeasesDetection.create(
                              widget.imageFile!,
                              widget.results,
                              name,
                            );
                          }

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

  @override
  Widget build(BuildContext context) {
    final disease = widget.results.isNotEmpty ? widget.results.first.label : 'Penyakit';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Rekomendasi dan Saran'),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 14),
                children: [
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
                            'Berdasarkan Hasil Deteksi Ditemukan Bahwa Sapi Terdampak penyakit $disease Berikut adalah penanganan awal sebelum lebih parah:',
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
                          child: Text(
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan Hasil Deteksi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}

