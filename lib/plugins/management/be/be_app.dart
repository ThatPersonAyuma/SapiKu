import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';
import 'package:sapiku/utils/cloudinary_handler.dart';
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sapiku/utils/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

// final List<Map<String, dynamic>>?
// schemaResult = await LocalDBHandler.runRawSelectQuery(
//   "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'android_%';",
//   [],
// );
// if (schemaResult != null) {
//   for (var row in schemaResult) {
//     print('Table: ${row['name']}');
//     print('Schema: ${row['sql']}\n');
//   }
// }
// #region Temporary
/// Simulate setup in download plugin, used in before main
const managementName = "management";
Future<bool> managementSetup(VoidCallback callback) async {
  final res = await LocalDBHandler.runRawSelectQuery(
    "SELECT id, is_setup FROM ${Plugin.tableName} WHERE name = ?",
    [managementName],
  );
  callback();
  if (res == null) return false;
  if (res.isNotEmpty) {
    if (res[0]['is_setup'] == 1) return true;
  }
  // Because the data is not cleaned perfectly, we need to avoid redundant adding
  if (res.isEmpty){
    final batch = LocalDBHandler.getBatch();
    if (batch == null) return false;

    await managementCreateTables(batch);
    callback();

    await managementSeeder(batch, callback);
    
    await batch.commit(noResult: true);
  }
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
      INSERT INTO plugins (name, is_setup)
      values (?, ?);
      """,
      [managementName, boolToInt(true)],
    );
  }
  callback();
  print("Success Setup");
  return true;
}

Future<void> managementCreateTables(Batch batch) async {
  batch.execute("""
    CREATE TABLE IF NOT EXISTS ${Product.tableName} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
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
        datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
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
}

/// For Download all assets needed for the start of the plugin
Future<List<String>?> downloadAssets(VoidCallback callback) async {
  List<String> paths = List.filled(3, "");
  // Download for susu ori
  final res1 = await CloudinaryHandler.downloadAndStoreImage(
    managementName,
    'susu_ori.jpg',
  );
  if (res1 == null) {
    return null;
  } else {
    paths[0] = res1;
  }
  callback();
  // Download for susu coklat
  final res2 = await CloudinaryHandler.downloadAndStoreImage(
    managementName,
    'susu_coklat.jpg',
  );
  if (res2 == null) {
    return null;
  } else {
    paths[1] = res2;
  }
  callback();
  // Download for susu ori
  final res3 = await CloudinaryHandler.downloadAndStoreImage(
    managementName,
    'susu_stroberi.jpg',
  );
  if (res3 == null) {
    return null;
  } else {
    paths[2] = res3;
  }
  callback();
  return paths;
}

/// Seeding the database with dummy data, for dev & preview only
Future<void> managementSeeder(Batch batch, VoidCallback callback) async {
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
    'datetime': DateTime.now().toUtc().toIso8601String(),
  });

  batch.insert(Transaction.tableName, {
    'datetime': DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 1))
        .toIso8601String(),
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

Future<void> manageTest() async {
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
  ManageUtils.saveReport(
    DateTime(2016, 9, 7, 17, 0),
    DateTime.now().add(const Duration(days: 1)),
  );
}
// #endregion

// #region DB Table Class Bridge
class Product {
  static String tableName = "products";
  static String qrPhotoPath = "qr_images";
  static String productImgPath = "product_images";

