# Dokumentasi Modul Management (`management.dart`)

Dokumentasi ini menjelaskan secara rinci fungsi, kelas, atribut, parameter, nilai kembali (*return value*), serta skenario penggunaan dari modul manajemen pada aplikasi Sapiku.

---

## 1. Fungsi Utama (Top-Level Functions)

### `managementSetup()`
* **Kegunaan**: Melakukan inisialisasi awal (*setup*) skema tabel basis data SQLite yang dibutuhkan oleh modul `management` (tabel `products`, `transactions`, dan `transaction_details`) serta mencatat status setup pada tabel `plugins`.
* **Parameter**: Tidak ada.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Dipanggil saat aplikasi pertama kali dijalankan atau sebelum fungsi `main()` untuk memastikan tabel basis data sudah siap digunakan.

### `manageTest()`
* **Kegunaan**: Fungsi pengujian (*testing/debugging*) internal untuk memeriksa isi data detail transaksi dan transaksi, serta menguji ekspor laporan.
* **Parameter**: Tidak ada.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Hanya digunakan pada tahap pengujian internal pengembangan aplikasi.

---

## 2. Kelas `Product`

Kelas ini merepresentasikan entitas barang atau produk dalam basis data.

### Atribut
* `tableName` (`static String`): Nama tabel basis data (`"products"`).
* `qrPhotoPath` (`static String`): Folder direktori penyimpanan gambar QR code (`"qr_images"`).
* `productImgPath` (`static String`): Folder direktori penyimpanan foto produk (`"product_images"`).
* `id` (`int`): ID unik produk (Primary Key).
* `name` (`String`): Nama produk (Harus unik).
* `price` (`double`): Harga satuan produk.
* `stock` (`int`): Jumlah stok barang yang tersedia.
* `imagePath` (`String?`): Path lokal file gambar foto produk (bisa null).
* `qrImagePath` (`String?`): Path lokal file gambar QR code produk (bisa null).

### Method & Konstruktor

#### `Product(...)`
* **Kegunaan**: Konstruktor utama untuk membuat objek `Product`. Secara otomatis memanggil fungsi privat `_ensureQrImage()` untuk memastikan QR Code telah dibuat.
* **Parameter**: `id` (`int`), `name` (`String`), `price` (`double`), `stock` (`int`), `imagePath` (`String?`), `qrImagePath` (`String?`).
* **Return**: Instance dari `Product`.
* **Kapan Digunakan**: Saat melakukan inisialisasi data produk di dalam kode aplikasi.

#### `toMap()`
* **Kegunaan**: Mengubah objek `Product` menjadi format `Map<String, Object?>`.
* **Parameter**: Tidak ada.
* **Return**: `Map<String, Object?>`
* **Kapan Digunakan**: Saat perlu mengonversi data produk ke format Map atau JSON.

#### `createFromMap(Map<String, Object?> map)`
* **Kegunaan**: Mengonversi data dari baris basis data (`Map`) menjadi instance kelas `Product`.
* **Parameter**: `map` (`Map<String, Object?>`) - Baris data dari query database.
* **Return**: `Product`
* **Kapan Digunakan**: Saat membaca data produk hasil *query* SELECT dari database.

#### `_ensureQrImage()` *(Private)*
* **Kegunaan**: Memeriksa apakah QR code sudah tersimpan di direktori lokal. Jika belum, fungsi akan membuat gambar QR code dan memperbarui `qrImagePath` di database.
* **Parameter**: Tidak ada.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Dipanggil internal oleh konstruktor `Product` atau fungsi lain ketika gambar QR code belum ada.

#### `Product.getById(int id)`
* **Kegunaan**: Mengambil data produk dari basis data berdasarkan ID.
* **Parameter**: `id` (`int`) - ID produk yang dicari.
* **Return**: `Future<Product?>` - Objek `Product` jika ditemukan, atau `null` jika tidak ditemukan/terjadi eror.
* **Kapan Digunakan**: Saat ingin menampilkan detail produk tertentu berdasarkan ID.

