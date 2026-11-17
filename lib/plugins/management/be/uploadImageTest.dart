import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapiku/utils/cloudinary_handler.dart';
// Import CloudinaryService yang sudah dibuat sebelumnya
// import 'cloudinary_service.dart';

class CloudinaryTestPage extends StatefulWidget {
  const CloudinaryTestPage({super.key});

  @override
  State<CloudinaryTestPage> createState() => _CloudinaryTestPageState();
}

class _CloudinaryTestPageState extends State<CloudinaryTestPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _fileNameController = TextEditingController(
    text: 'test_product_001',
  );

  File? _selectedImage;
  bool _isUploading = false;
  String? _resultUrl;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  /// Memilih gambar dari Galeri atau Kamera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Kompresi ringan agar upload lebih cepat
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _resultUrl = null;
          _statusMessage = null;
          _isError = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal memilih gambar: $e';
        _isError = true;
      });
    }
  }

  /// Menjalankan proses cek & upload ke Cloudinary
  Future<void> _handleUpload() async {
    final fileName = _fileNameController.text.trim();

    if (_selectedImage == null) {
      _showSnackBar('Pilih gambar terlebih dahulu!', isError: true);
      return;
    }

    if (fileName.isEmpty) {
      _showSnackBar('Nama file (public_id) tidak boleh kosong!', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Mengecek & mengupload ke Cloudinary...';
      _isError = false;
      _resultUrl = null;
    });

    try {
      final String publicId = fileName;

      // Cek manual terlebih dahulu hanya untuk memberi informasi status di UI test
      final existingUrl = await CloudinaryHandler.checkFileExistsByUrl(
        publicId: publicId,
      );

      final uploadedUrl = await CloudinaryHandler.uploadIfNotExists(
        file: _selectedImage!,
        fileName: fileName,
      );

      setState(() {
        _isUploading = false;
        if (uploadedUrl != null) {
          _resultUrl = uploadedUrl;
          _isError = false;
          _statusMessage = existingUrl != null
              ? 'File SUDAH ADA di Cloudinary (Skip upload, memakai URL lama).'
              : 'File BELUM ADA, berhasil diupload sebagai file baru!';
        } else {
          _isError = true;
          _statusMessage = 'Gagal mendapatkan URL dari Cloudinary. Cek log console.';
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isError = true;
        _statusMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Upload Cloudinary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Area Pratinjau Gambar
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada gambar dipilih',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // 2. Tombol Pilih Gambar (Galeri & Kamera)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Input Nama File (Public ID)
            TextField(
              controller: _fileNameController,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                labelText: 'Nama File (public_id tanpa ekstensi)',
                hintText: 'Contoh: product_123',
                border: OutlineInputBorder(),
                helperText: 'Gunakan nama yang sama untuk menguji deteksi duplikat.',
              ),
            ),
            const SizedBox(height: 20),

            // 4. Tombol Cek & Upload
            FilledButton.icon(
              onPressed: _isUploading ? null : _handleUpload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploading ? 'Memproses...' : 'Cek & Upload ke Cloudinary',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Kartu Hasil & Status
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isError ? Colors.red.shade300 : Colors.green.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: _isError ? Colors.red : Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isError
                                  ? Colors.red.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_resultUrl != null) ...[
                      const Divider(height: 20),
                      const Text(
                        'URL Cloudinary:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _resultUrl!,
                        style: const TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _resultUrl!));
                            _showSnackBar('URL disalin ke clipboard');
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Salin URL'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}