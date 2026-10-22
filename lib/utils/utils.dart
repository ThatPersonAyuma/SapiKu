import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sapiku/main.dart';

int boolToInt(bool a) => a ? 1 : 0;

DateTime strToDateTime(String datetime) {
  return DateTime.parse(datetime);
}

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
  static Future<bool> showYesNoMessage(String message, {PopUpTitle title=PopUpTitle.confirmation}) async {
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
      actions: [
        cancelButton,
        continueButton,
      ],
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
