import 'package:flutter/material.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/utils.dart';

class PluginHandler {
  static Future<bool> getManagementPlugin() async {
    // Start of Before Update With ShoreBird
    if (!await canUpdateManagePlugin()) {
      return false;
    }
    // await managementSetup(); // Download Method
    // End of Before Update With ShoreBird
    // Start of After Update With ShoreBird
    return await managementSetup();
    // End of After Update With ShoreBird
  }

  static Future<bool> canUpdateManagePlugin() async {
    final internetExist = await checkInternetConnection();
    if (!internetExist) {
      PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Tidak dapat terhubung ke internet. Silakan periksa koneksi internet anda.",
      );
      return false;
    }
    return true;
  }

  static Future<bool> getDetectionPlugin() async {
    return true;
  }

  static Future<void> detectionEnsurePlugin() async {}

  static Future<bool> manageEnsurePlugin() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM plugins WHERE name = ?",
      [managementName],
    );
    if (res == null) return false; //Error
    if (res.isEmpty) {
      // Meaning it's not setup yet
      final isDownload = await PopUpMessage.showYesNoMessage(
        """Plugin pencatatan berisi pencatatan produk dan penjualan. Apakah anda ingin mengunduh plugin Pencatatan?""",
      );
      if (isDownload) {
        return await getManagementPlugin();
      } else {
        return false;
      }
    } else {
      // Already setup
      final plugin = Plugin.createFromMap(res[0]);
      plugin.isActive = true;
      await plugin.saveToDb();
    }
    return true;
  }

  /// This called when the plugin management button get pressed on plugin menu
  static Future<void> onManagementPlugin(
    BuildContext context,
    String route,
  ) async {
    final res = await manageEnsurePlugin();
    print("Plugin Res: $res, ismounted ${context.mounted}");
    if (res && context.mounted) {
      Navigator.pushNamed(context, route);
      PopUpMessage.showOkMessage(PopUpTitle.success, "Plugin Pencatatan berhasil ditambahkan.");
    }
  }
}
