import 'dart:ui';
import 'package:sapiku/plugins/detection/be/db_class/deases.dart' show Deases;
import 'package:sapiku/plugins/detection/be/db_class/deases_Detection.dart'
    show DeasesDetection;
import 'package:sapiku/plugins/detection/be/db_class/scan.dart' show Scan;
import 'package:sapiku/utils/cloudinary_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sapiku/utils/utils.dart';
import 'package:sqflite/sqflite.dart';

// #region Setup & Testing

class DetectionPlugin {
  // #region Constant Value
  static const detectionName = "detection";
  static const modelAssetsId = "1WC6U1IBdGwmcUvyGQoG04CPrUdywfkYL";
  static const modelFolderPrefix = "models";

  /// Filename of YOLO Model
  static const yoloFileName = "yolov8n_f32.tflite";

  /// Filename of MobileNet Model
  static const mobNetFileName = "mobilenetv3_f32.tflite";

  // #region Detection Images
  static const imageName1 = "scaled_1000274709.jpg";
  static const imageName2 = "scaled_1000274707.jpg";
  // #endregion

  // #endregion

  static Future<bool> detectionSetup(
    void Function(int) callback,
    String version,
  ) async {
    print("Setup");
    callback(0);
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM ${Plugin.tableName} WHERE name = ?",
      [detectionName],
    );
    if (res == null) return false;
    if (res.isNotEmpty) {
      if (res[0]['is_setup'] == 1) {
        callback(100);
        return true;
      }
    }
    final batch = LocalDBHandler.getBatch();
    if (batch == null) return false;
    final isDownloaded = await downloadModelAssets(callback);
    if (!isDownloaded) return false;

    await detectionCreateTables(batch);

    await detectionSeeder(batch, callback);

    await batch.commit(noResult: true);
    callback(6);
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
  static Future<List<String>?> downloadAssets(
    void Function(int) callback,
  ) async {
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
    callback(2);
    final res2 = await CloudinaryHandler.downloadAndStoreImage(
      detectionName,
      imageName2,
    );
    if (res2 == null) {
      return null;
    } else {
      paths[1] = res2;
    }
    callback(2);
    return paths;
  }

  /// Download the inference assets needed.
  /// This will download the model data from google drive
  static Future<bool> downloadModelAssets(void Function(int) callback) async {
    print("Downloading model assets");
    final modelRes = await downloadAndExtractZipWProgress(
      modelAssetsId,
      "$detectionName/models",
      callback,
      maxContribution: 70,
      decodeComtribution: 10,
    );
    print("Result: $modelRes");
    if (!modelRes) return false;
    return true;
  }

  /// Seeding the database with dummy data, for dev & preview only
  static Future<void> detectionSeeder(
    Batch batch,
    void Function(int) callback,
  ) async {
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