  int id;
  String name;
  double price;
  int stock;
  String? imagePath;
  String? qrImagePath;
  Product(
    this.id,
    this.name,
    this.price,
    this.stock,
    this.imagePath,
    this.qrImagePath,
  ) {
    _ensureQrImage();
  }
  Map<String, Object?> toMap() {
    return {
      'id': id,
      "name": name,
      "price": price,
      "stock": stock,
      "imagePath": imagePath,
      "qrImagePath": qrImagePath,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Product{id: $id, name:$name price:$price stock:$stock imagePath: $imagePath qrImagePath: $qrImagePath}';
  }

  static Product createFromMap(Map<String, Object?> map) {
    return Product(
      map["id"] as int,
      map["name"] as String,
      map["price"] as double,
      map["stock"] as int,
      map["image_path"] as String?,
      map["qr_image_path"] as String?,
    );
  }

  /// Ensure QR is created
  Future<void> _ensureQrImage() async {
    if (qrImagePath == null) {
      print("creating");
      final bytes = await getQrPngbyId(id);
      if (bytes != null) {
        print("got qr");
        // 2. Dapatkan direktori penyimpanan dokumen
        final directory = await getApplicationDocumentsDirectory();

        // 3. Tentukan path file yang akan disimpan
        final filePath =
            '${directory.path}/$qrPhotoPath/${DateTime.now().millisecondsSinceEpoch}.png';

        // 4. Buat file dan tulis bytes ke dalamnya
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        qrImagePath = file.path;
        saveToDb();
        print("saved");
      }
    }
  }

  /// Get Product by ID, return none if id didnt exist or db is not setup properly
  static Future<Product?> getById(int id) async {
    List<Map<String, Object?>>? temp = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM $tableName WHERE id=$id",
    );
    if (temp == null || temp.isEmpty) return null;
    Map<String, Object?> res = temp[0];
    return Product.createFromMap(res);
  }

  /// Get Product by name, return none if id didnt exist or db is not setup properly
  static Future<Product?> getByName(String name) async {
    List<Map<String, Object?>>? temp = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM $tableName WHERE name LIKE ?",
      [name],
    );
    if (temp == null || temp.isEmpty) return null;
    Map<String, Object?> res = temp[0];
    return Product.createFromMap(res);
  }

  /// Get all of product, return list, can be empty.
  /// return null if db is not setup properly
  static Future<List<Product>?> getAll() async {
    List<Map<String, Object?>>? temp = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM $tableName",
    );
    if (temp == null || temp.isEmpty) return null;
    return [for (final map in temp) createFromMap(map)];
  }

  /// Create a Product isntance and insert it to the database.
  /// Return product fi success otherwise null
  static Future<Product?> create(
    String name,
    double price,
    int stock,
    XFile? imgFile,
  ) async {
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id FROM $tableName WHERE name = ?",
      [name],
    );
    // Show error product has same name
    if (res != null && res.isNotEmpty) return null;
    final imgPath = imgFile != null
        ? (await FileHandler.storeImage(productImgPath, imgFile, null))
        : null;
    int? id = await LocalDBHandler.runRawInsertQuery(
      "INSERT INTO $tableName(name, price, stock, image_path) VALUES(?, ?, ?, ?)",
      [name, price, stock, imgPath],
    );
    if (id == null) return null;
    return Product(id, name, price, stock, imgPath, null);
  }

  /// Save current Product, return int of count if success otherwise null
  Future<int?> saveToDb() async {
    return await LocalDBHandler.runRawUpdateQuery(
      "UPDATE $tableName SET name = ?, price = ?, stock = ?, image_path = ?, qr_image_path = ? WHERE id = ?;",
      [name, price, stock, imagePath, qrImagePath, id],
    );
  }

  /// Change product image and destroy before if exist also change current imagePath and save to the database
  Future<void> changeProductImage(XFile img) async {
    imagePath = await FileHandler.storeImage(productImgPath, img, imagePath);
    saveToDb();
  }

  Future<bool> saveQRtoGallery() async {
    try {
      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();

        if (!granted) {
          return false;
        }
      }
      if (qrImagePath == null) _ensureQrImage();
      if (qrImagePath == null) return false;
      final img = File(qrImagePath!);
      if (!img.existsSync()) {
        print("file doesnt exist");
        return false;
      }
      final bytes = img.readAsBytesSync();

      await Gal.putImageBytes(
        bytes,
        name: 'qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      return true;
    } catch (e) {
      debugPrint('Save QR error: $e');
      return false;
    }
  }

  /// Open qr scan and scan the qr. Return Product if qr scanned succesfully.
  /// Otherwise return null. This can happen if qr scan failed or product with that id didn't exist
  static Future<Product?> getFromQr(BuildContext ctx) async {
    final int? id = await Navigator.push(
      ctx,
      MaterialPageRoute<int>(builder: (context) => const QRScannerPage()),
    );
    // Error on read qr
    if (id == null) return null;
    return await Product.getById(id);
  }

  /// Delete a record by given id
  static Future<void> destroyById(int id) async {
    return await LocalDBHandler.runActionQuery(
      "DELETE FROM $tableName WHERE id=?",
      [id],
    );
  }

  /// Delete self from local database. Note this is not destroy the instance but only delete from the local database
  Future<void> destroy() async {
    return await LocalDBHandler.runActionQuery(
      "DELETE FROM $tableName WHERE id=?",
      [id],
    );
  }
}

