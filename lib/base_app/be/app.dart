import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/pages/download_plugin.dart';
import 'package:sapiku/plugins/detection/be/be_app.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/utils.dart';

class PluginHandler {
  static Future<List<Plugin>?> getAllReadyPlugin() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM ${Plugin.tableName} WHERE is_setup=?",
      [1],
    );
    if (res == null) return null;
    return [for (final map in res) Plugin.createFromMap(map)];
  }

  static Future<bool> getManagementPlugin(VoidCallback callback, String version) async {
    // Start of Before Update With ShoreBird
    if (!await canUpdatePlugin()) {
      return false;
    }
    // await managementSetup(); // Download Method
    // End of Before Update With ShoreBird
    // Start of After Update With ShoreBird
    callback();
    return await ManagementPlugin.managementSetup(callback, version);
    // End of After Update With ShoreBird
  }

  static Future<bool> canUpdatePlugin() async {
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

  static Future<bool> getDetectionPlugin(VoidCallback callback, String version) async {
    // Start of Before Update With ShoreBird
    if (!await canUpdatePlugin()) {
      return false;
    }
    // await managementSetup(); // Download Method
    // End of Before Update With ShoreBird
    // Start of After Update With ShoreBird
    callback();
    return await DetectionPlugin.detectionSetup(callback, version);
    // End of After Update With ShoreBird
  }

  static Future<bool> detectionEnsurePlugin(VoidCallback callback, String version) async {
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM plugins WHERE name = ?",
      [DetectionPlugin.detectionName],
    );
    if (res == null) return false; //Error
    if (res.isEmpty || (res.isNotEmpty && (res[0]['is_setup'] as int) == 0)) {
      // Meaning it's not setup yet
      final isDownload = await PopUpMessage.showYesNoMessage(
        """Plugin deteksi penyakit berisi fitur deteksi penyakit kulit sapi. Apakah anda ingin mengunduh plugin Deteksi Penyakit?""",
      );
      if (isDownload) {
        callback();
        final downRes = await getDetectionPlugin(callback, version);
        return downRes;
      } else {
        return false;
      }
    } else {
      // Already setup
    }
    return true;
  }

  static Future<bool> manageEnsurePlugin(VoidCallback callback, String version) async {
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM plugins WHERE name = ?",
      [ManagementPlugin.managementName],
    );
    if (res == null) return false; //Error
    if (res.isEmpty || (res.isNotEmpty && (res[0]['is_setup'] as int) == 0)) {
      // Meaning it's not setup yet
      final isDownload = await PopUpMessage.showYesNoMessage(
        """Plugin pencatatan berisi pencatatan produk dan penjualan. Apakah anda ingin mengunduh plugin Pencatatan?""",
      );
      if (isDownload) {
        callback();
        final downRes = await getManagementPlugin(callback, version);
        return downRes;
      } else {
        return false;
      }
    } else {
      // Already setup
    }
    return true;
  }

  /// Delete all data for managements.
  /// Meaning it will lost all of the data that known by system.
  /// Excluding report because it is not tracked
  static Future<void> deleteManagementPlugin() async {
    final plugin = await Plugin.getFromByName(ManagementPlugin.managementName);
    if (plugin == null) {
      PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Data plugin pencatatan tidak ditemukan.",
      );
      return;
    }
    // Delete all of the management data
    final bool isDeleted = await ManagementPlugin.managementDelete();
    if (!isDeleted) {
      PopUpMessage.showOkMessage(PopUpTitle.error, "Gagal menghapus data Plugin Pencatatan.");
      return;
    }
    plugin.isSetup = false;
    await plugin.saveToDb();
    PopUpMessage.showOkMessage(
      PopUpTitle.success,
      "Plugin Pencatatan berhasil dihapus.",
    );
  }

  /// This called when the plugin management button get pressed on plugin menu
  static Future<void> onManagementPlugin(
    BuildContext context,
    String route,
  ) async {
    final res = await manageEnsurePlugin(() {},"");
    if (res && context.mounted) {
      Navigator.pushNamed(context, route);
    }
  }

  static Future<void> onDetectionPlugin(
    BuildContext context,
    String route,
  ) async {
    final res = await detectionEnsurePlugin(() {},"");
    print("Plugin Res: $res, ismounted ${context.mounted}");
    if (res && context.mounted) {
      Navigator.pushNamed(context, route);
    }
  }

  /// Delete all data for detection.
  /// Meaning it will lost all of the data that known by system.
  /// Including the model
  static Future<void> deleteDetectionPlugin() async {
    final plugin = await Plugin.getFromByName(DetectionPlugin.detectionName);
    if (plugin == null) {
      PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Data plugin Deteksi tidak ditemukan.",
      );
      return;
    }
    // Delete all of the management data
    final bool isDeleted = await DetectionPlugin.detectionDelete();
    if (!isDeleted) {
      PopUpMessage.showOkMessage(PopUpTitle.error, "Gagal menghapus data Plugin Deteksi.");
      return;
    }
    plugin.isSetup = false;
    await plugin.saveToDb();
    PopUpMessage.showOkMessage(
      PopUpTitle.success,
      "Plugin Deteksi berhasil dihapus.",
    );
  }

  static Future<void> onPluginMenu(BuildContext context, String route) async {
    if (!await checkInternetConnection()) {
      PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Tidak dapat terhubung ke internet. Silakan periksa koneksi internet anda.",
      );
      return;
    }
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => DownloadPage(),
        ),
      );
    }
  }
}
