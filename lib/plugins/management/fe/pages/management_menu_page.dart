import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/widgets/plugin_card.dart';
import 'package:sapiku/core/fe/utils/custom_icons.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';

class ManagementMenuPage extends StatelessWidget {
  const ManagementMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Pencatatan'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
          children: [
            PluginCard(
              title: 'Pencatatan Produk',
              subtitle: 'Kelola pencatatan produk',
              route: '/management/pencatatan',
              icon: CustomIcons.fluent_notebook_32_filled,
              subIcon: CustomIcons.game_icons_notebook,
            ),
            const SizedBox(height: 8),
            PluginCard(
              title: 'Penjualan Produk',
              subtitle: 'Kelola transaksi penjualan produk',
              route: '/management/penjualan',
              icon: CustomIcons.fluent_building_retail_more_32_filled,
              subIcon: CustomIcons.fa7_solid_cash_register,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
