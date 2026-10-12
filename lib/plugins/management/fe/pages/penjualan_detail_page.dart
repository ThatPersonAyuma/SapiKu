import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';

class PenjualanDetailPage extends StatelessWidget {
  final String timeLabel;
  final List<({String name, int qty, String price})> items;
  final String totalLabel;
  const PenjualanDetailPage({
    super.key,
    required this.timeLabel,
    required this.items,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Detail Penjualan'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 14),
          children: [
            ClipRRect(
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
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeLabel, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 12),
                              ...items.map((it) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text('${it.name} : ${it.qty}x', style: const TextStyle(fontSize: 14, color: Colors.black87))),
                                        const SizedBox(width: 12),
                                        Text(it.price, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                      ],
                                    ),
                                  )),
                              const Divider(height: 16, thickness: 1, color: Color(0xFFE0E0E0)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text(totalLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