#### `Product.getByName(String name)`
* **Kegunaan**: Mencari produk berdasarkan nama.
* **Parameter**: `name` (`String`) - Nama produk yang dicari.
* **Return**: `Future<Product?>` - Objek `Product` jika ditemukan, atau `null`.
* **Kapan Digunakan**: Saat fitur pencarian produk berdasarkan nama digunakan.

#### `Product.getAll()`
* **Kegunaan**: Mengambil seluruh daftar produk yang tersimpan di basis data.
* **Parameter**: Tidak ada.
* **Return**: `Future<List<Product>?>` - List dari `Product` atau `null`.
* **Kapan Digunakan**: Saat menampilkan daftar katalog produk atau tabel produk.

#### `Product.create(String name, double price, int stock, XFile? imgFile)`
* **Kegunaan**: Membuat produk baru, menyimpan gambar ke direktori aplikasi jika ada, lalu menyimpan rekaman baru ke basis data.
* **Parameter**:
  * `name` (`String`): Nama produk.
  * `price` (`double`): Harga produk.
  * `stock` (`int`): Jumlah stok awal.
  * `imgFile` (`XFile?`): File gambar produk dari *picker*.
* **Return**: `Future<Product?>` - Objek `Product` yang berhasil dibuat, atau `null` jika nama sudah digunakan/terjadi eror.
* **Kapan Digunakan**: Saat pengguna menambahkan produk baru dari formulir aplikasi.

#### `saveToDb()`
* **Kegunaan**: Mengirimkan perubahan atribut objek `Product` saat ini ke basis data SQLite (`UPDATE`).
* **Parameter**: Tidak ada.
* **Return**: `Future<int?>` - Jumlah baris yang terpengaruh/diperbarui.
* **Kapan Digunakan**: Setelah mengubah atribut seperti nama, harga, stok, atau gambar produk pada objek.

#### `changeProductImage(XFile img)`
* **Kegunaan**: Mengubah foto produk, menghapus file foto lama (jika ada), menyimpan foto baru, lalu memperbarui basis data.
* **Parameter**: `img` (`XFile`) - File foto baru dari picker.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Saat pengguna melakukan edit/perbaruan foto produk.

#### `saveQRtoGallery()`
* **Kegunaan**: Memeriksa izin akses galeri, kemudian menyimpan file QR Code produk ke galeri perangkat menggunakan plugin `Gal`.
* **Parameter**: Tidak ada.
* **Return**: `Future<bool>` - `true` jika berhasil disimpan ke galeri, `false` jika gagal/izin ditolak.
* **Kapan Digunakan**: Saat pengguna menekan tombol simpan/unduh QR Code ke galeri HP.

#### `Product.getFromQr(BuildContext ctx)`
* **Kegunaan**: Membuka halaman pemindai QR (`QRScannerPage`), membaca ID dari QR, lalu mengambil data `Product` terkait dari basis data.
* **Parameter**: `ctx` (`BuildContext`) - Context navigasi Flutter.
* **Return**: `Future<Product?>` - Objek `Product` jika QR valid dan produk ditemukan, atau `null`.
* **Kapan Digunakan**: Saat fitur *Scan QR* kasir/stok diaktifkan.

#### `Product.destroyById(int id)`
* **Kegunaan**: Menghapus baris produk dari database berdasarkan ID.
* **Parameter**: `id` (`int`) - ID produk yang akan dihapus.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Saat ingin menghapus produk spesifik tanpa perlu membuat instance produk terlebih dahulu.

#### `destroy()`
* **Kegunaan**: Menghapus produk instance saat ini dari basis data.
* **Parameter**: Tidak ada.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Dipanggil langsung dari instance produk yang ingin dihapus.

---

## 3. Kelas `Transaction`

Kelas ini merepresentasikan induk data transaksi penjualan.

### Atribut
* `tableName` (`static const String`): Nama tabel basis data (`"transactions"`).
* `id` (`int`): ID transaksi (Primary Key).
* `datetime` (`DateTime`): Waktu terjadinya transaksi.
* `transactionDetails` (`List<TransactionDetail>?`): List dari Rincian/Item produk pada transaksi ini.

### Method & Konstruktor

