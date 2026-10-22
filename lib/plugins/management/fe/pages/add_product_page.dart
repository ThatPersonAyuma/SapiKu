import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk tidak boleh kosong')),
      );
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga harus lebih dari 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final product = await Product.create(name, price, stock, _selectedImage);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (product != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk "${product.name}" berhasil disimpan')),
      );
      Navigator.pop(context, product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan produk — nama mungkin sudah dipakai')),
      );
    }
  }

  Widget _cardBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              Container(width: 10, color: AppColors.greenBorder),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, String? prefixText}) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Tambah Produk'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140, bottom: 100),
          children: [
            _cardBox(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Produk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Nama Produk'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(hintText: 'Contoh: Susu UHT 1L'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Harga'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  hintText: '0',
                                  prefixText: 'Rp ',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Stok'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(hintText: '0'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _cardBox(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gambar Produk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _imagePreview(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedImage == null
                                    ? 'Belum ada gambar dipilih'
                                    : 'Gambar dipilih',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkCard,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
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
                                label: const Text('Pilih Gambar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkCard,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                label: const Text('Simpan Produk'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }

  Widget _imagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 90,
        height: 90,
        color: Colors.grey.shade200,
        child: _selectedImage == null
            ? const Icon(Icons.image, color: Colors.grey, size: 30)
            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
      ),
    );
  }
}
