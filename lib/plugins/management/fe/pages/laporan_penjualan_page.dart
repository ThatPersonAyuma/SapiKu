import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/plugin.dart';
import 'package:sapiku/plugins/management/be/report.dart' show ProductReport;
import 'package:sapiku/plugins/management/be/report.dart';

class LaporanPenjualanPage extends StatelessWidget {
  const LaporanPenjualanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 75;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Laporan Penjualan'),
      body: AppBackground(
        child: Column(
          children: [
            SizedBox(height: topOffset + 12),
            const Expanded(child: _PenjualanReportTab()),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}

class _PenjualanReportTab extends StatefulWidget {
  const _PenjualanReportTab();

  @override
  State<_PenjualanReportTab> createState() => _PenjualanReportTabState();
}

class _PenjualanReportTabState extends State<_PenjualanReportTab> {
  static final DateTime _allTimeStart = DateTime(2000, 1, 1);

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _allTime = false;
  List<Map<String, Object?>> _records = [];
  bool _loading = false;
  bool _downloading = false;

  DateTime get _effectiveStart => _allTime ? _allTimeStart : _startDate;
  DateTime get _effectiveEnd => _allTime ? DateTime.now() : _endDate;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final records = await Report.getTransactionReportShow(
      _effectiveStart,
      _effectiveEnd,
    );
    if (mounted) {
      setState(() {
        _records = records ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _loadReport();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _loadReport();
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _downloading = true);
    try {
      final success = await Report.saveReport(_effectiveStart, _effectiveEnd);
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

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _rp(int v) => 'Rp ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 8, bottom: 14),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Periode Laporan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _allTime ? null : _pickStartDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _allTime ? Colors.grey.shade200 : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _fmtDate(_startDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _allTime ? Colors.grey.shade400 : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          's/d',
                          style: TextStyle(
                            fontSize: 13,
                            color: _allTime ? Colors.grey.shade400 : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _allTime ? null : _pickEndDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _allTime ? Colors.grey.shade200 : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _fmtDate(_endDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _allTime ? Colors.grey.shade400 : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Checkbox(
                            value: _allTime,
                            activeColor: AppColors.darkCard,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (value) {
                              setState(() => _allTime = value ?? false);
                              _loadReport();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Sepanjang Masa',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_records.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      _allTime
                          ? 'Belum ada data penjualan'
                          : 'Tidak ada penjualan pada periode ini',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                ..._records.map((record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal: ${(record["datetime"] as DateTime).day.toString().padLeft(2, '0')}/${(record["datetime"] as DateTime).month.toString().padLeft(2, '0')}/${(record["datetime"] as DateTime).year}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ${_rp((record["total_price"] as double).toInt())}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _rp((record["total_price"] as double).toInt()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            ],
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
    );
  }
}
