# Dokumentasi Integrasi Modul Deteksi Penyakit Kulit Sapi

Dokumentasi ini menjelaskan dua komponen utama dari modul deteksi penyakit kulit sapi:
1. **Machine Learning Cascade Pipeline (`detection_pipeline.dart`)**: Mengelola inferensi model TFLite (YOLOv8 + MobileNetV3).
2. **Backend & Local Database (`be_app.dart`)**: Mengelola inisialisasi plugin, unduhan model/aset, skema SQLite, serta penyimpanan riwayat deteksi.

---

## 🚀 Alur Kerja Integrasi Front-End (Quick Start)

Untuk mengintegrasikan fitur deteksi pada halaman Flutter/UI, ikuti urutan langkah berikut:

```
[1. App Setup] -> [2. Init Pipeline] -> [3. Pilih Foto] -> [4. Process Image] -> [5. Save to DB] -> [6. Tampilkan Hasil & Solusi]
```

1. **Inisialisasi Plugin (Awal Aplikasi)**: Panggil `detectionSetup()` saat aplikasi pertama kali dijalankan.
2. **Inisialisasi Pipeline (Init Screen)**: Panggil `await cascadePipeline.initialize()`.
3. **Proses Deteksi Gambar**: Kirim `File` gambar ke `cascadePipeline.processImage(imageFile)`.
4. **Simpan Hasil ke DB**: Simpan hasil deteksi menggunakan `DeasesDetection.create(...)`.
5. **Ambil Solusi Penyakit**: Ambil detail & solusi penyakit dari lokal DB dengan `Deases.getByName(label)`.
6. **Tampilkan Riwayat**: Gunakan `DeasesDetection.getAll()` dan `detection.getScans()`.

---

## 📦 1. Modul Inference / Machine Learning (`detection_pipeline.dart`)

### 1.1 Class `DetectionResult`
Model data yang merepresentasikan satu objek penyakit yang terdeteksi dari hasil proses inferensi.

#### Attribute
| Nama Attribute | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `boundingBox` | `Rect` | Koordinat posisi area terdeteksi pada ukuran asli gambar (dalam piksel: `left`, `top`, `width`, `height`). |
| `yoloScore` | `double` | Skor kepercayaan (confidence) dari deteksi lokasi objek oleh YOLOv8 (nilai `0.0` - `1.0`). |
| `label` | `String` | Nama label kelas penyakit hasil klasifikasi MobileNetV3. |
| `classificationScore` | `double` | Skor kepastian klasifikasi penyakit dari MobileNetV3 (nilai `0.0` - `1.0`). |

#### Constructor
```dart
DetectionResult({
  required Rect boundingBox,
  required double yoloScore,
  required String label,
  required double classificationScore,
});
```

---

### 1.2 Class `ProfilingMetrics`
Model data untuk menyimpan metrik durasi/performa eksekusi setiap tahap inferensi (digunakan untuk *debugging* atau menampilkan performa ke pengguna).

#### Attribute
| Nama Attribute | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `yoloTimeMs` | `int` | Waktu eksekusi inferensi YOLOv8 (millisecond). |
| `cropTimeMs` | `int` | Waktu pemotongan (cropping) & pemrosesan area ROI (millisecond). |
| `mobileNetTimeMs` | `int` | Waktu eksekusi inferensi klasifikasi MobileNetV3 (millisecond). |
| `totalTimeMs` | `int` | Total waktu yang dibutuhkan dari awal hingga selesai (millisecond). |

---

### 1.3 Class `CascadePipeline`
Kelas utama yang memproses gambar melalui dua tahap model ML: **YOLOv8** (Deteksi Lokasi/ROI) dan **MobileNetV3** (Klasifikasi Jenis Penyakit).

#### Method & Fungsi

##### `Future<void> initialize()`
* **Fungsi**: Memuat file model TFLite (`.tflite`) dari direktori lokal aplikasi ke dalam *Isolate Interpreter* (menjalankan inferensi di background thread agar UI tidak *lag*). Menyiapkan delegate GPU (jika didukung).
* **Kapan digunakan**: Dipanggil sekali pada `initState()` halaman scanner/deteksi sebelum pemrosesan gambar dilakukan.
* **Parameter**: Tidak ada.
* **Nilai Kembalian**: `Future<void>`

##### `Future<Map<String, dynamic>> processImage(File imageFile)`
* **Fungsi**: Menerima file gambar, mengubah ukuran (*resize*), melakukan deteksi bounding box via YOLOv8, memotong area terdeteksi (ROI), mengeksekusi MobileNetV3 untuk klasifikasi penyakit, dan mengembalikan hasil deteksi serta metrik performa.
* **Kapan digunakan**: Dipanggil ketika pengguna selesai mengambil foto atau memilih gambar dari galeri.
* **Parameter**:
  | Parameter | Tipe Data | Keterangan |
  | :--- | :--- | :--- |
  | `imageFile` | `File` | File gambar mentah yang diambil dari kamera/galeri. |
