import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sapiku/utils/utils.dart';

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

  static Future<String> saveBinary(
    String prefix,
    String filename,
    Uint8List bytes,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "$directory/$prefix/$filename";
    final File newFile = File(filePath);
    await newFile.parent.create(recursive: true);
    await newFile.writeAsBytes(bytes);
    return filePath;
  }

  static Future<String> getStoredPath(String prefix, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return "$directory/$prefix/$filename";
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
      PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Error saat menyimpan file.",
      );
      return false;
    } finally {
      // 4. Hapus file sementara setelah selesai agar tidak memenuhi memori
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Delete a file using given file path.
  /// Automatically adding 
  static Future<void> deleteFile(String filePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filePath');
    if (!file.existsSync()) return;
    await file.delete();
  }

  /// Delete a directory and its sub-diretories and file. It use dete recursive
  static Future<void> deleteDirectory(String folderPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$folderPath');
    if (!file.existsSync()) return;
    await file.delete(recursive: true);
  }
}
