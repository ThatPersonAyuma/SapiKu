import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/widgets/plugin_card.dart';
import 'package:sapiku/core/fe/utils/custom_icons.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _plugins = [
    (title: 'Unduh Plugin', subtitle: 'Unduh plugin baru', route: '/plugin-list-download', icon: CustomIcons.at_icons_plug, subIcon: CustomIcons.fluent_plug_connected_32_filled),
    (title: 'Pencatatan', subtitle: 'Fitur pencatatan penjualan produk', route: '/management', icon: CustomIcons.basil_book_solid, subIcon: CustomIcons.reicon_pen_square_filled),
    (title: 'Deteksi Penyakit', subtitle: 'Fitur deteksi penyakit kulit sapi', route: '/detection', icon: CustomIcons.griddy_icons_cow_filled, subIcon: CustomIcons.fa7_solid_cow),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(),
      body: AppBackground(
        child: ListView.separated(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
          itemCount: _plugins.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = _plugins[i];
            return PluginCard(title: p.title, subtitle: p.subtitle, route: p.route, icon: p.icon, subIcon: p.subIcon);
          },
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
