import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Handler class for Local DB. It use sqlite.
/// Use LocalDBHandler.create() to create the class also it automatically open the db
class LocalDBHandler {
  static Database? db;

  LocalDBHandler._();

  /// Create a LocalDBHandler and open the database connection
  static Future<LocalDBHandler> setup() async {
    LocalDBHandler.db = await _localSetup();
    return LocalDBHandler._();
  }

  static Future<Database> _localSetup() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'sapiku.db'),
      version: 1,
      onCreate: (db, version) {
        // Create Config/Default table

        return db.execute(
          'CREATE TABLE plugins(id INTEGER PRIMARY KEY, name TEXT, isSetup BOOL DEFAULT FALSE, isActive BOOL DEFAULT FALSE)',
        );
      },
    );
  }

  /// Run Query String that doesn't return anything
  /// Call it action query
  static Future<void> runActionQuery(String query, [List<Object?>? arguments]) async {
    await db?.execute(query, arguments);
  }

  /// Run Query on specific table and retrieve all that need to return something
  /// Call it select query.
  static Future<List<Map<String, Object?>>?> runSelectQuery(String tableName) async {
    if (db == null) {
      // Show Error
      return null;
    }else{
      return await db!.query(tableName);
    }
  }

  /// Run Raw Query String that need to return something
  /// Call it select query
  static Future<List<Map<String, Object?>>?> runRawSelectQuery(String query, [List<Object?>? arguments]) async {
    if (db == null) {
      // Show Error
      return null;
    }else{
      return await db!.rawQuery(query, arguments);
    }
  }

  /// Run Raw Insert String, will return id if success
  static Future<int?> runRawInsertQuery(String query, [List<Object?>? arguments]) async {
    if (db == null) {
      // Show Error
      return null;
    }else{
      return await db!.rawInsert(query, arguments);
    }
  }
  /// Run Raw Update String, will return id if success
  static Future<int?> runRawUpdateQuery(String query, [List<Object?>? arguments]) async {
    if (db == null) {
      // Show Error
      return null;
    }else{
      return await db!.rawUpdate(query, arguments);
    }
  }
}
