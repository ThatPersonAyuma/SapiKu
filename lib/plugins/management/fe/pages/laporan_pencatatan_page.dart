import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';

class LaporanPencatatanPage extends StatefulWidget {
  const LaporanPencatatanPage({super.key});

  @override
  State<LaporanPencatatanPage> createState() => _LaporanPencatatanPageState();
}

class _LaporanPencatatanPageState extends State<LaporanPencatatanPage> {
  List<ProductReport> _reports = [];
  bool _loading = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final reports = await ManageUtils.createProdReport(startOfMonth, now);
    if (mounted) {
      setState(() {
        _reports = reports ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _downloading = true);
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final success = await ManageUtils.saveProductReport(startOfMonth, now, reportData: _reports);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Laporan berhasil diunduh' : 'Gagal mengunduh laporan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  String _rp(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Laporan Pencatatan Produk'),
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? ListView(
                      padding: const EdgeInsets.only(top: 140),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                      ],
                    )
                  : _reports.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.only(top: 140),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data pencatatan produk', style: TextStyle(color: Colors.black54)))),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 14),
                          itemCount: _reports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final report = _reports[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(top: 12, bottom: 12),
                                                child: Text(
                                                  report.name,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                              ),
                                              const Divider(height: 0, thickness: 0.5),
                                              const SizedBox(height: 14),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Terjual: ${report.selledQuantity}x',
                                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.darkCard,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${report.selledQuantity}x',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(width: 10, color: AppColors.greenBorder),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : _downloadReport,
                  icon: _downloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: const Text(
                    'Unduh Laporan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCard,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
