# Dokumentasi Class Bridge Database (Models)

Dokumen ini menjelaskan struktur data, atribut, dan method pada class bridge database yang digunakan untuk integrasi pada sisi **Frontend**.

---

## 1. Class `Product`
Model ini mewakili data produk beserta fungsionalitas manajemen produk dan aset QR Code.

### Atribut

| Atribut | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `int` | ID unik produk (Primary Key). |
| `productName` | `String` | Nama produk. |
| `price` | `double` | Harga unit produk. |
| `stock` | `int` | Jumlah stok yang tersedia. |
| `imagePath` | `String?` | Path lokal penyimpanan foto produk (bisa `null`). |
| `qrImagePath` | `String?` | Path lokal penyimpanan gambar QR Code produk (bisa `null`). |

---

### Method & Kapan Digunakan

#### 1. `Product.getAll()`
* **Parameter:** -
* **Return:** `Future<List<Product>?>`
* **Fungsi:** Mengambil seluruh daftar produk yang tersimpan di database.
* **Kapan Digunakan:** Dipanggil saat **memuat halaman Katalog/Daftar Produk** (misal di `initState` atau `FutureBuilder`).

#### 2. `Product.getById(int id)`
* **Parameter:** `id` (`int`) - ID produk yang dicari.
* **Return:** `Future<Product?>`
* **Fungsi:** Mengambil data 1 produk spesifik berdasarkan ID.
* **Kapan Digunakan:** Dipanggil pada **Halaman Detail Produk** atau saat melakukan pemindaian QR Code untuk mencocokkan ID produk.

#### 3. `Product.create(String productName, double price, int stock, XFile? imgFile)`
* **Parameter:**
  * `productName`: Nama produk baru.
  * `price`: Harga produk.
  * `stock`: Stok awal.
  * `imgFile`: File gambar produk dari kustom pemilih/kamera (`XFile`, optional).
* **Return:** `Future<Product?>` (Mengembalikan instance `Product` baru jika berhasil, atau `null` jika nama sudah ada / gagal).
* **Kapan Digunakan:** Dipanggil pada **Form Tambah Produk** saat tombol *Submit/Save* ditekan.

#### 4. `saveToDb()`
* **Parameter:** -
* **Return:** `Future<int?>`
* **Fungsi:** Mengupdate/menyimpan perubahan atribut pada instance `Product` yang sedang aktif ke database.
* **Kapan Digunakan:** Dipanggil setelah mengedit informasi produk (seperti mengubah nama, harga, atau stok dari UI form edit).

#### 5. `changeProductImage(XFile img)`
* **Parameter:** `img` (`XFile`) - File gambar baru dari picker/kamera.
* **Return:** `Future<void>`
* **Fungsi:** Mengubah gambar produk, menghapus file foto lama di penyimpanan lokal, dan langsung memperbarui database.
* **Kapan Digunakan:** Dipanggil dari UI saat pengguna **mengganti foto produk** pada halaman edit produk.

#### 6. `saveQRtoGallery()`
* **Parameter:** -
* **Return:** `Future<bool>` (Mengembalikan `true` jika berhasil disimpan ke galeri).
* **Fungsi:** Meminta izin akses galeri perangkat dan mengunduh/menyimpan gambar QR Code produk ke Galeri HP pengguna.
* **Kapan Digunakan:** Dipanggil saat pengguna menekan tombol **"Simpan/Download QR Code"** di UI.

---

## 2. Class `Transaction`
Model ini mewakili entitas utama dari transaksi penjualan.

### Atribut

| Atribut | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `int` | ID unik transaksi. |
| `datetime` | `DateTime` | Tanggal dan waktu transaksi dilakukan. |
| `transactionDetails` | `List<TransactionDetail>?` | List item detail rincian produk pada transaksi ini (nullable sebelum di-fetch). |

---

### Method & Kapan Digunakan

#### 1. `Transaction.getAll()`
* **Parameter:** -
* **Return:** `Future<List<Transaction>?>`
* **Fungsi:** Mengambil seluruh riwayat transaksi yang tersimpan.
* **Kapan Digunakan:** Dipanggil saat **memuat Halaman Riwayat Transaksi**.

#### 2. `getAllTransactionDetails()`
* **Parameter:** -
* **Return:** `Future<List<TransactionDetail>?>`
* **Fungsi:** Memuat rincian item/produk (`TransactionDetail`) yang termasuk dalam transaksi ini dan menyimpannya di atribut `transactionDetails`.
* **Kapan Digunakan:** Dipanggil saat pengguna **menekan/membuka item riwayat transaksi** untuk melihat rincian barang apa saja yang dibeli.

#### 3. `saveToDB()`
* **Parameter:** -
* **Return:** `Future<int?>`
* **Fungsi:** Memperbarui tanggal/waktu transaksi di database.
* **Kapan Digunakan:** Dipanggil jika ada koreksi data tanggal/waktu transaksi dari sisi admin/UI.

---

## 3. Class `TransactionDetail`
Model ini mewakili rincian tiap item produk yang ada di dalam sebuah transaksi.

### Atribut

| Atribut | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `int` | ID unik item detail transaksi. |
| `productId` | `int` | ID Produk yang dibeli. |
| `transactionId` | `int` | ID Transaksi induk. |
| `quantity` | `int` | Jumlah kuantitas produk yang dibeli. |

---

### Method & Kapan Digunakan

#### 1. `saveToDB()`
* **Parameter:** -
* **Return:** `Future<int?>`
* **Fungsi:** Memperbarui jumlah quantity atau item produk di database. Menolak pembaruan jika quantity `< 0`.
* **Kapan Digunakan:** Dipanggil dari UI saat ada skenario **pengubahan jumlah item (edit quantity)** pada rincian transaksi tertentu.