* **Nilai Kembalian**: `Future<Map<String, dynamic>>` berisi Map dengan struktur:
  ```dart
  {
    'results': List<DetectionResult>, // Maksimal 2 deteksi teratas
    'metrics': ProfilingMetrics,      // Informasi waktu eksekusi
    'imageWidth': int,                // Lebar asli gambar (px)
    'imageHeight': int,               // Tinggi asli gambar (px)
  }
  ```

---

## 🗄️ 2. Modul Database & Data Layer (`be_app.dart`)

### 2.1 Konstanta Global
| Nama Konstanta | Tipe Data | Nilai | Keterangan |
| :--- | :--- | :--- | :--- |
| `detectionName` | `String` | `"detection"` | Nama plugin/modul. |
| `modelAssetsId` | `String` | `"1Pxa6mnj..."` | ID Google Drive tempat mengunduh aset model ML. |
| `modelFolderPrefix`| `String` | `"models"` | Nama folder penyimpanan model ML. |
| `yoloFileName` | `String` | `"yolov8n_f32.tflite"` | Nama file model YOLOv8. |
| `mobNetFileName` | `String` | `"mobilenetv3_f32.tflite"` | Nama file model MobileNetV3. |
| `imageName1` | `String` | `"13_jpg..."` | File dummy seeder 1. |
| `imageName2` | `String` | `"1_jpg..."` | File dummy seeder 2. |

---

### 2.2 Fungsi Global (Setup & Database Management)

#### `Future<bool> detectionSetup(VoidCallback callback)`
* **Fungsi**: Mengonfigurasi modul deteksi pertama kali (mengecek status setup, mengunduh model TFLite, membuat tabel database, dan memasukkan data awal/seeder).
* **Kapan digunakan**: Dipanggil saat inisialisasi aplikasi (misal: di Splash Screen atau Plugin Manager).
* **Parameter**: `VoidCallback callback` (Fungsi callback yang dipanggil setiap ada kemajuan unduhan aset).
* **Nilai Kembalian**: `Future<bool>` — `true` jika setup berhasil/sudah pernah setup, `false` jika gagal.

#### `Future<void> detectionCreateTables(Batch batch)`
* **Fungsi**: Menambahkan perintah pembuatan tabel (`deases`, `deases_detections`, `scans`) ke dalam SQLite batch.
* **Kapan digunakan**: Dipanggil internal oleh `detectionSetup`.

#### `Future<List<String>?> downloadAssets(VoidCallback callback)`
* **Fungsi**: Mengunduh sampel gambar dummy dari Cloudinary untuk seeder.
* **Nilai Kembalian**: `Future<List<String>?>` — List path lokal gambar terunduh.

#### `Future<bool> downloadModelAssets()`
* **Fungsi**: Mengunduh dan mengekstrak file model TFLite dari Google Drive.
* **Nilai Kembalian**: `Future<bool>` — `true` jika berhasil.

#### `Future<void> detectionSeeder(Batch batch, VoidCallback callback)`
* **Fungsi**: Memasukkan data awal penyakit sapi beserta solusinya dan contoh riwayat deteksi.

---

### 2.3 Class Data Models

### Class `Deases`
Merepresentasikan master data jenis penyakit kulit sapi beserta solusi/tindakannya.

#### Attribute
| Attribute | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | `int` | Primary key penyakit. |
| `name` | `String` | Nama unik label penyakit (contoh: `lumpy`, `mange`, `ringworm`, `healthy_cowhide`, `pediculosis`). |
| `solution` | `String` | Deskripsi pertolongan pertama / solusi medis. |

#### Method Utama
* `static Future<Deases?> getByName(String deasesName)`
  * **Fungsi**: Mengambil detail penyakit dan solusinya berdasarkan nama label penyakit.
  * **Kapan digunakan**: Saat FE ingin menampilkan solusi penyakit dari label hasil `DetectionResult.label`.
  * **Nilai Kembalian**: Object `Deases` jika ditemukan, atau `null` jika tidak ada.

---

### Class `DeasesDetection`
Merepresentasikan record 1 kali aktivitas pemindaian/deteksi foto oleh pengguna (Riwayat Pemindaian).

#### Attribute
| Attribute | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | `int` | ID riwayat deteksi. |
| `name` | `String` | Judul/nama rekaman deteksi (Default: ISO Timestamp atau custom). |
| `datetime` | `DateTime` | Waktu saat deteksi dilakukan. |
| `imagePath` | `String` | Path lokal penyimpanan file gambar yang di-scan. |
| `scans` | `List<Scan>` | List hasil kotak deteksi (*bounding boxes*) pada foto ini. |

#### Method Utama

##### `static Future<DeasesDetection?> create(...)` ⭐ (Rekomendasi Utama FE)
```dart
static Future<DeasesDetection?> create(
  XFile imgFile,
  List<DetectionResult> detections,
  String? name,
) async
```
* **Fungsi**: Menyimpan foto hasil deteksi ke direktori lokal, membuat record `DeasesDetection` baru, dan menyimpan semua daftar `DetectionResult` ke tabel `scans`.
* **Kapan digunakan**: Dipanggil tepat setelah `CascadePipeline.processImage()` selesai dijalankan.
* **Parameter**:
  * `imgFile`: Gambar asli yang dipindai (`XFile`).
  * `detections`: List `DetectionResult` hasil dari `processImage()`.
  * `name`: Nama/catatan opsional untuk rekaman ini (jika `null`, otomatis menggunakan timestamp).
