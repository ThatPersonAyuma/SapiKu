import 'dart:ui';

import 'package:image_picker/image_picker.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';
import 'package:sapiku/utils/cloudinary_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sapiku/utils/utils.dart';
import 'package:sqflite/sqflite.dart';

// #region Setup & Testing

class DetectionPlugin {
  // #region Constant Value
  static const detectionName = "detection";
  static const modelAssetsId = "1Pxa6mnjzePYSq_Yrc9bcqc-mCOYeGx5M";
  static const modelFolderPrefix = "models";

  /// Filename of YOLO Model
  static const yoloFileName = "yolov8n_f32.tflite";

  /// Filename of MobileNet Model
  static const mobNetFileName = "mobilenetv3_f32.tflite";

  // #region Detection Images
  static const imageName1 = "13_jpg.rf.7cbaa11ffeee0cbc54197cb4b2a6d763.jpg";
  static const imageName2 = "1_jpg.rf.2c3cbd206bd74b6bdd9272dcd85ce73e.jpg";
  // #endregion

  // #endregion

  static Future<bool> detectionSetup(VoidCallback callback, String version) async {
    print("Setup");
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM ${Plugin.tableName} WHERE name = ?",
      [detectionName],
    );
    if (res == null) return false;
    if (res.isNotEmpty) {
      if (res[0]['is_setup'] == 1) return true;
    }
    final batch = LocalDBHandler.getBatch();
    if (batch == null) return false;
    final isDownloaded = await downloadModelAssets();
    if (!isDownloaded) return false;

    await detectionCreateTables(batch);

    await detectionSeeder(batch, callback);

