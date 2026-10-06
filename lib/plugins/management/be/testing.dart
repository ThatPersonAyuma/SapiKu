import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Jika menggunakan image_picker untuk XFile
import 'be_app.dart';

// Pastikan mengimpor file model database Anda di sini:
// import 'package:your_project/models/database_models.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  // Form controllers untuk Produk
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _idSearchController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Data state
  List<Product> _productList = [];
  List<Transaction> _transactionList = [];
  final List<String> _logs = [];

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
      _logs.insert(0, '[${DateTime.now().toString().split('.').first}] $message');
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
    } else {
      _addLog('⚠️ Produk ID $id tidak ditemukan');
    }
  }

  Future<void> _handleSaveQR(Product product) async {
    _addLog('Memproses simpan QR ke galeri untuk ID: ${product.id}...');
    final success = await product.saveQRtoGallery();
    if (success) {
      _addLog('✅ QR Code berhasil disimpan ke Galeri');
    } else {
      _addLog('❌ Gagal menyimpan QR Code (Izin ditolak/File tidak ada)');
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

  Future<void> _handleGetTransactionDetails(Transaction transaction) async {
    _addLog('Memanggil transaction.getAllTransactionDetails() untuk ID: ${transaction.id}...');
    final details = await transaction.getAllTransactionDetails();
    if (details != null) {
      _addLog('✅ Ditemukan ${details.length} detail transaksi pada ID ${transaction.id}');
      setState(() {}); // Rerender UI
    } else {
      _addLog('⚠️ Gagal mengambil detail transaksi');
    }
  }

  // ==========================================
  // BUILD UI
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
                children: [
                  _buildProductTab(),
                  _buildTransactionTab(),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 2),
            _buildLogTerminal(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('1. Form Tambah Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()),
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
                label: Text(_selectedImage == null ? 'Pilih Gambar' : 'Gambar Terpilih'),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: _handleCreateProduct,
                child: const Text('Simpan Produk'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          const Text('2. Cari / Ambil Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idSearchController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cari berdasarkan ID', border: OutlineInputBorder()),
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
                child: const Text('Fetch All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List Produk
          const Text('3. Daftar Produk DB:', style: TextStyle(fontWeight: FontWeight.bold)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _productList.length,
            itemBuilder: (context, index) {
              final item = _productList[index];
              return Card(
                child: ListTile(
                  title: Text('${item.name} (ID: ${item.id})'),
                  subtitle: Text('Harga: Rp${item.price} | Stok: ${item.stock}\nQR: ${item.qrImagePath ?? "Kosong"}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.qr_code),
                    tooltip: 'Save QR to Gallery',
                    onPressed: () => _handleSaveQR(item),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _handleGetAllTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Load Semua Transaksi'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _transactionList.length,
              itemBuilder: (context, index) {
                final tx = _transactionList[index];
                return Card(
                  child: ExpansionTile(
                    title: Text('Transaksi ID: ${tx.id}'),
                    subtitle: Text('Waktu: ${tx.datetime}'),
                    onExpansionChanged: (expanded) {
                      if (expanded && tx.transactionDetails == null) {
                        _handleGetTransactionDetails(tx);
                      }
                    },
                    children: [
                      if (tx.transactionDetails == null)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Memuat detail...'),
                        )
                      else if (tx.transactionDetails!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Tidak ada detail item'),
                        )
                      else
                        ...tx.transactionDetails!.map(
                          (detail) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.subdirectory_arrow_right),
                            title: Text('Product ID: ${detail.productId}'),
                            subtitle: Text('Quantity: ${detail.quantity}'),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTerminal() {
    return Container(
      height: 180,
      color: Colors.black87,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Console Output Logs:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white70, size: 20),
                onPressed: () => setState(() => _logs.clear()),
              )
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(
                  _logs[index],
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}