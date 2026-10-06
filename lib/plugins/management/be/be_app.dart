import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sapiku/utils/utils.dart';
import 'package:sqflite/sqflite.dart';

// #region Temporary
/// Simulate setup in download plugin, used in before main
Future<void> managementSetup() async {
  const tableName = "management";
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

  final res = await LocalDBHandler.runRawSelectQuery(
    "SELECT id, isSetup FROM plugins WHERE name = ?",
    [tableName],
  );
  if (res == null) return;
  if (res.isNotEmpty) {
    if (res[0]['isSetup'] == 1) return;
  }
  final batch = LocalDBHandler.getBatch();
  if (batch == null) return;
  batch.execute("""
    CREATE TABLE IF NOT EXISTS ${Product.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        image_path TEXT NULL,
        qr_image_path TEXT NULL
    );
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
        FOREIGN KEY (product_id) REFERENCES produk(id) ON DELETE RESTRICT,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
    );
  """);
  await batch.commit(noResult: true);
  if (res.isNotEmpty) {
    await LocalDBHandler.runRawUpdateQuery(
      """
      UPDATE plugins
      SET isSetup = ?, isActive = ?
      WHERE id = ?;
      """,
      [true, true, res[0]['id']],
    );
  } else {
    await LocalDBHandler.runRawInsertQuery(
      """
      INSERT INTO plugins (name, isSetup, isActive)
      values (?, ?, ?);
      """,
      [tableName, true, true],
    );
  }
  print("Success Setup");
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
}

class Transaction {
  static const tableName = "transactions";

  int id;
  DateTime datetime;
  List<TransactionDetail>? transactionDetails;

  Transaction(this.id, this.datetime);

  static Transaction createFromMap(Map<String, Object?> map) {
    return Transaction(map["id"] as int, strToDateTime(map["datetime"] as String));
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
    List<TransactionDetailInsertComponent> details,
  ) async {
    final int? id = await LocalDBHandler.runRawInsertQuery("""
      INSERT INTO $tableName
      DEFAULT VALUES;
      """, []);
    if (id == null) return null;
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
      SET product_id = ?, transaction_id = ?, quanity = ?;
      """,
      [productId, transactionId, quantity],
    );
  }
}

// #endregion