    await batch.commit(noResult: true);
    if (res.isNotEmpty) {
      await LocalDBHandler.runRawUpdateQuery(
        """
        UPDATE plugins
        SET is_setup = ?
        WHERE id = ?;
        """,
        [boolToInt(true), res[0]['id']],
      );
    } else {
      await LocalDBHandler.runRawInsertQuery(
        """
        INSERT INTO plugins (name, is_setup, version)
        values (?, ?, ?);
        """,
        [detectionName, boolToInt(true), version],
      );
    }
    print("Success Setup");
    return true;
  }

  /// SQL Query String for creating the detection plugin tables
  static Future<void> detectionCreateTables(Batch batch) async {
    batch.execute("""
      CREATE TABLE IF NOT EXISTS ${Deases.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(255) NOT NULL UNIQUE,
        solution TEXT NOT NULL
      );
    """);
    batch.execute("""
      CREATE TABLE IF NOT EXISTS ${DeasesDetection.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(255) NOT NULL,
        datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        image_path TEXT NOT NULL
      );
    """);
    batch.execute("""
      CREATE TABLE IF NOT EXISTS ${Scan.tableName} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          label_id INTEGER NOT NULL,
          detection_id INTEGER NOT NULL,
          x_center REAL NOT NULL,
          y_center REAL NOT NULL,
          width REAL NOT NULL,
          height REAL NOT NULL,
          result TEXT NOT NULL,
          confidence REAL NOT NULL,
          FOREIGN KEY (label_id) REFERENCES deases (id) ON DELETE CASCADE,
          FOREIGN KEY (detection_id) REFERENCES deases_detections (id) ON DELETE CASCADE
      );
    """);
  }

  /// For Download all assets needed for the start of the plugin.
  /// In this scenario we download all of the images for example of detection history
  static Future<List<String>?> downloadAssets(VoidCallback callback) async {
    List<String> paths = List.filled(2, "");
    // Download for susu ori
    final res1 = await CloudinaryHandler.downloadAndStoreImage(
      detectionName,
      imageName1,
    );
    if (res1 == null) {
      return null;
    } else {
      paths[0] = res1;
    }
    callback();
    final res2 = await CloudinaryHandler.downloadAndStoreImage(
      detectionName,
      imageName2,
    );
    if (res2 == null) {
      return null;
    } else {
      paths[1] = res2;
    }
    callback();
    return paths;
  }

  /// Download the inference assets needed.
  /// This will download the model data from google drive
  static Future<bool> downloadModelAssets() async {
    print("Downloading model assets");
    final modelRes = await downloadAndUnzip(
      modelAssetsId,
      "$detectionName/models",
    );
    print("Result: $modelRes");
    if (!modelRes) return false;
    return true;
  }

  /// Seeding the database with dummy data, for dev & preview only
  static Future<void> detectionSeeder(Batch batch, VoidCallback callback) async {
    final paths = await downloadAssets(callback);
    if (paths == null) return;
    // 1. Seed Table Deases
    batch.insert(Deases.tableName, {
      'name': 'healthy_cowhide',
      'solution':
          'Kondisi kulit sehat. Tidak memerlukan tindakan medis khusus. Pertahankan kebersihan kandang, berikan nutrisi pakan yang seimbang, dan lakukan pemeriksaan kesehatan rutin.',
    });
    batch.insert(Deases.tableName, {
      'name': 'lumpy',
      'solution':
          'Isolasi sapi yang terinfeksi untuk mencegah penularan. Berikan vaksinasi Lumpy Skin Disease (LSD), lakukan pengendalian vektor pemindah (lalat, nyamuk, caplak), serta berikan obat suportif seperti antibiotik (mencegah infeksi sekunder) dan antiinflamasi sesuai petunjuk dokter hewan.',
    });
    batch.insert(Deases.tableName, {
      'name': 'mange',
      'solution':
          'Karantina sapi yang terinfeksi. Berikan terapi antiparasit seperti ivermectin (suntik atau pour-on) atau permethrin, serta bersihkan dan disinfeksi seluruh area kandang dan peralatan ternak secara menyeluruh.',
    });
    batch.insert(Deases.tableName, {
      'name': 'pediculosis',
      'solution':
          'Gunakan insektisida topikal atau antiparasit pour-on khusus pembasmi kutu. Bersihkan dan ganti alas kandang secara berkala, serta obati seluruh kelompok ternak yang pernah kontak langsung dengan sapi terinfeksi.',
    });
    batch.insert(Deases.tableName, {
      'name': 'ringworm',
      'solution':
          'Isolasi ternak dan bersihkan kerak pada kulit secara perlahan. Oleskan larutan atau salep antijamur (seperti povidone-iodine 10% atau salep antifungal khusus ternak) dan pastikan kandang mendapatkan paparan sinar matahari langsung serta sirkulasi udara yang memadai.',
    });
    // 2. Seed Table DeasesDetection
    batch.insert(DeasesDetection.tableName, {
      'name': 'Sapi nomor 24',
      'datetime': DateTime(2026, 1, 1, 6, 30, 15, 12, 0).toIso8601String(),
      'image_path': paths[0],
    });
    final datetime = DateTime(2026, 2, 1, 5, 50, 35, 32, 2).toIso8601String();
    batch.insert(DeasesDetection.tableName, {
      'name': datetime,
      'datetime': datetime,
      'image_path': paths[1],
    });

    // 3. Seed Table Scan
    batch.insert(Scan.tableName, {
      'label_id': 1,
      'detection_id': 1,
      'x_center': 0.233,
      'y_center': 0.450,
      'width': 0.320,
      'height': 0.410,
      'result': 'healthy_cowhide',
      'confidence': 0.945,
    });

    batch.insert(Scan.tableName, {
      'label_id': 2,
      'detection_id': 1,
      'x_center': 0.675,
      'y_center': 0.512,
      'width': 0.280,
      'height': 0.350,
      'result': 'lumpy',
      'confidence': 0.887,
    });

    batch.insert(Scan.tableName, {
      'label_id': 3,
      'detection_id': 2,
      'x_center': 0.500,
      'y_center': 0.380,
      'width': 0.450,
      'height': 0.520,
      'result': 'mange',
      'confidence': 0.912,
    });
  }

  static Future<void> detectionDeleteAssets() async {
    await FileHandler.deleteDirectory("$detectionName/$modelFolderPrefix");
    await FileHandler.deleteDirectory(DeasesDetection.photoDirectory);
  }

  static Future<bool> detectionDeleteTables() async {
    final Batch? batch = LocalDBHandler.getBatch();
    if (batch == null) return false;
    batch.rawQuery("DROP TABLE IF EXISTS ${Scan.tableName};");
    batch.rawQuery("DROP TABLE IF EXISTS ${Deases.tableName};");
    batch.rawQuery("DROP TABLE IF EXISTS ${DeasesDetection.tableName};");
    batch.commit(noResult: true);
    return true;
  }

  static Future<bool> detectionDelete() async {
    final bool isDeleted = await detectionDeleteTables();
    if (!isDeleted) return false;
    await detectionDeleteAssets();
    return true;
  }
}
// #endregion

/// Class Deases represent the cow skin deases.
/// Use getByName method to get the data of the deases in local DB
/// Notice there is no save or create method. User can't add or change it, this is done so there will only one source of truth done by plugin download.
class Deases {
  static const tableName = "deases";