* **Nilai Kembalian**: Object `DeasesDetection` terbuat, atau `null` jika gagal.

##### `static Future<List<DeasesDetection>?> getAll()`
* **Fungsi**: Mengambil seluruh daftar riwayat deteksi yang tersimpan, diurutkan dari yang terbaru.
* **Kapan digunakan**: Dipanggil pada halaman **Riwayat Deteksi (History Screen)**.
* **Catatan**: Method ini belum menyertakan atribut `scans`. Panggil `getScans()` secara terpisah pada objek individual jika membutuhkan detail bounding box.

##### `Future<List<Scan>?> getScans()`
* **Fungsi**: Mengambil seluruh daftar bounding box (`Scan`) yang terikat dengan ID deteksi ini.
* **Kapan digunakan**: Dipanggil saat pengguna membuka **Halaman Detail Riwayat**.

##### `Future<bool> destroy()`
* **Fungsi**: Menghapus record deteksi ini beserta gambar terkait dari database dan direktori lokal.
* **Kapan digunakan**: Saat pengguna menekan tombol "Hapus Riwayat".

---

### Class `Scan`
Merepresentasikan data 1 kotak deteksi (*bounding box*) yang tersimpan di database.

#### Attribute
| Attribute | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | `int` | Primary key scan. |
| `labelId` | `int` | Foreign Key yang terhubung ke tabel `deases`. |
| `detectionId` | `int` | Foreign Key yang terhubung ke `deases_detections`. |
| `xCenter` | `double` | Posisi X titik pusat bounding box (**Rasio ter-normalisasi 0.0 - 1.0**). |
| `yCenter` | `double` | Posisi Y titik pusat bounding box (**Rasio ter-normalisasi 0.0 - 1.0**). |
| `width` | `double` | Lebar bounding box (**Rasio ter-normalisasi 0.0 - 1.0**). |
| `height` | `double` | Tinggi bounding box (**Rasio ter-normalisasi 0.0 - 1.0**). |
| `detectionResult`| `String` | Nama label hasil terdeteksi. |
| `confident` | `double` | Nilai kepastian deteksi (0.0 - 1.0). |

---

### Class `ScanComponent` *(Legacy/Alternative DTO)*
Digunakan sebagai format alternatif pembawa data scan manual jika tidak menggunakan objek `DetectionResult`.

---

## 🎨 3. Panduan Integrasi Front-End & Code Snippets

### 3.1 Contoh Pemrosesan Pemindaian Lengkap (Scanning Screen)

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapiku/plugins/detection/be/be_app.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final CascadePipeline _pipeline = CascadePipeline();
  bool _isInitializing = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initPipeline();
  }

  Future<void> _initPipeline() async {
    await _pipeline.initialize();
    setState(() => _isInitializing = false);
  }

  Future<void> _handleImageScan(XFile pickedFile) async {
    setState(() => _isProcessing = true);

    try {
      File imageFile = File(pickedFile.path);

      // 1. Eksekusi Pipeline ML
      final output = await _pipeline.processImage(imageFile);
      List<DetectionResult> results = output['results'];
      ProfilingMetrics metrics = output['metrics'];

      // 2. Simpan Hasil ke Database Lokal
      DeasesDetection? savedRecord = await DeasesDetection.create(
        pickedFile,
        results,
        "Pemeriksaan ${DateTime.now().day}/${DateTime.now().month}",
      );

      // 3. Ambil Solusi Penyakit untuk Hasil Pertama (Top 1)
      Deases? mainDiseaseInfo;
      if (results.isNotEmpty) {
        mainDiseaseInfo = await Deases.getByName(results.first.label);
      }

      // 4. Navigasi ke Halaman Hasil
      if (mounted && savedRecord != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              detectionRecord: savedRecord,
              diseaseInfo: mainDiseaseInfo,
              results: results,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error scan: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) return CircularProgressIndicator();
    return Scaffold(
      body: Center(
        child: _isProcessing 
          ? CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.camera);
                if (img != null) _handleImageScan(img);
              },
              child: Text("Ambil Foto Sapi"),
            ),
      ),
    );
  }
}
```

---

### 3.2 Menampilkan Bounding Box di Atas Gambar (UI Drawing)

* **Hasil Real-Time (`DetectionResult`)**: Menggunakan nilai piksel absolut dari `DetectionResult.boundingBox`.
* **Hasil Riwayat DB (`Scan`)**: Menggunakan rasio ter-normalisasi (0.0-1.0), dikalikan dengan ukuran `Widget`/gambar layar UI.

```dart
// CustomPainter untuk menggambar Bounding Box dari DetectionResult
class BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size originalImageSize;

  BoundingBoxPainter(this.detections, this.originalImageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / originalImageSize.width;
    final double scaleY = size.height / originalImageSize.height;

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var det in detections) {
      final rect = det.boundingBox;
      
      // Scale posisi ke ukuran widget UI
      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );

      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}