#### `Transaction(this.id, this.datetime)`
* **Kegunaan**: Konstruktor utama kelas `Transaction`.
* **Parameter**: `id` (`int`), `datetime` (`DateTime`).
* **Return**: Instance dari `Transaction`.

#### `createFromMap(Map<String, Object?> map)`
* **Kegunaan**: Mengubah hasil query SQLite menjadi instance `Transaction`.
* **Parameter**: `map` (`Map<String, Object?>`)
* **Return**: `Transaction`

#### `toMap()`
* **Kegunaan**: Mengonversi transaksi ke format `Map`.
* **Parameter**: Tidak ada.
* **Return**: `Map<String, Object?>`

#### `Transaction.getAll()`
* **Kegunaan**: Mengambil seluruh daftar transaksi diurutkan dari yang terbaru (`datetime DESC`).
* **Parameter**: Tidak ada.
* **Return**: `Future<List<Transaction>?>`
* **Kapan Digunakan**: Untuk menampilkan riwayat transaksi pada aplikasi.

#### `getAllTransactionDetails()`
* **Kegunaan**: Mengambil semua item rincian transaksi (`TransactionDetail`) milik transaksi ini dan menyimpannya ke variabel `transactionDetails`.
* **Parameter**: Tidak ada.
* **Return**: `Future<List<TransactionDetail>?>`
* **Kapan Digunakan**: Saat pengguna membuka detail rincian dari satu transaksi tertentu.

#### `saveToDB()`
* **Kegunaan**: Memperbarui tanggal transaksi di basis data.
* **Parameter**: Tidak ada.
* **Return**: `Future<int?>`
* **Kapan Digunakan**: Jika ada pengeditan tanggal transaksi.

#### `Transaction.getById(int id)`
* **Kegunaan**: Mengambil transaksi berdasarkan ID.
* **Parameter**: `id` (`int`)
* **Return**: `Future<Transaction?>`

#### `Transaction.create(List<TransactionDetailInsertComponent> details, {DateTime? date})`
* **Kegunaan**: Membuat transaksi baru, memvalidasi persediaan stok produk, mengurangi stok jika mencukupi, serta memasukkan item detail transaksi ke basis data menggunakan `Batch`.
* **Parameter**:
  * `details` (`List<TransactionDetailInsertComponent>`): Daftar produk dan jumlah yang dibeli.
  * `date` (`DateTime?`, opsional): Tanggal kustom transaksi. Jika tidak diisi, menggunakan waktu default database (`CURRENT_TIMESTAMP`).
* **Return**: `Future<Transaction?>` - Objek transaksi yang dibuat, atau `null` jika stok tidak mencukupi/terjadi kesalahan.
* **Kapan Digunakan**: Saat proses pembayaran / *checkout* kasir selesai.

#### `Transaction.destroyById(int id)` / `destroy()`
* **Kegunaan**: Menghapus data transaksi dari database (detail transaksi akan otomatis terhapus karena aturan `ON DELETE CASCADE`).
* **Parameter**: `id` (`int`) pada method static.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Saat membatalkan atau menghapus riwayat transaksi.

#### `Transaction.getAllTransactionAndDetails(DateTime start, DateTime end)`
* **Kegunaan**: Melakukan *JOIN query* antara tabel transaksi, detail transaksi, dan produk untuk mendapatkan laporan lengkap pada rentang tanggal tertentu.
* **Parameter**: `start` (`DateTime`), `end` (`DateTime`).
* **Return**: `Future<List<Map<String, Object?>>?>` - List data gabungan hasil join query.
* **Kapan Digunakan**: Digunakan oleh sistem pelaporan/rekapitulasi transaksi.

---

## 4. Kelas `TransactionDetail`

Kelas ini merepresentasikan detail/item produk di dalam suatu transaksi.

### Atribut
* `tableName` (`static const String`): Nama tabel (`"transaction_details"`).
* `id` (`int`): ID unik detail transaksi.
* `productId` (`int`): ID produk yang dibeli.
* `transactionId` (`int`): ID transaksi induk.
* `quantity` (`int`): Jumlah produk yang dibeli.