  int id;
  String name;
  String solution;

  Deases(this.id, this.name, this.solution);

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'solution': solution};
  }

  @override
  String toString() {
    return 'Deases{id: $id, name: $name, solution: $solution}';
  }

  static Deases createFromMap(Map<String, Object?> map) {
    return Deases(
      map["id"] as int,
      map["name"] as String,
      map["solution"] as String,
    );
  }

  /// Get deases from local db by the deases name.
  /// The deases name should be exactly like in the local db.
  /// The choice to search by name because the output of model can be label that more stable to compare.
  /// Return deases or null if the deases with the name didn't exist
  static Future<Deases?> getByName(String deasesName) async {
    List<Map<String, Object?>>? temp = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM $tableName WHERE name=?",
      [deasesName],
    );
    if (temp == null || temp.isEmpty) return null;
    Map<String, Object?> res = temp[0];
    return Deases.createFromMap(res);
  }
}

/// Class Deases Detection
class DeasesDetection {
  static const tableName = "deases_detections";
  static const photoDirectory = "deases_images";

  int id;
  String name;
  DateTime datetime = DateTime.timestamp();
  String imagePath;
  List<Scan> scans = [];

  DeasesDetection(this.id, this.name, this.imagePath, {DateTime? datetime}) {
    if (datetime != null) {
      this.datetime = datetime;
    }
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'imagePath': imagePath};
  }

  @override
  String toString() {
    return 'Deases{id: $id, name: $name, imagePath: $imagePath}';
  }

  static Future<DeasesDetection?> getById(int id) async {
    return null;
  }

  /// Get all of the deases detection sorted by the newest.
  /// Note that this doesn't return scans as it is intended to be used to list of all available Deases Detection (History)
  /// Use getScans instead, note that you should have this class isntance as getScans is not static method
  static Future<List<DeasesDetection>?> getAll() async {
    final List<Map<String, Object?>>? res =
        await LocalDBHandler.runRawSelectQuery("SELECT * FROM $tableName;");
    if (res == null) return null;
    return [
      for (final {
            'id': id as int,
            'name': name as String,
            'datetime': datetime as DateTime,
            'image_path': imagePath as String,
          }
          in res)
        DeasesDetection(id, name, imagePath, datetime: datetime),
    ];
  }

  /// Get all of the scan result of this deases detection.
  /// The scans instance will be stored in this.scans, this method will also return the list of the instances
  Future<List<Scan>?> getScans() async {
    final List<Map<String, Object?>>? res =
        await LocalDBHandler.runRawSelectQuery(
          "SELECT * FROM ${Scan.tableName} WHERE \"detection_id\" = $id;",
        );
    if (res == null) null;
    scans = [
      for (final {
            'id': id as int,
            'label_id': labelId as int,
            'detection_id': detectionId as int,
            'x_center': xCenter as double,
            'y_center': yCenter as double,
            'width': width as double,
            'height': height as double,
            'result': result as String,
            'confidence': confidence as double,
          }
          in res!)
        Scan(
          id,
          labelId,
          detectionId,
          xCenter,
          yCenter,
          width,
          height,
          result,
          confidence,
        ),
    ];
    return scans;
  }

  /// Create deases detection on the database and return an instance of DeasesDetection.
  /// Don't forget to use add scan to add scans data of the detection
  static Future<DeasesDetection?> createWScanComponent(
    XFile imgFile,
    List<ScanComponent> scans,
    String? name,
  ) async {
    final path = await FileHandler.storeImage(photoDirectory, imgFile, null);
    name ??= DateTime.now().toIso8601String();
    if (name.length > 255) {
      await PopUpMessage.showOkMessage(
        PopUpTitle.warning,
        "Nama deteksi harus kurang dari 255 karakter",
      );
      return null;
    }
    final id = await LocalDBHandler.runRawInsertQuery(
      """
      INSERT INTO $tableName (name, image_path)
      values (?, ?);
      """,
      [name, path],
    );
    if (id == null) return null;
    DeasesDetection detection = DeasesDetection(id, name, path);
    for (final scan in scans) {
      final scanId = await LocalDBHandler.runRawInsertQuery(
        """
        INSERT INTO ${Scan.tableName} 
        (label_id, detection_id, x_center, y_center, width, height, result, confidence)
        VALUES (?,?,?,?,?,?,?,?);
        """,
        [
          scan.labelId,
          id,
          scan.xCenter,
          scan.yCenter,
          scan.width,
          scan.height,
          scan.detectionResult,
          scan.confident,
        ],
      );
      if (scanId == null) {
        await detection.destroy();
        return null;
      }
      detection.scans.add(
        Scan(
          scanId,
          scan.labelId,
          id,
          scan.xCenter,
          scan.yCenter,
          scan.width,
          scan.height,
          scan.detectionResult,
          scan.confident,
        ),
      );
    }
    return detection;
  }

  /// Create DeasesDetection Object and Save It to the database.
  /// Return null if failed. This is prefered because it use
  /// DetectionResult than ScanComponent which already compatibe with detection pipeline
  static Future<DeasesDetection?> create(
    XFile imgFile,
    List<DetectionResult> detections,
    String? name,
  ) async {
    final path = await FileHandler.storeImage(photoDirectory, imgFile, null);
    name ??= DateTime.now().toIso8601String();

    final id = await LocalDBHandler.runRawInsertQuery(
      """
      INSERT INTO $tableName (name, image_path)
      values (?, ?);
      """,
      [name, path],
    );

    if (id == null) return null;
    DeasesDetection detection = DeasesDetection(id, name, path);

    for (final scan in detections) {
      // 1. Ambil Deases berdasarkan label, gunakan fallback default ID jika null
      final deases = await Deases.getByName(scan.label);
      if (deases == null) {
        return null;
      }
      final int labelId = deases.id; // Default labelId = 0 jika tidak ditemukan

      // 2. Ekstrak koordinat xCenter, yCenter, width, dan height dari Rect
      final double xCenter = scan.boundingBox.center.dx;
      final double yCenter = scan.boundingBox.center.dy;
      final double width = scan.boundingBox.width;
      final double height = scan.boundingBox.height;

      // 3. Fallback untuk detectionResult
      final String resultText = scan.label.isNotEmpty
          ? scan.label
          : "Tidak Diketahui";

      // 4. Fallback untuk confidence (prioritas classificationScore, lalu yoloScore, lalu 0.0)
      final double confidence = scan.classificationScore > 0
          ? scan.classificationScore
          : (scan.yoloScore > 0 ? scan.yoloScore : 0.0);

      final scanId = await LocalDBHandler.runRawInsertQuery(
        """
        INSERT INTO ${Scan.tableName} 
        (label_id, detection_id, x_center, y_center, width, height, result, confidence)
        VALUES (?,?,?,?,?,?,?,?);
        """,
        [labelId, id, xCenter, yCenter, width, height, resultText, confidence],
      );

      if (scanId == null) {
        await detection.destroy();
        return null;
      }

      detection.scans.add(
        Scan(
          scanId,
          labelId,
          id,
          xCenter,
          yCenter,
          width,
          height,
          resultText,
          confidence,
        ),
      );
    }

    return detection;
  }

  /// Delete the object from the database
  Future<bool> destroy() async {
    try {
      await LocalDBHandler.runActionQuery(
        """
        DELETE FROM ${DeasesDetection.tableName}
        WHERE id=?;
        """,
        [id],
      );
      return true;
    } catch (e) {
      PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Terjadi kesalahan saat menghapus data Deteksi pada database lokal.",
      );
      return false;
    }
  }
}

