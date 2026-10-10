import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';

class PenjualanCard extends StatelessWidget {
  final String timeLabel;
  final String totalLabel;
  final VoidCallback? onDetailTap;
  const PenjualanCard({super.key, required this.timeLabel, required this.totalLabel, this.onDetailTap});

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(timeLabel, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                          Text(totalLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onDetailTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkCard,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Lihat Detail'),
                        ),
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
  }
}
