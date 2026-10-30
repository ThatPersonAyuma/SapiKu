import 'package:flutter/material.dart';
import 'package:sapiku/base_app/be/app.dart';
import 'package:sapiku/base_app/fe/models/download_plugin_data.dart';
import 'package:sapiku/base_app/fe/widgets/download_element.dart';
import 'package:sapiku/core/fe/utils/custom_icons.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';

class DownloadPage extends StatefulWidget {
  List<PluginConf> pluginConfs = [];
  DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPage();
}

class _DownloadPage extends State<DownloadPage> {
  List<DownloadPluginData> plugins = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });
    final res = await CloudHandler.getPluginData();
    if (res == null) {
      if (mounted) {
        Navigator.pop(context);
        return;
      }
    } else {
      widget.pluginConfs = res;
      final availableRes = await _addAvailablePluginData();
      setState(() {
        plugins = availableRes;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<DownloadPluginData>> _addAvailablePluginData() async {
    List<DownloadPluginData> temp = [];
    for (final data in widget.pluginConfs) {
      switch (data.name) {
        case "management":
          temp.add(
            DownloadPluginData(
              title: 'Pencatatan',
              subtitle: 'Unduh plugin',
              name: data.name,
              icon: CustomIcons.basil_book_solid,
              downloadCallback: PluginHandler.manageEnsurePlugin,
              removeCallback: PluginHandler.deleteManagementPlugin,
              plugin: await Plugin.getFromByName(data.name),
              version: data.version
            ),
          );
          break;
        case "detection":
          temp.add(
            DownloadPluginData(
              title: 'Deteksi Penyakit',
              subtitle: 'Fitur deteksi penyakit kulit sapi',
              name: data.name,
              icon: CustomIcons.griddy_icons_cow_filled,
              downloadCallback: PluginHandler.detectionEnsurePlugin,
              removeCallback: PluginHandler.deleteDetectionPlugin,
              plugin: await Plugin.getFromByName(data.name),
              version: data.version
            ),
          );
          break;
        default:
      }
    }
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(),
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
                itemCount: plugins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = plugins[i];
                  return DownloadCard(
                    title: p.title,
                    name: p.name,
                    subtitle: p.subtitle,
                    icon: p.icon,
                    downloadCallback: p.downloadCallback,
                    removeCallback: p.removeCallback,
                    plugin: p.plugin,
                    version: p.version
                  );
                },
              ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