class Transaction {
  static const tableName = "transactions";

  int id;
  DateTime datetime;
  List<TransactionDetail>? transactionDetails;

  Transaction(this.id, this.datetime);

  static Transaction createFromMap(Map<String, Object?> map) {
    return Transaction(
      map["id"] as int,
      strToDateTime(map["datetime"] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, "datetime": datetime};
  }

  @override
  String toString() {
    return 'Transaction{id: $id, datetime:$datetime}';
  }

  /// Get all of the transaction Data
  static Future<List<Transaction>?> getAll() async {
    final List<Map<String, Object?>>? res =
        await LocalDBHandler.runRawSelectQuery(
          "SELECT * FROM $tableName ORDER BY datetime DESC;",
        );
    if (res == null) return null;
    return [for (final map in res) Transaction.createFromMap(map)];
  }

  /// Get all of the transaction detail data. This method will return list of TransactionDetails
  /// Also will save it to the attribute of self transactionDetails
  Future<List<TransactionDetail>?> getAllTransactionDetails() async {
    final res = await LocalDBHandler.runRawSelectQuery("""
      SELECT * FROM ${TransactionDetail.tableName}
      WHERE transaction_id = $id
      """);
    // ORDER BY name;
    if (res == null) return null;
    transactionDetails = [
      for (final map in res) TransactionDetail.createFromMap(map),
    ];
    return transactionDetails;
  }

  Future<int?> saveToDB() async {
    return await LocalDBHandler.runRawUpdateQuery(
      """
      UPDATE $tableName 
      SET datetime = ?;
      """,
      [datetime],
    );
  }

  static Future<Transaction?> getById(int id) async {
    List<Map<String, Object?>>? temp = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM $tableName WHERE id=$id",
    );
    if (temp == null || temp.isEmpty) return null;
    Map<String, Object?> res = temp[0];
    return Transaction.createFromMap(res);
  }

  static Future<Transaction?> create(
    List<TransactionDetailInsertComponent> details, {
    DateTime? date,
  }) async {
    int? id;
    if (date == null) {
      id = await LocalDBHandler.runRawInsertQuery("""
        INSERT INTO $tableName
        DEFAULT VALUES;
        """, []);
    } else {
      id = await LocalDBHandler.runRawInsertQuery(
        """
        INSERT INTO $tableName(datetime)
        VALUES(datetime(?));
        """,
        [date.toIso8601String()],
      );
    }
    if (id == null) return null;
    List<int> targetIds = [for (final detail in details) detail.productId];

    // Membuat placeholder '?, ?, ?' sesuai jumlah isi List
    String placeholders = List.filled(targetIds.length, '?').join(',');
    final List<Map<String, Object?>>? res =
        await LocalDBHandler.runRawSelectQuery(
          'SELECT * FROM ${Product.tableName} WHERE id IN ($placeholders)',
          targetIds,
        );
    if (res == null) return null;
    final List<Product> products = [
      for (final map in res) Product.createFromMap(map),
    ];
    // Check if quantity meet demand
    for (final detail in details) {
      final Product? p = products
          .where((p) => p.id == detail.productId)
          .firstOrNull;
      if (p == null) return null;
      if (detail.quantity <= p.stock) {
        p.stock -= detail.quantity;
        p.saveToDb(); // This should be batch in the end consider to change into sql update string rather than execute one to avoid changing while there would be an error
      } else {
        return null;
      }
    }

    final Batch? batch = LocalDBHandler.getBatch();
    if (batch == null) return null;
    for (final detail in details) {
      batch.rawInsert(
        """
        INSERT INTO ${TransactionDetail.tableName}(product_id, transaction_id, quantity)
        VALUES(?, ?, ?);
        """,
        [detail.productId, id, detail.quantity],
      );
    }
    batch.commit(noResult: true);
    return Transaction.getById(id);
  }