### Method & Konstruktor
* **`TransactionDetail(...)`**: Konstruktor utama.
* **`createFromMap(Map<String, Object?> map)`**: Konversi dari Map database ke objek `TransactionDetail`.
* **`toMap()`**: Konversi dari objek ke Map.
* **`saveToDB()`**:
  * **Kegunaan**: Memperbarui data detail transaksi pada database.
  * **Parameter**: Tidak ada.
  * **Return**: `Future<int?>` - `null` jika `quantity < 0`.
  * **Kapan Digunakan**: Saat mengubah kuantitas item dalam detail transaksi.

---

## 5. Kelas `TransactionDetailInsertComponent`

Kelas penolong (*helper class*) sederhana untuk menampung data sebelum transaksi dibuat.

### Atribut
* `productId` (`int`): ID Produk.
* `quantity` (`int`): Jumlah barang yang dibeli.

### Konstruktor
* **`TransactionDetailInsertComponent(this.productId, this.quantity)`**: Digunakan saat menyusun daftar keranjang belanja sebelum dikirim ke `Transaction.create()`.

---

## 6. Kelas `ReportRecord`

Kelas untuk struktur data rekapan laporan keuangan/penjualan.

### Atribut
* `date` (`DateTime`): Waktu/Tanggal transaksi.
* `totalPrice` (`double`): Total nilai harga item pada transaksi.

### Method
* **`createFromMap(Map<String, Object?> map)`**: Membuat objek `ReportRecord` dari `Map`.
* **`createFromListMap(List<Map<String, Object?>> data)`**: Mengonversi `List<Map>` hasil query laporan menjadi `List<ReportRecord>`.

---

## 7. Kelas `ManageUtils`

Kelas utilitas untuk pengelolaan konfigurasi keamanan dan pembuatan file laporan Excel.

### Atribut
* `_cloudPwKey` (`static const String`): Key penyimpanan kata sandi cloud.
* `_reportDir` (`static const String`): Nama folder laporan.
* `_storage` (`FlutterSecureStorage`): Instance penyimpanan aman.
* `_columnNames` (`static List<String>`): Header kolom Excel (`["Waktu", "Total"]`).

### Method

#### `ManageUtils.setCloudSyncPw(String pw)`
* **Kegunaan**: Menyimpan kata sandi sinkronisasi cloud ke penyimpanan aman (*secure storage*).
* **Parameter**: `pw` (`String`) - Kata sandi yang akan disimpan.
* **Return**: `Future<void>`
* **Kapan Digunakan**: Saat pengguna mengatur atau mengupdate kata sandi sinkronisasi cloud.

#### `ManageUtils.getCloudSyncPw()`
* **Kegunaan**: Membaca kata sandi sinkronisasi cloud dari *secure storage*.
* **Parameter**: Tidak ada.
* **Return**: `Future<String?>` - Kata sandi dalam bentuk string atau `null`.
* **Kapan Digunakan**: Saat proses autentikasi sinkronisasi cloud berlangsung.

#### `ManageUtils.createReport(DateTime start, DateTime end)`
* **Kegunaan**: Mengambil data transaksi gabungan dari database berdasarkan rentang tanggal dan mengubahnya menjadi `List<ReportRecord>`.
* **Parameter**: `start` (`DateTime`), `end` (`DateTime`).
* **Return**: `Future<List<ReportRecord>?>`
* **Kapan Digunakan**: Saat menyiapkan data laporan keuangan sebelum ditampilkan atau diekspor.

#### `ManageUtils.saveReport(DateTime start, DateTime end, {List<ReportRecord>? reportData})`
* **Kegunaan**: Membuat dokumen Excel (`.xlsx`) dari data laporan transaksi menggunakan `syncfusion_flutter_xlsio` dan menyimpannya menggunakan file picker.
* **Parameter**:
  * `start` (`DateTime`): Tanggal awal laporan.
  * `end` (`DateTime`): Tanggal akhir laporan.
  * `reportData` (`List<ReportRecord>?`, opsional): Data rekap yang sudah disiapkan (mencegah pencarian ulang jika sudah ada).
* **Return**: `Future<bool>` - `true` jika pembuatan dan penyerahan file berhasil, `false` jika gagal.
* **Kapan Digunakan**: Saat pengguna menekan tombol "Ekspor Laporan Excel".