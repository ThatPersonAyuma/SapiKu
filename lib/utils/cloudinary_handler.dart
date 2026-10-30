import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sapiku/utils/utils.dart';

class CloudinaryHandler {
  static Future<String?> downloadAndStoreImage(String prefix, String filename) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://res.cloudinary.com/tdjglugb/image/upload/v1792624511/$filename",
        ),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$prefix/$filename');
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        print('Gambar berhasil disimpan di: ${file.path}');
        return file.path;
      } else {
        print('Gagal mengunduh. Kode status: ${response.statusCode}');
        await PopUpMessage.showOkMessage(PopUpTitle.error, "Terjadi kesalahan pada pengunduhan aset gambar.");
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      await PopUpMessage.showOkMessage(PopUpTitle.error, "Terjadi kesalahan pada sistem pengambilan gambar.");
      return null;
    }
  }

  static Future<bool> uploadImage(XFile imgFile, String filename)async{
    return true;
  }
}
