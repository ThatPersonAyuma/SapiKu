import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: AppColors.brown,
        border: Border(top: BorderSide(color: AppColors.greenBorder, width: 10)),
      ),
    );
  }
}