class ScanComponent {
  int labelId;
  double xCenter;
  double yCenter;
  double width;
  double height;
  String detectionResult;
  double confident;

  ScanComponent(
    this.labelId,
    this.xCenter,
    this.yCenter,
    this.width,
    this.height,
    this.detectionResult,
    this.confident,
  );
}

class Scan {
  static const tableName = "scans";

  int id;
  int labelId;
  int detectionId;

  /// Has value in range [0,1], ratio of the image
  double xCenter;

  /// Has value in range [0,1], ratio of the image
  double yCenter;

  /// Has value in range [0,1], ratio of the image
  double width;

  /// Has value in range [0,1], ratio of the image
  double height;
  String detectionResult;
  double confident;

  Scan(
    this.id,
    this.labelId,
    this.detectionId,
    this.xCenter,
    this.yCenter,
    this.width,
    this.height,
    this.detectionResult,
    this.confident,
  );

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'label_id': labelId,
      'detection_id': detectionId,
      'x_cebter': xCenter,
      'y_center': yCenter,
      'width': width,
      'height': height,
      'result': detectionResult,
      'confident': confident,
    };
  }

  @override
  String toString() {
    return 'Deases{id: $id, labelId: $labelId, xCenter: $xCenter, yCenter: $yCenter, width: $width, height: $height, detectionResult: $detectionResult, confident: $confident}';
  }
}
