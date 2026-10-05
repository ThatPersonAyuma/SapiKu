
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileHandler {
  static Future<String> storeImage(String prefix, XFile imgFile, String? oldImagePath) async {
    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        '${directory.path}/$prefix/${DateTime.now().millisecondsSinceEpoch}.png';
    final bytes = await imgFile.readAsBytes();
    final File newFile = File(filePath);
    await newFile.writeAsBytes(bytes);
    if (oldImagePath != null) {
      // if image before exist, destroy
      final File oldFile = File(oldImagePath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
    return filePath;
  } 
}