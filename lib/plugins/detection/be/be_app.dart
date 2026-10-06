import 'package:image_picker/image_picker.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';

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
  static const photoDirectory = "DeasesImages";

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

  Future<DeasesDetection?> getById(int id) async {
    return null;
  }

  static Future<int?> createDetection(XFile imgFile, String? name) async {
    final path = await FileHandler.storeImage(photoDirectory, imgFile, null);
    return await LocalDBHandler.runRawInsertQuery(
      "INSERT INTO $tableName(name, imagePath) VALUES(?, ?)",
      [name, path],
    );
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
          "SELECT * FROM ${Scan.tableName} WHERE ${"detection_id"} = $id;",
        );
    if (res == null) null;
    scans = [
      for (final {
            'id': id as int,
            'name': name as String,
            'datetime': datetime as DateTime,
            'image_path': imagePath as String,
          }
          in res!)
        Scan(id, name, imagePath, datetime: datetime),
    ];
    return scans;
  }
}

class Scan {
  static const tableName = "scans";

  int id;
  int labelId;
  int detectionId;

  /// Has value in range [0,1], ratio of the image
  double xCebter;

  /// Has value in range [0,1], ratio of the image
  double yCenter;

  /// Has value in range [0,1], ratio of the image
  double width;

  /// Has value in range [0,1], ratio of the image
  double height;
  String detectionResult;
  double accuration;
  double confident;

  Scan(
    this.id,
    this.labelId,
    this.detectionId,
    this.xCebter,
    this.yCenter,
    this.width,
    this.height,
    this.detectionResult,
    this.accuration,
    this.confident,
  );

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'labelId': labelId,
      'xCebter': xCebter,
      'yCenter': yCenter,
      'width': width,
      'height': height,
      'detectionResult': detectionResult,
      'accuration': accuration,
      'confident': confident,
    };
  }

  @override
  String toString() {
    return 'Deases{id: $id, labelId: $labelId, xCebter: $xCebter, yCenter: $yCenter, width: $width, height: $height, detectionResult: $detectionResult, accuration: $accuration, confident: $confident}';
  }
}
