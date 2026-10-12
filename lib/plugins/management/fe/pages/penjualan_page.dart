import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/fe/widgets/penjualan_card.dart';
import 'package:sapiku/plugins/management/fe/widgets/penjualan_fab_menu.dart';

class PenjualanPage extends StatelessWidget {
  const PenjualanPage({super.key});

  static const _data = [
    (
      time: '10:30 - 12 Januari 2025',
      total: 'Rp 150.000',
      items: <({String name, int qty, String price})>[
        (name: 'Susu Segar 1L', qty: 2, price: 'Rp 30.000'),
        (name: 'Susu tachyon 500ml', qty: 1, price: 'Rp 25.000'),
        (name: 'Susu uma 250g', qty: 1, price: 'Rp 65.000'),
      ],
    ),
    (
      time: '14:15 - 11 Januari 2025',
      total: 'Rp 275.500',
      items: <({String name, int qty, String price})>[
        (name: 'Susu Segar 1L', qty: 5, price: 'Rp 75.000'),
        (name: 'Susu tachyon 500ml', qty: 3, price: 'Rp 75.000'),
        (name: 'Susu uma 250g', qty: 2, price: 'Rp 125.500'),
      ],
    ),
    (
      time: '09:00 - 10 Januari 2025',
      total: 'Rp 89.000',
      items: <({String name, int qty, String price})>[
        (name: 'Susu Segar 1L', qty: 1, price: 'Rp 15.000'),
        (name: 'Susu tachyon 500ml', qty: 2, price: 'Rp 50.000'),
        (name: 'Susu uma 250g', qty: 1, price: 'Rp 24.000'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Daftar Penjualan'),
      body: Stack(
        children: [
          AppBackground(
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 90),
              itemCount: _data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final d = _data[i];
                return PenjualanCard(
                  timeLabel: d.time,
                  totalLabel: d.total,
                  onDetailTap: () => Navigator.pushNamed(
                    context,
                    '/management/penjualan/detail',
                    arguments: {'time': d.time, 'items': d.items, 'total': d.total},
                  ),
                );
              },
            ),
          ),
          PenjualanFabMenu(
            onTambah: () => Navigator.pushNamed(context, '/management/penjualan/tambah'),
            onLaporan: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan Penjualan')));
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
