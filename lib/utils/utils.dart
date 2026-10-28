import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/main.dart';

int boolToInt(bool a) => a ? 1 : 0;

DateTime strToDateTime(String datetime) {
  return DateTime.parse(datetime);
}

/// A method to download a file from public google drive.
/// Only works for file under 100mb. Larger file can trigger google virus scan which redirect to a web page instead of just download the file
Future<File?> downloadPublicFile(
  String fileId,
  String prefix,
  String fileName,
) async {
  final url = Uri.parse(
    'https://drive.google.com/uc?export=download&id=$fileId',
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$prefix/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
  } catch (e) {
    // Penanganan kesalahan
  }
  return null;
}

/// Same as downloadPublicFile but it is for Zip file which will be unzip to the target directory
Future<bool> downloadAndUnzip(String fileId, String prefix) async {
  final url = Uri.parse(
    'https://drive.google.com/uc?export=download&id=$fileId',
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Dekode berkas ZIP langsung dari array byte di memori
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      final destinationDir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        final filename = file.name;
        final extractPath = '${destinationDir.path}/$prefix/$filename';

        if (file.isFile) {
          final data = file.content as List<int>;
          print('model path: $extractPath');
          File(extractPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(extractPath).createSync(recursive: true);
        }
      }
      return true;
    }
    return false;
  } catch (e) {
    PopUpMessage.showOkMessage(
      PopUpTitle.error,
      "Terjadi kesalahan ketika mencoba mengunduh zip asset",
    );
    return false;
  }
}

/// Check connection internet by try to access example.com
Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('connected');
      return true;
    }
    return false;
  } on SocketException catch (_) {
    print('not connected');
    return false;
  }
}

enum PopUpTitle { error, warning, success, confirmation }

/// Class that provide static method for showing pop up message
class PopUpMessage {
  static String getTitleValue(PopUpTitle title) {
    switch (title) {
      case PopUpTitle.error:
        return "Terjadi Kesalahan";
      case PopUpTitle.warning:
        return "Peringatan";
      case PopUpTitle.success:
        return "Berhasil";
      case PopUpTitle.confirmation:
        return "Konfirmasi";
    }
  }

  /// Show message with only ok option. Return void as this is only used for giving the user a message
  static Future<void> showOkMessage(PopUpTitle title, String message) async {
    await showDialog(
      context: navigatorKey.currentContext!,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greenBorder, width: 2),
              ),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTitleValue(title),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show message with ok or yes option. Return bool.
  /// This is used for getting confirmation from the user before doing some action.
  /// Therefore the title default value is confirmation.
  static Future<bool> showYesNoMessage(
    String message, {
    PopUpTitle title = PopUpTitle.confirmation,
  }) async {
    final result = await showDialog<bool?>(
      context: navigatorKey.currentContext!,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greenBorder, width: 2),
              ),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTitleValue(title),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkCard,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Ya'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Show success message with two options: Selesai (navigate to home) and Tutup (close dialog)
  static Future<void> showDownloadSuccessMessage(
    String pluginTitle,
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greenBorder, width: 2),
              ),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTitleValue(PopUpTitle.success),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Plugin $pluginTitle berhasil diunduh',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Tutup'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkCard,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Selesai'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
