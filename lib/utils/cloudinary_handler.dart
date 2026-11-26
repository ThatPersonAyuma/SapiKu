import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sapiku/utils/utils.dart';

class CloudinaryHandler {
  static const String cloudName = 'tdjglugb';
  static const String uploadPreset = 'sapiku_upload';
  static Future<String?> downloadCloudImage(
    String prefix,
    String filename,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://res.cloudinary.com/$cloudName/image/upload/v1794695519/sapiku/management/$filename",
        ),
      );
      print(
        "url: https://res.cloudinary.com/$cloudName/image/upload/v1794695519/sapiku/management/$filename",
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
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      return null;
    }
  }

  static Future<String?> downloadAndStoreImageWProgress(
    String prefix,
    String filename,
    void Function(int) callback,
    int contributeScore,
  ) async {
    final client = http.Client();
    int current = 0;

    try {
      final url = Uri.parse(
        "https://res.cloudinary.com/$cloudName/image/upload/v1794695519/sapiku/management/$filename",
      );
      final request = http.Request('GET', url);
      final http.StreamedResponse response = await client.send(request);

      if (response.statusCode == 200) {
        final int totalBytes = response.contentLength ?? 0;
        final List<int> bytes = [];

        // Dengarkan aliran data (chunk) gambar yang masuk
        await for (final chunk in response.stream) {
          bytes.addAll(chunk);

          if (totalBytes > 0) {
            // Gunakan bytes.length (kumulatif) agar skala 0 -> contributeScore akurat
            final progNow = (bytes.length / totalBytes) * contributeScore;
            final increment = getIncrement(current, progNow);
            
            if (increment > 0) {
              callback(increment);
              current += increment;
            }
          }
        }

        // Pastikan sisa contributeScore terpenuhi jika totalBytes == 0 atau selisih pembulatan
        final remaining = contributeScore - current;
        if (remaining > 0) {
          callback(remaining);
        }

        // Simpan kumpulan byte menjadi file gambar
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$prefix/$filename');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);

        print('Gambar berhasil disimpan di: ${file.path}');
        return file.path;
      } else {
        print('Gagal mengunduh. Kode status: ${response.statusCode}');
        await PopUpMessage.showOkMessage(
          PopUpTitle.error,
          "Terjadi kesalahan pada pengunduhan aset gambar.",
        );
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      await PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Terjadi kesalahan pada sistem pengambilan gambar.",
      );
      return null;
    } finally {
      client.close();
    }
  }

  static Future<String?> downloadAndStoreImage(
    String prefix,
    String filename,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://res.cloudinary.com/$cloudName/image/upload/v1794695519/sapiku/management/$filename",
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
        await PopUpMessage.showOkMessage(
          PopUpTitle.error,
          "Terjadi kesalahan pada pengunduhan aset gambar.",
        );
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      await PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Terjadi kesalahan pada sistem pengambilan gambar.",
      );
      return null;
    }
  }

  /// Mengecek dan mengupload file jika belum ada berdasarkan [fileName] (tanpa ekstensi).
  /// Mengembalikan `secure_url` file tersebut.
  static Future<String?> uploadIfNotExists({
    required File file,
    required String
    fileName, // Contoh: 'produk_123' (jangan sertakan .jpg/.png)
    String folder = 'sapiku/management',
  }) async {
    print("filename: ${file.path}");
    final String publicId = fileName;

    // 1. Cek terlebih dahulu lewat URL publik (opsional, menghemat bandwidth upload)
    final existingUrl = await checkFileExistsByUrl(publicId: publicId);
    if (existingUrl != null) {
      print('File sudah ada di Cloudinary: $existingUrl');
      return existingUrl;
    }

    // 2. Jika belum ada, lakukan upload dengan overwrite = false
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      // ..fields['public_id'] = fileName // atau full path jika tidak pakai field 'folder'
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['secure_url'] as String?;
    } else {
      // Menangani kondisi jika file ternyata sudah ada saat proses upload
      final errorMessage = data['error']?['message']?.toString() ?? '';
      if (errorMessage.contains('already exists')) {
        return 'https://res.cloudinary.com/$cloudName/image/upload/$publicId';
      }
      print('Gagal upload Cloudinary: $errorMessage');
      return null;
    }
  }

  /// Mengecek apakah file sudah ada menggunakan HTTP HEAD ke URL publik Cloudinary
  static Future<String?> checkFileExistsByUrl({
    required String publicId,
    String resourceType = 'image',
  }) async {
    // Cloudinary otomatis meresolusi format jika ekstensi tidak ditulis,
    // atau tambahkan ekstensi spesifik seperti .jpg / .png jika formatnya pasti.
    final url =
        'https://res.cloudinary.com/$cloudName/$resourceType/upload/v1794695519/sapiku/management/$publicId';

    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        return url;
      }
    } catch (e) {
      print('Error saat mengecek URL Cloudinary: $e');
    }
    return null;
  }
}