  /// Delete a record by given id
  static Future<void> destroyById(int id) async {
    return await LocalDBHandler.runActionQuery(
      "DELETE FROM $tableName WHERE id=?",
      [id],
    );
  }

  /// Delete self from local database. Note this is not destroy the instance but only delete from the local database
  Future<void> destroy() async {
    return await LocalDBHandler.runActionQuery(
      "DELETE FROM $tableName WHERE id=?",
      [id],
    );
  }

  /// Get all transaction and its transaction detail needed for transaction report
  /// The detail needed is transaction static and product static
  static Future<List<Map<String, Object?>>?> getAllTransactionAndDetails(
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, Object?>>? res =
        await LocalDBHandler.runRawSelectQuery(
          """
      SELECT 
        t.id AS id,
        t.datetime AS datetime, 
        SUM(td.quantity * COALESCE(c.price, 0.0)) AS total_price
      FROM $tableName t
      INNER JOIN ${TransactionDetail.tableName} td
        ON t.id = td.transaction_id
      INNER JOIN ${Product.tableName} c
        ON c.id = td.product_id
      WHERE datetime(t.datetime) >= datetime(?) 
        AND datetime(t.datetime) <= datetime(?)
      GROUP BY t.id, t.datetime
      ORDER BY t.datetime ASC;
      """,
          [start.toIso8601String(), end.toIso8601String()],
        );
    print("res trans:\n$res");
    return res;
  }

  /// Get all transaction and its transaction detail needed for transaction report
  /// The detail needed is transaction static and product static
  static Future<List<Map<String, Object?>>?> getAllProductStat(
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, Object?>>? res =
        await LocalDBHandler.runRawSelectQuery(
          """
      SELECT 
        c.name AS product_name, 
        SUM(td.quantity) AS total_selled
      FROM $tableName t
      INNER JOIN ${TransactionDetail.tableName} td
        ON t.id = td.transaction_id
      INNER JOIN ${Product.tableName} c
        ON c.id = td.product_id
      WHERE datetime(t.datetime) >= datetime(?) 
        AND datetime(t.datetime) <= datetime(?)
      GROUP BY c.id
      ORDER BY t.datetime ASC;
      """,
          [start.toIso8601String(), end.toIso8601String()],
        );
    print("res prod:\n$res");
    return res;
  }
}

/// We can only calculate selledQuantity because the product quantity itself is dynamic.
/// And we dont store the quantity on that day.
class ProductReport {
  String name;
  int selledQuantity;

  ProductReport(this.name, this.selledQuantity);

  static ProductReport createFromMap(Map<String, Object?> map) {
    return ProductReport(
      map["product_name"] as String,
      map["total_selled"] as int,
    );
  }

  static List<ProductReport> createFromListMap(
    List<Map<String, Object?>> data,
  ) {
    // Need to create two type of data
    return [for (final map in data) ProductReport.createFromMap(map)];
  }
}

class TransactionRecord {
  DateTime date;
  double totalPrice;

  TransactionRecord(this.date, this.totalPrice);

  static TransactionRecord createFromMap(Map<String, Object?> map) {
    return TransactionRecord(
      strToDateTime((map["datetime"] as String)),
      map["total_price"] as double,
    );
  }

  static List<TransactionRecord> createFromListMap(
    List<Map<String, Object?>> data,
  ) {
    // Need to create two type of data
    return [for (final map in data) TransactionRecord.createFromMap(map)];
  }
}

class TransactionDetailInsertComponent {
  int productId;
  int quantity;

  TransactionDetailInsertComponent(this.productId, this.quantity);
}

class TransactionDetail {
  static const tableName = "transaction_details";

  int id;
  int productId;
  int transactionId;
  int quantity;

  TransactionDetail(this.id, this.productId, this.transactionId, this.quantity);

  static TransactionDetail createFromMap(Map<String, Object?> map) {
    return TransactionDetail(
      map["id"] as int,
      map["product_id"] as int,
      map["transaction_id"] as int,
      map["quantity"] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'transaction_id': transactionId,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return 'TransactionDetail{id: $id, product_id: $productId,  transaction_id: $transactionId,  quantity: $quantity}';
  }

  Future<int?> saveToDB() async {
    // Show error, quantity can't be null
    if (quantity < 0) return null;
    return await LocalDBHandler.runRawUpdateQuery(
      """
      UPDATE $tableName 
      SET product_id = ?, transaction_id = ?, quantity = ?;
      """,
      [productId, transactionId, quantity],
    );
  }
}

// #endregion

// #region Utils
/// Class to access utils method for management feature
class ManageUtils {
  static const _cloudPwKey = "cloudPwKey";

