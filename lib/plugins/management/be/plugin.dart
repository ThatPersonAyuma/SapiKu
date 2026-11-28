import 'package:sapiku/plugins/management/be/db_class/product.dart'
    show Product;
import 'package:sapiku/plugins/management/be/db_class/transaction.dart'
    show Transaction;
import 'package:sapiku/plugins/management/be/db_class/transaction_detail.dart'
    show TransactionDetail;
import 'package:sapiku/plugins/management/be/sync.dart' show SyncEngine;
import 'package:sapiku/plugins/management/be/report.dart';
import 'package:sapiku/utils/cloudinary_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sapiku/utils/utils.dart';
import 'package:sqflite/sqflite.dart' show Batch;

// #region Temporary
/// Simulate setup in download plugin, used in before main
class ManagementPlugin {
  static const managementName = "management";
  static Future<bool> managementSetup(
    void Function(int) callback,
    String version,
  ) async {
    callback(0);
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM ${Plugin.tableName} WHERE name = ?",
      [managementName],
    );
    if (res == null) return false;
    if (res.isNotEmpty) {
      if (res[0]['is_setup'] == 1) {
        callback(100);
        return true;
      }
    }
    // Because the data is not cleaned perfectly, we need to avoid redundant adding
    final batch = LocalDBHandler.getBatch();
    if (batch == null) return false;

    await managementCreateTables(batch);

    await managementSeeder(batch, callback);

    await batch.commit(noResult: true);
    callback(20);
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
        [managementName, boolToInt(true), version],
      );
    }
    print("Success Setup");
    return true;
  }

  static Future<void> managementCreateTables(Batch batch) async {
    batch.execute("""
      CREATE TABLE IF NOT EXISTS ${Product.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(255) NOT NULL UNIQUE,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        qr_image_path TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """);
    batch.execute("""
      CREATE TRIGGER IF NOT EXISTS update_timestamp
      AFTER UPDATE ON ${Product.tableName}
      BEGIN
          UPDATE ${Product.tableName} 
          SET updated_at = CURRENT_TIMESTAMP 
          WHERE id = OLD.id;
      END;
    """);
    batch.execute("""
      CREATE TABLE IF NOT EXISTS ${Transaction.tableName} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    """);
    batch.execute("""
      CREATE TABLE IF NOT EXISTS ${TransactionDetail.tableName} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          transaction_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY (product_id) REFERENCES ${Product.tableName}(id) ON DELETE RESTRICT,
          FOREIGN KEY (transaction_id) REFERENCES ${Transaction.tableName}(id) ON DELETE CASCADE
      );
    """);
    SyncEngine.setup(batch);
  }

  /// For Download all assets needed for the start of the plugin
  static Future<List<String>?> downloadAssets(
    void Function(int) callback,
  ) async {
    List<String> paths = List.filled(3, "");
    // Download for susu ori
    final res1 = await CloudinaryHandler.downloadAndStoreImageWProgress(
      managementName,
      'scaled_1000274711.jpg',
      callback,
      20,
    );
    if (res1 == null) {
      return null;
    } else {
      paths[0] = res1;
    }
    callback(6);
    // Download for susu coklat
    final res2 = await CloudinaryHandler.downloadAndStoreImageWProgress(
      managementName,
      'scaled_1000274710.jpg',
      callback,
      20,
    );
    if (res2 == null) {
      return null;
    } else {
      paths[1] = res2;
    }
    callback(7);
    // Download for susu ori
    final res3 = await CloudinaryHandler.downloadAndStoreImageWProgress(
      managementName,
      'scaled_1000274712.jpg',
      callback,
      20,
    );
    if (res3 == null) {
      return null;
    } else {
      paths[2] = res3;
    }
    callback(7);
    return paths;
  }

  /// Seeding the database with dummy data, for dev & preview only
  static Future<void> managementSeeder(
    Batch batch,
    void Function(int) callback,
  ) async {
    final paths = await downloadAssets(callback);
    if (paths == null) return;
    // 1. Seed Table Product
    batch.insert(Product.tableName, {
      'name': 'Susu Original',
      'price': 8000.0,
      'stock': 50,
      'image_path': paths[0],
      'qr_image_path': null,
    });

    batch.insert(Product.tableName, {
      'name': 'Susu Coklat',
      'price': 10000.0,
      'stock': 100,
      'image_path': paths[1],
      'qr_image_path': null,
    });

    batch.insert(Product.tableName, {
      'name': 'Susu Stroberi',
      'price': 10000.0,
      'stock': 30,
      'image_path': paths[2],
      'qr_image_path': null,
    });

    // 2. Seed Table Transaction
    // Menggunakan ISO8601 string atau membiarkan SQLite mengisi CURRENT_TIMESTAMP
    batch.insert(Transaction.tableName, {
      'datetime': DateTime.parse(
        '2026-11-06 03:05:52.255158+00',
      ).toIso8601String(),
    });

    batch.insert(Transaction.tableName, {
      'datetime': DateTime.parse(
        '2026-11-06 03:06:18.098768+00',
      ).toIso8601String(),
    });

    // 3. Seed Table TransactionDetail
    // Referensi ke product_id (1, 2, 3) dan transaction_id (1, 2)
    batch.insert(TransactionDetail.tableName, {
      'product_id': 1,
      'transaction_id': 1,
      'quantity': 2,
    });

    batch.insert(TransactionDetail.tableName, {
      'product_id': 2,
      'transaction_id': 1,
      'quantity': 1,
    });

    batch.insert(TransactionDetail.tableName, {
      'product_id': 3,
      'transaction_id': 2,
      'quantity': 1,
    });
  }

  static Future<void> manageTest() async {
    // Transaction.create(
    //   [TransactionDetailInsertComponent(2, 2)],
    //   date: DateTime(2017, 9, 7, 17, 30)
    // );
    // Transaction.create(
    //   [TransactionDetailInsertComponent(2, 2)]
    // );
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM ${TransactionDetail.tableName}",
    );
    print("Transaction detail:\n$res");
    final res2 = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM ${Transaction.tableName}",
    );
    print("Transaction:\n$res2");
    final res3 = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM ${Product.tableName}",
    );
    print("Product:\n$res3");
    Report.saveReport(
      DateTime(2016, 9, 7, 17, 0),
      DateTime.now().add(const Duration(days: 1)),
    );
  }

  /// Function to drop all management table
  static Future<bool> manageDropTables() async {
    final Batch? batch = LocalDBHandler.getBatch();
    if (batch == null) return false;
    batch.rawQuery("DROP TABLE IF EXISTS ${TransactionDetail.tableName};");
    batch.rawQuery("DROP TABLE IF EXISTS ${Product.tableName};");
    batch.rawQuery("DROP TABLE IF EXISTS ${Transaction.tableName};");
    await batch.commit(noResult: true);
    return true;
  }

  /// Method for delete plugin management
  static Future<bool> managementDelete() async {
    final bool isDeleted = await manageDropTables();
    if (!isDeleted) return false;
    await FileHandler.deleteDirectory(Product.productImgPath);
    await FileHandler.deleteDirectory(Product.qrPhotoPath);
    return true;
  }
}
// #endregion

// #region Utils

// #endregion
