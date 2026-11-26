import 'package:sapiku/utils/db/local_handler.dart';

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