  static final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  /// Set cloud PW and store it in secure storage
  static Future<void> setCloudSyncPw(String pw) async {
    await _storage.write(key: _cloudPwKey, value: pw);
  }

  /// Get the cloud PW string, return null if not set
  static Future<String?> getCloudSyncPw() async {
    return _storage.read(key: _cloudPwKey);
  }

  static Future<bool> login() async {
    final pw = await getCloudSyncPw();
    if (pw == null) return false;
    final success = await cloudLogin(
      const String.fromEnvironment("SUPABASE_USER_EMAIL"),
      pw,
    );
    return success;
  }

  /// Format the excel for transaction detail report
  static Future<bool> _createTransReportExcel(
    DateTime start,
    DateTime end,
    Worksheet sheet,
    List<TransactionRecord>? reportData,
  ) async {
    const List<String> columnNames = ["Waktu", "Total"];
    reportData ??= await createTransReport(start, end);
    if (reportData == null) return false;

    sheet.getRangeByIndex(1, 1).setText(columnNames[0]);
    sheet.getRangeByIndex(1, 2).setText(columnNames[1]);
    int ri = 1;
    for (final record in reportData) {
      ++ri;
      sheet.getRangeByIndex(ri, 1).setDateTime(record.date);
      sheet.getRangeByIndex(ri, 2).setNumber(record.totalPrice);
    }
    return true;
  }

  /// Format the excel sheet for product statistic reports
  static Future<bool> _createProductReportExcel(
    DateTime start,
    DateTime end,
    Worksheet sheet,
    List<ProductReport>? reportData,
  ) async {
    const List<String> columnNames = ["Nama Produk", "Total Terjual"];
    reportData ??= await createProdReport(start, end);
    if (reportData == null) return false;

    sheet.getRangeByIndex(1, 4).setText(columnNames[0]);
    sheet.getRangeByIndex(1, 5).setText(columnNames[1]);
    int ri = 1;
    for (final record in reportData) {
      ++ri;
      sheet.getRangeByIndex(ri, 4).setText(record.name);
      sheet.getRangeByIndex(ri, 5).setNumber(record.selledQuantity.toDouble());
    }
    return true;
  }

  /// Get List of TransactionRecord to show the report of transaction/sell.
  /// Return null if error
  static Future<List<TransactionRecord>?> createTransReport(
    DateTime start, // Add end
    DateTime end,
  ) async {
    start = start.toUtc();
    end = end.toUtc();
    final res = await Transaction.getAllTransactionAndDetails(start, end);
    if (res == null) return null;
    return TransactionRecord.createFromListMap(res);
  }

  /// Get List of ProductReport to show the report of selled product stat.
  /// Return null if error
  static Future<List<ProductReport>?> createProdReport(
    DateTime start, // Add end
    DateTime end,
  ) async {
    start = start.toUtc();
    end = end.toUtc();
    final res = await Transaction.getAllProductStat(start, end);
    if (res == null) return null;
    return ProductReport.createFromListMap(res);
  }

  /// Cretae excel and save report on it. It sgould be saved in download directory.
  /// Pass the reportDara if you have list of TransactionRecord to avoid calling createReport twice.
  /// Return true if success, otherwise false
  static Future<bool> saveReport(
    DateTime start,
    DateTime end, {
    List<TransactionRecord>? reportData,
    List<ProductReport>? productData,
  }) async {
    final filePath = '${start.toIso8601String()}-${end.toIso8601String()}.xlsx';
    final Workbook wb = Workbook();
    final Worksheet sheet = wb.worksheets[0];
    await _createTransReportExcel(start, end, sheet, reportData);
    await _createProductReportExcel(start, end, sheet, productData);
    FileHandler.saveFileWithPicker(
      bytes: wb.saveAsStream(),
      fileName: filePath,
    );
    wb.dispose();
    return true;
  }
}

// #endregion
