import 'package:path/path.dart';
import 'package:sapiku/utils/utils.dart';
import 'package:sqflite/sqflite.dart';

/// Handler class for Local DB. It use sqlite.
/// Use LocalDBHandler.create() to create the class also it automatically open the db
class LocalDBHandler {
  static Database? db;

  LocalDBHandler._();

  /// Create a LocalDBHandler and open the database connection
  static Future<LocalDBHandler> setup() async {
    // databaseFactory.deleteDatabase(join(await getDatabasesPath(), 'sapiku.db'));
    LocalDBHandler.db = await _localSetup();
    // final columns = await LocalDBHandler.runRawSelectQuery("PRAGMA table_info(plugins);", []);
    // print("Struktur kolom: $columns");
    return LocalDBHandler._();
  }

  static Future<Database> _localSetup() async {
    // print("Database path: ${join(await getDatabasesPath(), 'sapiku.db')}");
    return await openDatabase(
      join(await getDatabasesPath(), 'sapiku.db'),
      version: 1,
      onConfigure: (db) async {
        // Wajib diaktifkan di sini agar berlaku untuk setiap koneksi
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) {
        // Create Config/Default table

        return db.execute(
          'CREATE TABLE ${Plugin.tableName}(id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, is_setup BOOL DEFAULT FALSE)',
        );
      },
    );
  }

  /// Run Query String that doesn't return anything.
  /// Only run single execution, indicate by ';'.
  /// Call it action query.
  static Future<void> runActionQuery(
    String query, [
    List<Object?>? arguments,
  ]) async {
    await db?.execute(query, arguments);
  }

  /// Run Query on specific table and retrieve all that need to return something
  /// Call it select query.
  static Future<List<Map<String, Object?>>?> runSelectQuery(
    String tableName,
  ) async {
    if (db == null) {
      // Show Error
      return null;
    } else {
      return await db!.query(tableName);
    }
  }

  /// Run Raw Query String that need to return something
  /// Call it select query
  static Future<List<Map<String, Object?>>?> runRawSelectQuery(
    String query, [
    List<Object?>? arguments,
  ]) async {
    if (db == null) {
      // Show Error
      return null;
    } else {
      return await db!.rawQuery(query, arguments);
    }
  }

  /// Run Raw Insert String, will return id if success
  static Future<int?> runRawInsertQuery(
    String query, [
    List<Object?>? arguments,
  ]) async {
    if (db == null) {
      // Show Error
      return null;
    } else {
      return await db!.rawInsert(query, arguments);
    }
  }

  /// Run Raw Update String, will return id if success
  static Future<int?> runRawUpdateQuery(
    String query, [
    List<Object?>? arguments,
  ]) async {
    if (db == null) {
      // Show Error
      return null;
    } else {
      return await db!.rawUpdate(query, arguments);
    }
  }

  static Batch? getBatch() {
    if (db == null) {
      // Show Error
      return null;
    } else {
      return db!.batch();
    }
  }
}

class Plugin {
  static const tableName = "plugins";
  int id;
  String name;
  bool isSetup;

  Plugin(this.id, this.name, this.isSetup);

  static Plugin createFromMap(Map<String, Object?> map) {
    return Plugin(
      map['id'] as int,
      map['name'] as String,
      (map['is_setup'] as int)==1,
    );
  }

  static Future<Plugin?> getFromByName(String name) async {
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM $tableName WHERE name = ?;",
      [name],
    );
    if (res == null) return null;
    if (res.isEmpty) return null;
    return Plugin.createFromMap(res[0]);
  }

  Future<int?> saveToDb() async {
    return await LocalDBHandler.runRawUpdateQuery(
      "UPDATE $tableName SET name = ?, is_setup = ? WHERE id = ?;",
      [name, boolToInt(isSetup), id],
    );
  }
}
