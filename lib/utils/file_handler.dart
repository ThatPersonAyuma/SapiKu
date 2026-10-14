import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileHandler {
  static Future<String> storeImage(
    String prefix,
    XFile imgFile,
    String? oldImagePath,
  ) async {
    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        '${directory.path}/$prefix/${DateTime.now().millisecondsSinceEpoch}.png';
    final bytes = await imgFile.readAsBytes();
    final File newFile = File(filePath);
    await newFile.parent.create(recursive: true);
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

  static Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Mengambil folder eksternal khusus aplikasi di Android
        // Path: /storage/emulated/0/Android/data/<package_name>/files
        directory = await getExternalStorageDirectory();

        // Atau bisa coba fungsi bawaan path_provider untuk folder Downloads:
        // directory = await getDownloadsDirectory();
      }
    } catch (err) {
      print("Cannot get download folder path, err: ${err.toString()}");
    }
    return directory?.path;
  }

  static Future<bool> saveFileWithPicker({
    required List<int> bytes,
    required String fileName,
  }) async {
    File? tempFile;
    try {
      // 1. Simpan file sementara di folder Temp bawaan aplikasi
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/$fileName');
      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(bytes);

      // 2. Konfigurasi parameter dialog penyimpanan
      final params = SaveFileDialogParams(
        sourceFilePath: tempFile.path,
        fileName: fileName, // Nama default yang muncul di picker
      );

      // 3. Tampilkan dialog native OS ke pengguna
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      // Jika finalPath != null, artinya pengguna menekan tombol "Save"
      return finalPath != null;
    } catch (e) {
      print("Error saat menyimpan file: $e");
      return false;
    } finally {
      // 4. Hapus file sementara setelah selesai agar tidak memenuhi memori
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}
