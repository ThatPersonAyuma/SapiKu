import 'package:image_picker/image_picker.dart';
import 'package:sapiku/plugins/detection/be/db_class/deases.dart' show Deases;
import 'package:sapiku/plugins/detection/be/db_class/scan.dart' show Scan, ScanComponent;
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sapiku/utils/utils.dart';

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
        await LocalDBHandler.runRawSelectQuery(
          "SELECT * FROM $tableName ORDER BY DATETIME(datetime) DESC;",
        );
    if (res == null) return null;
    return [
      for (final {
            'id': id as int,
            'name': name as String,
            'datetime': datetimeStr as String,
            'image_path': imagePath as String,
          }
          in res)
        DeasesDetection(id, name, imagePath, datetime: DateTime.parse(datetimeStr)),
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
    final path = await FileHandler.storeImage(photoDirectory, imgFile);
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
    final path = await FileHandler.storeImage(photoDirectory, imgFile);
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

  /// Get count of the total item of the DeasesDetection
  static Future<int?> getCount() async {
    final res = await LocalDBHandler.runRawSelectQuery("""
    SELECT COUNT(*) as c FROM $tableName;
    """);
    if (res == null || res.isEmpty) return null;
    return res[0]['c'] as int;
  }

  /// The index page using 1 as the first index
  static Future<List<DeasesDetection>?> getPage(
    int currentPage,
    int pageSize,
  ) async {
    final totalItem = await DeasesDetection.getCount();
    if (totalItem == null) return null;
    int maxPage = (totalItem / pageSize).ceil();
    if (maxPage < 1) maxPage = 1;
    if (currentPage < 1) currentPage = 1;
    if (currentPage > maxPage) currentPage = maxPage;
    int offset = (currentPage - 1) * pageSize;
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT * FROM $tableName LIMIT ? OFFSET ? ORDER BY DATETIME(datetime) DESC;
    """,
      [pageSize, offset],
    );
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
}