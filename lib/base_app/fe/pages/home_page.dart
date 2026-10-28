import 'package:flutter/material.dart';
import 'package:sapiku/base_app/be/app.dart';
import 'package:sapiku/base_app/fe/models/available_plugin_data.dart';
import 'package:sapiku/base_app/fe/widgets/plugin_card.dart';
import 'package:sapiku/core/fe/utils/custom_icons.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/utils/db/local_handler.dart';

// class HomePage extends StatelessWidget {
//   final List<Plugin> plugins;
//   const HomePage({super.key, required this.plugins});

//   // static const _plugins = [
//   //   (
//   //     title: 'Unduh Plugin',
//   //     subtitle: 'Unduh plugin baru',
//   //     route: '/plugin-list-download',
//   //     icon: CustomIcons.at_icons_plug,
//   //     subIcon: CustomIcons.fluent_plug_connected_32_filled,
//   //     onTap: null,
//   //   ),
//   //   (
//   //     title: 'Pencatatan',
//   //     subtitle: 'Fitur pencatatan penjualan produk',
//   //     route: '/management',
//   //     icon: CustomIcons.basil_book_solid,
//   //     subIcon: CustomIcons.reicon_pen_square_filled,
//   //     onTap: PluginHandler.onManagementPlugin,
//   //   ),
//   //   (
//   //     title: 'Deteksi Penyakit',
//   //     subtitle: 'Fitur deteksi penyakit kulit sapi',
//   //     route: '/detection',
//   //     icon: CustomIcons.griddy_icons_cow_filled,
//   //     subIcon: CustomIcons.fa7_solid_cow,
//   //     onTap: null,
//   //   ),
//   // ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: const SapikuAppBar(),
//       body: AppBackground(
//         child: ListView.separated(
//           padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
//           itemCount: plugins.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 8),
//           itemBuilder: (_, i) {
//             final p = plugins[i];
//             return DownloadCard(
//               title: p.title,
//               subtitle: p.subtitle,
//               route: p.route,
//               icon: p.icon,
//               subIcon: p.subIcon,
//               onTap: p.onTap,
//             );
//           },
//         ),
//       ),
//       bottomNavigationBar: const AppBottomBar(),
//     );
//   }
// }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  List<Plugin> pluginsData = [];
  List<AvailablePluginData> plugins = [
    AvailablePluginData(
      title: 'Unduh Plugin',
      subtitle: 'Unduh plugin baru',
      route: '/plugin-list-download',
      icon: CustomIcons.at_icons_plug,
      subIcon: CustomIcons.fluent_plug_connected_32_filled,
      onTap: PluginHandler.onPluginMenu,
    ),
  ];
  // final _plugins = [
  //   (
  //     title: 'Unduh Plugin',
  //     subtitle: 'Unduh plugin baru',
  //     route: '/plugin-list-download',
  //     icon: CustomIcons.at_icons_plug,
  //     subIcon: CustomIcons.fluent_plug_connected_32_filled,
  //     onTap: null,
  //   ),
  // (
  //   title: 'Pencatatan',
  //   subtitle: 'Fitur pencatatan penjualan produk',
  //   route: '/management',
  //   icon: CustomIcons.basil_book_solid,
  //   subIcon: CustomIcons.reicon_pen_square_filled,
  //   onTap: PluginHandler.onManagementPlugin,
  // ),
  // (
  //   title: 'Deteksi Penyakit',
  //   subtitle: 'Fitur deteksi penyakit kulit sapi',
  //   route: '/detection',
  //   icon: CustomIcons.griddy_icons_cow_filled,
  //   subIcon: CustomIcons.fa7_solid_cow,
  //   onTap: null,
  // ),
  // ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<List<AvailablePluginData>> _addAvailablePluginData() async {
    final temp = [
      AvailablePluginData(
        title: 'Unduh Plugin',
        subtitle: 'Unduh plugin baru',
        route: '/plugin-list-download',
        icon: CustomIcons.at_icons_plug,
        subIcon: CustomIcons.fluent_plug_connected_32_filled,
        onTap: PluginHandler.onPluginMenu,
      ),
    ];
    for (final data in pluginsData) {
      switch (data.name) {
        case "management":
          temp.add(
            AvailablePluginData(
              title: 'Pencatatan',
              subtitle: 'Fitur pencatatan penjualan produk',
              route: '/management',
              icon: CustomIcons.basil_book_solid,
              subIcon: CustomIcons.reicon_pen_square_filled,
              onTap: PluginHandler.onManagementPlugin,
            ),
          );
          break;
        case "detection":
          temp.add(
            AvailablePluginData(
              title: 'Deteksi Penyakit',
              subtitle: 'Fitur deteksi penyakit kulit sapi',
              route: '/detection',
              icon: CustomIcons.griddy_icons_cow_filled,
              subIcon: CustomIcons.fa7_solid_cow,
              onTap: null,
            ),
          );
          break;
        default:
      }
    }
    return temp;
  }

  Future<void> load() async {
    setState(() {
      _isLoading = false;
    });
    final res = await PluginHandler.getAllReadyPlugin();
    if (res != null) {
      pluginsData = res;
      plugins = await _addAvailablePluginData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasDownloadedPlugins = pluginsData.isNotEmpty;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AppBackground(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
                itemCount: plugins.length + (hasDownloadedPlugins ? 0 : 1),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (!hasDownloadedPlugins && i == 0) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Image.asset(
                                    'assets/images/bg-sapi.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 20,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Image.asset('assets/images/logo.png'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'SAPIKU adalah sebuah aplikasi yang ditujukan untuk membantu bagian pencatatan kasir dan juga dapat membantu untuk mendeteksi penyakit lumpy pada kulit sapi dengan menggunakan kamera bawaan.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final pluginIndex = hasDownloadedPlugins ? i : i - 1;
                  final p = plugins[pluginIndex];
                  return PluginCard(
                    title: p.title,
                    subtitle: p.subtitle,
                    route: p.route,
                    icon: p.icon,
                    subIcon: p.subIcon,
                    onTap: (p.onTap != null)
                        ? (ctx, route) async {
                            await p.onTap!(ctx, route);
                            await load();
                          }
                        : null,
                  );
                },
              ),
            ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
