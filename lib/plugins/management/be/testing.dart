import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/utils/db/local_handler.dart';

// Pastikan mengimpor file model database Anda di sini:
// import 'package:your_project/models/database_models.dart';
// import 'package:your_project/services/local_db_handler.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  // Form controllers untuk Tambah Produk
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _idSearchController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  List<Product> _productList = [];
  List<Transaction> _transactionList = [];
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _handleGetAllProducts();
    _handleGetAllTransactions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _idSearchController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
        0,
        '[${DateTime.now().toString().split('.').first}] $message',
      );
    });
  }

  // ==========================================
  // ACTION HANDLERS - PRODUCT
  // ==========================================

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
      _addLog('Gambar dipilih: ${image.name}');
    }
  }

  Future<void> _handleCreateProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text) ?? 0;

    if (name.isEmpty) {
      _addLog('❌ Gagal: Nama produk tidak boleh kosong');
      return;
    }

    _addLog('Memproses Product.create()...');
    final product = await Product.create(name, price, stock, _selectedImage);

    if (product != null) {
      _addLog('✅ Produk berhasil dibuat (ID: ${product.id})');
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      setState(() => _selectedImage = null);
      _handleGetAllProducts();
    } else {
      _addLog('❌ Gagal membuat produk (mungkin nama sudah ada / DB error)');
    }
  }

  Future<void> _handleGetAllProducts() async {
    _addLog('Memanggil Product.getAll()...');
    final products = await Product.getAll();
    if (products != null) {
      setState(() => _productList = products);
      _addLog('✅ Berhasil mengambil ${products.length} produk');
    } else {
      _addLog('⚠️ Tidak ada produk atau database error');
      setState(() => _productList = []);
    }
  }

  Future<void> _handleGetProductById() async {
    final id = int.tryParse(_idSearchController.text);
    if (id == null) {
      _addLog('❌ Masukkan ID angka yang valid');
      return;
    }

    _addLog('Memanggil Product.getById($id)...');
    final product = await Product.getById(id);
    if (product != null) {
      _addLog('✅ Ditemukan: ${product.toString()}');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ).then((_) => _handleGetAllProducts());
      }
    } else {
      _addLog('⚠️️ Produk ID $id tidak ditemukan');
    }
  }

  // ==========================================
  // ACTION HANDLERS - TRANSACTION
  // ==========================================

  Future<void> _handleGetAllTransactions() async {
    _addLog('Memanggil Transaction.getAll()...');
    final transactions = await Transaction.getAll();
    if (transactions != null) {
      setState(() => _transactionList = transactions);
      _addLog('✅ Berhasil mengambil ${transactions.length} transaksi');
    } else {
      _addLog('⚠️ DB error atau belum ada transaksi');
      setState(() => _transactionList = []);
    }
  }

  // ==========================================
  // BUILD MAIN UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Database Tester Bridge'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: 'Produk'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Transaksi'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [_buildProductTab(), _buildTransactionTab()],
              ),
            ),
            const Divider(height: 1, thickness: 2),
            _buildLogTerminal(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScanProducts() async {
    _addLog('Memanggil Product.getAll()...');
    final product = await Product.getFromQr(context);
    if (product != null) {
      // setState(() => _productList = [product]);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
      _addLog('✅ Berhasil mengambil ${product.name} produk');
    } else {
      _addLog('⚠️ Tidak ada produk atau qr error');
      setState(() => _productList = []);
    }
  }

  // --- TAB PRODUK ---
  Widget _buildProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1. Form Tambah Produk Baru',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Produk',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _selectedImage == null ? 'Pilih Gambar' : 'Gambar Terpilih',
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _handleCreateProduct,
                child: const Text('Simpan Produk'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          const Text(
            '2. Cari & Kelola Produk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idSearchController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cari berdasarkan ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _handleGetProductById,
                icon: const Icon(Icons.search),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleGetAllProducts,
                child: const Text('Refresh List'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleScanProducts,
                child: const Text('Scan'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Daftar Produk (Klik item untuk Detail/Edit):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _productList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada data produk'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _productList.length,
                  itemBuilder: (context, index) {
                    final item = _productList[index];
                    return Card(
                      child: ListTile(
                        leading: _buildImageThumbnail(item.imagePath),
                        title: Text('${item.name} (ID: ${item.id})'),
                        subtitle: Text(
                          'Harga: Rp${item.price} | Stok: ${item.stock}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: item),
                            ),
                          );
                          _handleGetAllProducts(); // Refresh setelah balik dari detail
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // --- TAB TRANSAKSI ---
  Widget _buildTransactionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_productList.isEmpty) {
                      await _handleGetAllProducts();
                    }
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateTransactionScreen(
                          availableProducts: _productList,
                        ),
                      ),
                    );
                    _handleGetAllTransactions();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Transaksi Baru'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _handleGetAllTransactions,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Daftar Transaksi (Klik untuk Detail):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _transactionList.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.builder(
                    itemCount: _transactionList.length,
                    itemBuilder: (context, index) {
                      final tx = _transactionList[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt),
                          ),
                          title: Text('Transaksi #${tx.id}'),
                          subtitle: Text('Waktu: ${tx.datetime}'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TransactionDetailScreen(transaction: tx),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- LOG TERMINAL ---
  Widget _buildLogTerminal() {
    return Container(
      height: 160,
      color: Colors.black87,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Console Output Logs:',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => setState(() => _logs.clear()),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(
                  _logs[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String? path) {
    if (path != null && File(path).existsSync()) {
      return Image.file(File(path), width: 40, height: 40, fit: BoxFit.cover);
    }
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 20),
    );
  }
}

// ============================================================================
// 1. HALAMAN DETAIL & EDIT PRODUK
// ============================================================================

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    widget.product.name = _nameController.text.trim();
    widget.product.price =
        double.tryParse(_priceController.text) ?? widget.product.price;
    widget.product.stock =
        int.tryParse(_stockController.text) ?? widget.product.stock;

    final result = await widget.product.saveToDb();
    setState(() => _isSaving = false);

    if (mounted) {
      if (result != null && result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Berhasil memperbarui data produk')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Gagal menyimpan perubahan')),
        );
      }
    }
  }

  Future<void> _handleChangeImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await widget.product.changeProductImage(image);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Foto produk berhasil diganti')),
        );
      }
    }
  }

  Future<void> _handleSaveQR() async {
    final success = await widget.product.saveQRtoGallery();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ QR Code disimpan ke galeri'
                : '❌ Gagal menyimpan QR Code',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Produk #${widget.product.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Gambar Produk & QR Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text(
                      'Foto Produk',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          widget.product.imagePath != null &&
                              File(widget.product.imagePath!).existsSync()
                          ? Image.file(
                              File(widget.product.imagePath!),
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _handleChangeImage,
                      icon: const Icon(Icons.photo_camera, size: 16),
                      label: const Text('Ubah'),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'QR Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          widget.product.qrImagePath != null &&
                              File(widget.product.qrImagePath!).existsSync()
                          ? Image.file(
                              File(widget.product.qrImagePath!),
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Text(
                                'Belum ada QR',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _handleSaveQR,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),

            // Form Edit
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok Produk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text(
                'Simpan Perubahan (saveToDb)',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. HALAMAN TAMBAH TRANSAKSI
// ============================================================================

class CreateTransactionScreen extends StatefulWidget {
  final List<Product> availableProducts;

  const CreateTransactionScreen({super.key, required this.availableProducts});

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  Product? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController(text: "1");

  // Keranjang belanja sementara: List<Map{product: Product, quantity: int}>
  final List<Map<String, dynamic>> _cartItems = [];

  void _addToCart() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    setState(() {
      _cartItems.add({'product': _selectedProduct!, 'quantity': qty});
      _selectedProduct = null;
      _qtyController.text = "1";
    });
  }

  Future<void> _submitTransaction() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang transaksi masih kosong')),
      );
      return;
    }

    try {
      // // 1. Buat record di tabel transactions
      // int? txId = await LocalDBHandler.runRawInsertQuery(
      //   "INSERT INTO transactions() VALUES()",
      //   [],
      // );

      // if (txId == null) {
      //   throw Exception("Gagal membuat record transaksi utama");
      // }

      // // 2. Buat record di tabel transaction_details untuk setiap item
      // for (final item in _cartItems) {
      //   final product = item['product'] as Product;
      //   final qty = item['quantity'] as int;

      //   await LocalDBHandler.runRawInsertQuery(
      //     "INSERT INTO transaction_details(product_id, transaction_id, quantity) VALUES(?, ?, ?)",
      //     [product.id, txId, qty],
      //   );
      // }
      final transaction = await Transaction.create([
        for (final item in _cartItems) TransactionDetailInsertComponent((item['product'] as Product).id, item['quantity'] as int)
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Transaksi #${transaction?.id} berhasil disimpan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal menyimpan transaksi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Transaksi Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tambah Item ke Transaksi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              hint: const Text('Pilih Produk'),
              items: widget.availableProducts.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.name} (Rp${p.price})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedProduct = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Quantity)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            const Text(
              'Ringkasan Item Transaksi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(child: Text('Belum ada item ditambahkan'))
                  : ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        final p = item['product'] as Product;
                        final q = item['quantity'] as int;
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            'Rp${p.price} x $q item = Rp${p.price * q}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _cartItems.removeAt(index)),
                          ),
                        );
                      },
                    ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitTransaction,
              child: const Text(
                'Simpan Transaksi ke Database',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. HALAMAN DETAIL TRANSAKSI
// ============================================================================

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = true;
  List<TransactionDetail> _details = [];
  Map<int, Product> _productCache = {};

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    setState(() => _isLoading = true);

    // Ambil detail transaksi
    final details = await widget.transaction.getAllTransactionDetails();
    if (details != null) {
      _details = details;

      // Fetch detail produk terkait untuk menampilkan nama/harga di UI
      for (final item in _details) {
        if (!_productCache.containsKey(item.productId)) {
          final prod = await Product.getById(item.productId);
          if (prod != null) {
            _productCache[item.productId] = prod;
          }
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = 0;
    for (var d in _details) {
      final p = _productCache[d.productId];
      if (p != null) {
        grandTotal += p.price * d.quantity;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Detail Transaksi #${widget.transaction.id}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID Transaksi: #${widget.transaction.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Tanggal: ${widget.transaction.datetime}'),
                          Text('Jumlah Item: ${_details.length} item jenis'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rincian Item:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _details.isEmpty
                        ? const Center(child: Text('Tidak ada detail item'))
                        : ListView.builder(
                            itemCount: _details.length,
                            itemBuilder: (context, index) {
                              final item = _details[index];
                              final product = _productCache[item.productId];

                              return Card(
                                child: ListTile(
                                  title: Text(
                                    product?.name ??
                                        'Produk ID: ${item.productId}',
                                  ),
                                  subtitle: Text(
                                    'Quantity: ${item.quantity} | Harga Satuan: Rp${product?.price ?? 0}',
                                  ),
                                  trailing: Text(
                                    'Rp${(product?.price ?? 0) * item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp$grandTotal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
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
}
