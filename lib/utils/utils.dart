import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
      builder: (context) => AlertDialog(
        title: Text(getTitleValue(title)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
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
    Widget cancelButton = ElevatedButton(
      child: Text("Cancel"),
      onPressed: () {
        // returnValue = false;
        Navigator.of(navigatorKey.currentContext!).pop(false);
      },
    );
    Widget continueButton = ElevatedButton(
      child: Text("Continue"),
      onPressed: () {
        // returnValue = true;
        Navigator.of(navigatorKey.currentContext!).pop(true);
      },
    ); // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(getTitleValue(title)),
      content: Text(message),
      actions: [cancelButton, continueButton],
    ); // show the dialog
    final result = await showDialog<bool?>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return alert;
      },
    );
    return result ?? false;
  }
}
