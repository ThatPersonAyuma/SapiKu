import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:workmanager/workmanager.dart';

// #region Temporary
/// Simulate setup in download plugin, used in before main
class ManagementPlugin {
  static const managementName = "management";
  static Future<bool> managementSetup(
    VoidCallback callback,
    String version,
  ) async {
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM ${Plugin.tableName} WHERE name = ?",
      [managementName],
    );
    if (res == null) return false;
    callback();
    if (res.isNotEmpty) {
      if (res[0]['is_setup'] == 1) return true;
    }
    // Because the data is not cleaned perfectly, we need to avoid redundant adding
    final batch = LocalDBHandler.getBatch();
    if (batch == null) return false;

    await managementCreateTables(batch);
    callback();

    await managementSeeder(batch, callback);

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
        [managementName, boolToInt(true), version],
      );
    }
    callback();
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
  static Future<List<String>?> downloadAssets(VoidCallback callback) async {
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
  static Future<void> managementSeeder(
    Batch batch,
    VoidCallback callback,
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
    ManageUtils.saveReport(
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

// #region DB Table Class Bridge
class Product {
  static const String tableName = "products";
  static String qrPhotoPath = "qr_images";
  static String productImgPath = "product_images";

  int id;
  String name;
  double price;
  int stock;
  String? imagePath;
  String? qrImagePath;
  late bool isDeleted;
  Product(
    this.id,
    this.name,
    this.price,
    this.stock,
    this.imagePath,
    this.qrImagePath, {
    bool? isDeleted,
  }) {
    if (isDeleted != null) {
      this.isDeleted = isDeleted;
    } else {
      this.isDeleted = false;
    }
    _ensureQrImage();
  }
  Map<String, Object?> toMap() {
    return {
      'id': id,
      "name": name,
      "price": price,
      "stock": stock,
      "image_path": imagePath,
      "qr_image_path": qrImagePath,
      "is_deleted": isDeleted,
    };
  }

  Map<String, Object?> toCloudMap() {
    return {
      "name": name,
      "price": price,
      "stock": stock,
      "image_name": imagePath?.split("/").last,
      "is_deleted": isDeleted,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Product{id: $id, name:$name price:$price stock:$stock imagePath: $imagePath qrImagePath: $qrImagePath}';
  }

  static Product createFromMap(Map<String, Object?> map) {
    final isDeleted = (map["is_deleted"] as int) == 1;
    return Product(
      map["id"] as int,
      map["name"] as String,
      map["price"] as double,
      map["stock"] as int,
      map["image_path"] as String?,
      map["qr_image_path"] as String?,
      isDeleted: isDeleted,
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

  /// Get Product by ID, return none if id didnt exist or db is not setup properly.
  /// Adding includeDeleted to indicate if the data needed for is all of the product data.
  /// The product data that has been deleted is shadowed by is_deleted attribute.
  /// For this use includeDeleted, default to false.
  static Future<Product?> getById(int id, {bool includeDeleted = false}) async {
    List<Map<String, Object?>>? temp;
    if (includeDeleted) {
      temp = await LocalDBHandler.runRawSelectQuery(
        "SELECT * FROM $tableName WHERE id=$id;",
        [],
      );
    } else {
      temp = await LocalDBHandler.runRawSelectQuery(
        "SELECT * FROM $tableName WHERE id=$id AND is_deleted=?;",
        [boolToInt(false)],
      );
    }
    if (temp == null || temp.isEmpty) return null;
    Map<String, Object?> res = temp[0];
    return Product.createFromMap(res);
  }

  /// Get Product by name, return none if id didnt exist or db is not setup properly.
  /// Adding includeDeleted to indicate if the data needed for is all of the product data.
  /// The product data that has been deleted is shadowed by is_deleted attribute.
  /// For this use includeDeleted, default to false.
  static Future<Product?> getByName(
    String name, {
    bool includeDeleted = false,
  }) async {
    List<Map<String, Object?>>? temp;
    if (includeDeleted) {
      temp = await LocalDBHandler.runRawSelectQuery(
        "SELECT * FROM $tableName WHERE name=$name;",
        [],
      );
    } else {
      temp = await LocalDBHandler.runRawSelectQuery(
        "SELECT * FROM $tableName WHERE name=$name AND is_deleted=?;",
        [boolToInt(false)],
      );
    }
    if (temp == null || temp.isEmpty) return null;
    Map<String, Object?> res = temp[0];
    return Product.createFromMap(res);
  }

  /// Get all of product, return list, can be empty.
  /// return null if db is not setup properly
  static Future<List<Product>?> getAll() async {
    List<Map<String, Object?>>? temp = await LocalDBHandler.runRawSelectQuery(
      "SELECT * FROM $tableName WHERE is_deleted=?;",
      [boolToInt(false)],
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
    if (name.length > 255) {
      await PopUpMessage.showOkMessage(
        PopUpTitle.warning,
        "Nama Produk harus kurang dari 255 karakter.",
      );
      return null;
    }
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id FROM $tableName WHERE name = ?",
      [name],
    );
    // Show error product has same name
    if (res != null && res.isNotEmpty) return null;
    final imgPath = imgFile != null
        ? (await FileHandler.storeImage(productImgPath, imgFile))
        : null;
    int? id = await LocalDBHandler.runRawInsertQuery(
      "INSERT INTO $tableName(name, price, stock, image_path) VALUES(?, ?, ?, ?)",
      [name, price, stock, imgPath],
    );
    if (id == null) return null;
    await CommitTrack.create(Product.tableName, id, CommitType.create);
    return Product(id, name, price, stock, imgPath, null);
  }

  /// Save current Product, return int of count if success otherwise null
  Future<int?> saveToDb() async {
    return await LocalDBHandler.runRawUpdateQuery(
      "UPDATE $tableName SET name = ?, price = ?, stock = ?, image_path = ?, qr_image_path = ? WHERE id = ?;",
      [name, price, stock, imagePath, qrImagePath, id],
    );
  }

  /// Update stock produk, return int of count if success otherwise null
  /// This will automatically change this.stock, so don't change the stock value directly
  Future<int?> updateStock(int newStock) async {
    final diff = newStock - stock;
    final newId = await LocalDBHandler.runRawUpdateQuery(
      "UPDATE $tableName SET stock = ? WHERE id = ?;",
      [stock, id],
    );
    stock = newStock;
    if (newId == null) return null;
    final commitId = await CommitTrack.create(
      tableName,
      newId,
      CommitType.stockUpdate,
      data: diff.toString(),
    );
    if (commitId == null) return null;
    return newId;
  }

  /// Change product image and destroy before if exist also change current imagePath and save to the database
  Future<void> changeProductImage(XFile img) async {
    imagePath = await FileHandler.storeImage(
      productImgPath,
      img,
      oldImagePath: imagePath,
    );
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
  static Future<bool> destroyById(int id) async {
    // Track Commit
    await CommitTrack.create(Product.tableName, id, CommitType.delete);
    return await LocalDBHandler.runActionQuery(
      """UPDATE $tableName
       SET is_deleted=?
       WHERE id=?""",
      [boolToInt(true), id],
    );
  }

  /// Delete self from local database. Note this is not destroy the instance but only delete from the local database
  Future<bool> destroy() async {
    // Delete related transaction details first due to foreign key constraint
    return await LocalDBHandler.runActionQuery(
      """UPDATE $tableName
      SET name=?,is_deleted=?
      WHERE id=?""",
      ["deleted_$name", boolToInt(true), id],
    );
  }

  /// Get count of the product item
  static Future<int?> getCount() async {
    final res = await LocalDBHandler.runRawSelectQuery("""
    SELECT COUNT(*) as c FROM $tableName;
    """);
    if (res == null || res.isEmpty) return null;
    return res[0]['c'] as int;
  }

  /// The index page using 1 as the first index
  static Future<List<Product>?> getPage(int currentPage, int pageSize) async {
    final totalItem = await getCount();
    if (totalItem == null) return null;
    int maxPage = (totalItem / pageSize).ceil();
    if (maxPage < 1) maxPage = 1;
    if (currentPage < 1) currentPage = 1;
    if (currentPage > maxPage) currentPage = maxPage;
    int offset = (currentPage - 1) * pageSize;
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT * FROM $tableName LIMIT ? OFFSET ?;
    """,
      [pageSize, offset],
    );
    if (res == null) return null;
    return [for (final map in res) Product.createFromMap(map)];
  }

  static void upsert(Batch batch, Product product, String? imgPath) {
    batch.rawInsert(
      """
    INSERT INTO ${Product.tableName} (id, name, price, stock, image_path, is_deleted)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      name = excluded.name,
      price = excluded.price,
      stock = excluded.stock,
      image_path = excluded.image_path,
      is_deleted = excluded.is_deleted;
  """,
      [
        product.id,
        product.name,
        product.price,
        product.stock,
        imgPath,
        boolToInt(product.isDeleted),
      ],
    );
  }
}

class Transaction {
  static const tableName = "transactions";

  int id;
  DateTime datetime;
  List<TransactionDetail>? transactionDetails;
  late bool isDeleted;

  Transaction(this.id, this.datetime, bool? isDeleted) {
    if (isDeleted != null) {
      this.isDeleted = isDeleted;
    } else {
      this.isDeleted = false;
    }
  }

  static Transaction createFromMap(Map<String, Object?> map) {
    bool isDeleted = map.containsKey('is_deleted')
        ? (map['is_deleted'] as bool)
        : false;
    return Transaction(
      map["id"] as int,
      strToDateTime(map["datetime"] as String),
      isDeleted,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, "datetime": datetime};
  }

  Map<String, Object?> toCloudMap() {
    return {"datetime": datetime};
  }

  @override
  String toString() {
    return 'Transaction{id: $id, datetime:$datetime}';
  }

  /// Get all of the transaction Data
  static Future<List<Transaction>?> getAll() async {
    final List<Map<String, Object?>>? res =
        await LocalDBHandler.runRawSelectQuery(
          "SELECT * FROM $tableName ORDER BY DATETIME(datetime) DESC;",
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
    CommitTrack.create(Transaction.tableName, id, CommitType.create);
    return Transaction.getById(id);
  }

  /// Delete a record by given id
  static Future<bool> destroyById(int id) async {
    return await LocalDBHandler.runActionQuery(
      "DELETE FROM $tableName WHERE id=?",
      [id],
    );
  }

  /// Delete self from local database. Note this is not destroy the instance but only delete from the local database
  Future<bool> destroy() async {
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
      ORDER BY datetime(t.datetime) ASC;
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
      ORDER BY datetime(t.datetime) DESC;
      """,
          [start.toIso8601String(), end.toIso8601String()],
        );
    print("res prod:\n$res");
    return res;
  }

  /// Get count of the transaction item
  static Future<int?> getCount() async {
    final res = await LocalDBHandler.runRawSelectQuery("""
    SELECT COUNT(*) as c FROM $tableName;
    """);
    if (res == null || res.isEmpty) return null;
    return res[0]['c'] as int;
  }

  /// The index page using 1 as the first index
  static Future<List<Transaction>?> getPage(
    int currentPage,
    int pageSize,
  ) async {
    final totalItem = await getCount();
    if (totalItem == null) return null;
    int maxPage = (totalItem / pageSize).ceil();
    if (maxPage < 1) maxPage = 1;
    if (currentPage < 1) currentPage = 1;
    if (currentPage > maxPage) currentPage = maxPage;
    int offset = (currentPage - 1) * pageSize;
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT * FROM $tableName LIMIT ? OFFSET ? ORDER BY datetime(t.datetime) DESC;
    """,
      [pageSize, offset],
    );
    if (res == null) return null;
    return [for (final map in res) Transaction.createFromMap(map)];
  }

  static void upsert(Batch batch, Transaction transaction) {
    batch.rawInsert(
      """
      INSERT INTO ${Transaction.tableName} (id, datetime)
      VALUES (?, ?)
      ON CONFLICT(id) DO UPDATE SET
        datetime = excluded.datetime;
    """,
      [transaction.id, transaction.datetime.toIso8601String()],
    );
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
  static const _lastSyncKey = "lastSyncKey";

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

  /// Set Last and store it in secure storage
  static Future<void> setLastSync(DateTime datetime) async {
    await _storage.write(
      key: _lastSyncKey,
      value: datetime.toUtc().toIso8601String(),
    );
  }

  /// Get the Last Sync Time (UTC), return null if not set
  static Future<DateTime?> getLastSync() async {
    final res = await _storage.read(key: _lastSyncKey);
    if (res == null) return null;
    return DateTime.tryParse(res);
  }

  static Future<bool> login() async {
    // final pw = await getCloudSyncPw();
    // if (pw == null) return false;
    final success = await CloudHandler.cloudLogin(
      const String.fromEnvironment("SUPABASE_USER_EMAIL"),
      const String.fromEnvironment("SUPABASE_USER_KEY"),
      // // pw,
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

@pragma('vm:entry-point')
void syncCallback() {
  Workmanager().executeTask((task, inputData) async {
    print("=== BACKGROUND SYNC STARTED ===");
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await CloudHandler.cloudSetup();
      await LocalDBHandler.setup();
      print("=== BACKGROUND SYNC SUCCESS ===");

      // Pastikan SyncEngine.doSync mengembalikan boolean (true jika sukses, false jika gagal)
      bool success = await SyncEngine.doSync();
    } catch (err) {
      print("=== BACKGROUND SYNC FAILED ===");
      print("Dispatch Sync error: $err");
    }
    return true;
  });
}

enum CommitType {
  create,
  update,
  stockUpdate,
  downloadImage,
  uploadImage,
  delete,
}

class CommitTrack {
  final int id;
  final String tableName;
  final int recordId;
  final CommitType commitType;
  final DateTime createdAt;
  final String? data;
  CommitTrack(
    this.id,
    this.tableName,
    this.recordId,
    this.commitType,
    this.createdAt,
    this.data,
  );
  static CommitTrack createFromMap(Map<String, Object?> map) {
    return CommitTrack(
      map['id'] as int,
      map['table_name'] as String,
      map['record_id'] as int,
      CommitType.values[map['type'] as int],
      DateTime.parse(map['created_at'] as String),
      map['data'] as String?,
    );
  }

  static Future<int?> create(
    String tableName,
    int recordId,
    CommitType type, {
    String? data,
  }) async {
    return LocalDBHandler.runRawInsertQuery(
      """
      INSERT INTO ${SyncEngine.tableName} (table_name, record_id, type, data)
      VALUES (?,?,?,?)
    """,
      [tableName, recordId, type.index, data],
    );
  }

  static List<CommitTrack> createFromMaps(List<Map<String, Object?>> maps) {
    return [for (final map in maps) CommitTrack.createFromMap(map)];
  }

  Future<bool> destroy({bool allRelated = false}) async {
    if (allRelated) {
      return LocalDBHandler.runActionQuery(
        """
        DELETE FROM ${SyncEngine.tableName} 
        WHERE table_name=?
          AND record_id=?;
      """,
        [tableName, recordId],
      );
    } else {
      return LocalDBHandler.runActionQuery(
        """
        DELETE FROM $tableName 
        WHERE id=?;
      """,
        [id],
      );
    }
  }
}

typedef NewIdProductData = ({int newId, Product product});
typedef NewIdTransactionData = ({int newId, Transaction transaction});

class SyncEngine {
  static const tableName = "commit_tracks";
  static const taskName = "SyncTask";
  static const taskKey = "ST001";
  static const interval = Duration(minutes: 2);

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Create a reference to the file location
  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/lastSync.txt');
  }

  static Future<File> writeString(String text) async {
    final file = await _localFile;

    // Write the file (overwrites existing content by default)
    return file.writeAsString(text);
  }

  // Read the string from the file
  static Future<String> readLastSyncStr() async {
    try {
      final file = await _localFile;
      // Read the contents of the file
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      final dateStr = DateTime.parse(
        '2026-11-07 02:28:50.534194+00',
      ).toIso8601String();
      writeString(dateStr);
      return dateStr;
    }
  }

  static void setup(Batch batch) {
    batch.execute("""
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name VARCHAR(255) NOT NULL,
        record_id INTEGER NOT NULL,
        type INTEGER NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        data TEXT NULL
      );
    """);
  }

  static Future<List<Map<String, dynamic>>> needToSyncTables({
    String? lastSync,
  }) async {
    lastSync ??= await readLastSyncStr();
    try {
      final lastRes = await supabase
          .from('last_edited_tables')
          .select()
          .gt('updated_at', lastSync);
      print("Res needToSync: ${lastRes}");
      for (final {
            'id': id as int,
            'table_name': tableName as String,
            'updated_at': updatedAt as String,
          }
          in lastRes) {
        print(
          "id: $id, table_name: $tableName, updated_at: ${DateTime.parse(updatedAt)}, need_to_sync: ${DateTime.parse(lastSync).isBefore(DateTime.parse(updatedAt))}",
        );
      }
      return lastRes;
    } catch (e) {
      return [];
    }
  }

  static Future<List<CommitTrack>?> needPushTables() async {
    final res = await LocalDBHandler.runRawSelectQuery("""
      SELECT * FROM ${SyncEngine.tableName} ORDER BY table_name ASC, DATETIME(created_at) ASC; 
    """);
    if (res != null) return CommitTrack.createFromMaps(res);
    return null;
  }

  /// START
  /// 1. Inspect all the updated data, which table need to updated
  /// 2. Pull all data neede for check especially its updated_at
  /// 3. Check if there is conflicts
  ///   3.1 True: Resolve first
  ///     a. write on deleted => drop the update, then update local db (bulk)
  ///     b. decrease on zero => drop the update, change nothing, sync stock with the pull (cloud) data
  ///   3.2 False: Pass
  /// 4. Create query for update (bulk)
  /// 5. Push query to the cloud
  /// End
  static Future<bool> doSync() async {
    /// Return bool to indicate for workmanager need to retry or not
    final Batch? batch = LocalDBHandler.getBatch();
    if (batch == null) return false;
    if (CloudHandler.isLogged) {
      if (!await ManageUtils.login()) {
        // Failed to login
        return true; // try again next
      }
    }
    final serverDateTime = await _getServerTimestamp();
    if (serverDateTime == null) {
      print("Error on getting server timestamp");
      return false;
    }
    String syncDatetimeStr = serverDateTime.toIso8601String();
    // CloudTableChanged?
    bool isCloudProductChange = false;
    bool isCloudTransactionChange = false;
    // Push?
    final pushTables = await needPushTables();
    // push data
    Iterable<CommitTrack>? transactionCommits;
    Iterable<CommitTrack>? productCommits;
    print("push table: $pushTables");
    if (pushTables != null && pushTables.isNotEmpty) {
      final tableNames = [Product.tableName, Transaction.tableName];
      // find the first table name
      final dividerIdx = pushTables.indexWhere(
        (commitTrack) => commitTrack.tableName == tableNames.first,
      );
      print("Pushing divider: ${dividerIdx}, len: ${pushTables.length} ");
      if (dividerIdx != -1) {
        // Meaning there is product commit
        productCommits = pushTables.take(dividerIdx + 1);
        // Filter newlyAddedProduct
        final Iterable<CommitTrack> newlyAddedProducts = productCommits.where(
          (e) => e.commitType == CommitType.create,
        );
        // Newly Added Id
        final newlyAddedProductIds = newlyAddedProducts
            .map((el) => el.recordId)
            .toSet();
        // Filter non newly added commit (modified)
        productCommits = productCommits
            .where(
              (e) =>
                  e.commitType != CommitType.create &&
                  newlyAddedProductIds.contains(e.recordId),
            )
            .toList();
        print(
          "datas: Product commit$productCommits NewlyAddedProduct: $newlyAddedProducts, NewlyIds: $newlyAddedProductIds",
        );

        List<NewIdProductData> newData = [];
        for (final addProduct in newlyAddedProducts) {
          print("pushing product: ${addProduct}");
          final data = await _pushNewProduct(batch, addProduct);
          if (data != null) {
            newData.add(data);
          }
        }
        if (newData.isNotEmpty) {
          newData.sort((b, a) => a.newId.compareTo(b.newId));
          for (final data in newData) {
            await _updateLocalNewlyAddedProduct(
              batch,
              data.newId,
              data.product,
            );
          }
        }
        if (newlyAddedProducts.isNotEmpty) isCloudProductChange = true;
      }
      final start = pushTables.length - dividerIdx - 1;
      if (start > 0) {
        transactionCommits = pushTables.take(start);
        final Iterable<CommitTrack> newlyAddedTransaction = transactionCommits
            .where((e) => e.commitType == CommitType.create);

        final newlyAddedTransactionIds = newlyAddedTransaction
            .map((el) => el.recordId)
            .toSet();

        transactionCommits = transactionCommits
            .where(
              (e) =>
                  e.commitType != CommitType.create &&
                  newlyAddedTransactionIds.contains(e.recordId),
            )
            .toList();

        List<NewIdTransactionData> newData = [];
        for (final transData in newlyAddedTransaction) {
          final data = await _pushNewTransaction(batch, transData);
          if (data != null) {
            newData.add(data);
          }
        }
        if (newData.isNotEmpty) {
          newData.sort((b, a) => a.newId.compareTo(b.newId));
          for (final data in newData) {
            await _updateLocalNewlyAddedTransaction(
              batch,
              data.newId,
              data.transaction,
            );
          }
        }
        if (newlyAddedTransaction.isNotEmpty) isCloudTransactionChange = true;
      }
      print("End of Push New Added");
    }
    // Update time if any changed changed
    if (isCloudProductChange) _updateChangedTimeCloud(Product.tableName);
    if (isCloudTransactionChange)
      _updateChangedTimeCloud(Transaction.tableName);
    final datetime = await readLastSyncStr();
    final syncTables = await SyncEngine.needToSyncTables(lastSync: datetime);
    List<int>? modifiedProductByCloudIds;
    List<int>? modifiedTransactionByCloudIds;
    // Pull Sync
    if (syncTables.isNotEmpty) {
      // Need to pull
      print("Pulling |Sync|");
      try {
        // Map<String, Object> pulledDta = {};
        for (final map in syncTables) {
          if (map['table_name'] == Product.tableName) {
            final newProducts = await _getNewCloudProduct(datetime);
            final excludedIds = [for (final product in newProducts) product.id];
            final modifiedProducts = await _getCloudProduct(
              datetime,
              excludedIds,
            );
            final placeholders = List.filled(
              newProducts.length,
              '?',
            ).join(', ');
            // Check does there is id/name with the same name with the new product form cloud
            // Name Conflict, Strategy=>change the local to 'local_{name}'
            final namesToInclude = newProducts.map((p) => p.name).toList();
            final nameConflictIds = await LocalDBHandler.runRawSelectQuery("""
              SELECT id FROM ${Product.tableName} 
              WHERE name IN ($placeholders)
            """, namesToInclude);
            if (nameConflictIds == null) return false;
            for (final id in nameConflictIds) {
              batch.rawUpdate(
                """
                UPDATE ${Product.tableName}
                SET name = 'local_'||name
                WHERE id=?
              """,
                [id],
              );
            }
            // Then resolve conflicted ID
            // Strategy=>Upsert, insert if not exist, update if exist.
            // Drawback can alter the product data
            List<String> imgPaths = [];
            for (final product in newProducts) {
              String? imgPath;
              if (product.imagePath != null) {
                imgPath = await FileHandler.getFilePath(
                  Product.productImgPath,
                  product.imagePath!,
                );
                imgPaths.add(product.imagePath!);
              }
              Product.upsert(batch, product, imgPath);
            }
            // Download asset if not exist
            for (final imgName in imgPaths) {
              if (!(await FileHandler.fileExist(
                Product.productImgPath,
                imgName,
              ))) {
                // Download
              }
            }
            modifiedProductByCloudIds = [];
            // Save modified cloud data
            for (final modifiedProduct in modifiedProducts) {
              await modifiedProduct.saveToDb();
              modifiedProductByCloudIds.add(modifiedProduct.id);
            }
            // // Then resolve conflicted ID
            // // Strategy=>move to the last
            // // Better strategy but complex implementation. Alter ID meaning alter its foreign key
          }
          if (map['table_name'] == Transaction.tableName) {
            final newTransactions = await _getNewCloudTransaction(datetime);
            final excludedIds = [
              for (final product in newTransactions) product.id,
            ];
            final modifiedTransaction = await _getCloudTransaction(
              datetime,
              excludedIds,
            );
            // For transaction the only problem is conflicted ID
            // Resolve with Upsert strategy
            final List<int> addedIds = [];
            for (final transaction in newTransactions) {
              if (transaction.isDeleted) continue;
              addedIds.add(transaction.id);
              Transaction.upsert(batch, transaction);
            }
            // Then we also need to insert any transaction detail of its related transaction
            final tdData = await _getNewCloudTransactionDetails(addedIds);
            await _saveCloudTransactionDetails(batch, tdData);
            modifiedTransactionByCloudIds = [];
            // Applay Modification
            for (final transaction in modifiedTransaction) {
              if (transaction.isDeleted) {
                if (!await transaction.destroy()) {
                  print("Error in pull delete local transaction from cloud");
                }
              } else {
                // Should not be come to here
                print("saved pulled transaction");
                await transaction.saveToDB();
              }
              modifiedTransactionByCloudIds.add(transaction.id);
            }
          }
        }
        print("Pull Sync success");
      } catch (err) {
        print('error in sync: $err');
        return false;
      }
    }
    print("Start Push |Sync|");
    // Push Diff CHANGE
    // CloudTableChanged?
    isCloudProductChange = false;
    isCloudTransactionChange = false;
    try {
      if (productCommits != null) {
        // Before pull diff, filter from modified from cloud
        // Deletion must be run
        if (modifiedProductByCloudIds != null) {
          productCommits = productCommits.where(
            (e) =>
                modifiedProductByCloudIds!.contains(e.recordId) &&
                e.commitType != CommitType.delete,
          );
        }
        await _processProductDiff(batch, productCommits);
        isCloudProductChange = true;
      }
      // Push Diff must be used after pull CHANGE
      if (transactionCommits != null) {
        // Before pull diff, filter from modified from cloud
        // Deletion must be run
        if (modifiedTransactionByCloudIds != null) {
          transactionCommits = transactionCommits.where(
            (e) =>
                modifiedTransactionByCloudIds!.contains(e.recordId) &&
                e.commitType != CommitType.delete,
          );
        }
        await _processTransactionDiff(batch, transactionCommits);
        isCloudTransactionChange = true;
      }
    } catch (err) {
      print("Error on push diff");
      return false;
    }
    print("END Push |Sync|");
    // Update time if any changed changed
    if (isCloudProductChange) _updateChangedTimeCloud(Product.tableName);
    if (isCloudTransactionChange)
      _updateChangedTimeCloud(Transaction.tableName);
    writeString(syncDatetimeStr);
    await batch.commit(noResult: true);
    return true;
  }

  static Future<bool> _updateChangedTimeCloud(String tableName) async {
    try {
      await supabase
          .from("last_edited_tables")
          .update({})
          .eq("table_name", tableName);
      return true;
    } catch (err) {
      print("Error on updating last updated table");
      return false;
    }
  }

  static Future<DateTime?> _getServerTimestamp() async {
    try {
      // Memanggil fungsi RPC yang sudah dibuat di database
      final response = await supabase.rpc('get_server_time');

      // Response dari rpc akan berupa String (ISO 8601), ubah ke DateTime
      if (response != null) {
        return DateTime.parse(response.toString());
      }
    } catch (e) {
      print('Gagal mengambil waktu server: $e');
    }
    return null;
  }

  /// Get the product data that are updated or newly created in cloud
  static Future<List<Product>> _getNewCloudProduct(String datetime) async {
    final res = await supabase
        .from(Product.tableName)
        .select('id, name, price, stock, image_name, is_deleted')
        .gt('created_at', datetime);
    for (final map in res) {
      map['image_path'] = map['image_name'];
      map['is_deleted'] = (map['is_deleted'] as bool) ? 1 : 0;
      if (map['price'] is int) {
        map['price'] = map['price'].toDouble();
      }
    }
    print("Product: $res");
    return [for (final map in res) Product.createFromMap(map)];
  }

  /// Get the product data that are updated or newly created in cloud
  static Future<List<Product>> _getCloudProduct(
    String datetime,
    List<int> excludedId,
  ) async {
    final res = await supabase
        .from(Product.tableName)
        .select('id, name, price, stock, image_name, is_deleted, updated_at')
        .gt('updated_at', datetime)
        .not('id', 'in', excludedId);
    for (final map in res) {
      map['image_path'] = map['image_name'];
    }
    print("Transaction: $res");
    return [for (final map in res) Product.createFromMap(map)];
  }

  /// Get the transaction data that are updated or newly created in cloud
  static Future<List<Transaction>> _getCloudTransaction(
    String datetime,
    List<int> excludedId,
  ) async {
    final res = await supabase
        .from(Transaction.tableName)
        .select('id, datetime, is_deleted')
        .gt('updated_at', datetime)
        .not('id', 'in', excludedId);
    print("Transaction: $res");
    return [for (final map in res) Transaction.createFromMap(map)];
  }

  /// Get the transaction data that are updated or newly created in cloud
  static Future<List<Transaction>> _getNewCloudTransaction(
    String datetime,
  ) async {
    final res = await supabase
        .from(Transaction.tableName)
        .select('id, datetime, is_deleted')
        .gt('created_at', datetime);
    print("Transaction: $res");
    return [for (final map in res) Transaction.createFromMap(map)];
  }

  /// Get the transaction_Detail data for related transaction id that known as newly added in cloud
  static Future<List<Map<String, dynamic>>> _getNewCloudTransactionDetails(
    List<int> ids,
  ) async {
    final res = await supabase
        .from(TransactionDetail.tableName)
        .select('product_id, transaction_id, quantity')
        .inFilter('id', ids);
    print("TransactionDetails: $res");
    return res;
  }

  /// Save the cloud transaction data, this approach use insert.
  /// No transaction data will lost but the id of it will be different from the cloud.
  /// This chosen because there is no needed to keep track of the transaction detail id,
  /// as usually this table is accessed by transaction using transaction_id
  static Future<void> _saveCloudTransactionDetails(
    Batch batch,
    List<Map<String, dynamic>> data,
  ) async {
    for (final map in data) {
      batch.rawUpdate(
        """
        INSERT INTO ${TransactionDetail.tableName} (product_id, transaction_id, quantity)
        VALUES (?,?,?);
      """,
        [
          map['product_id'] as int,
          map['transaction_id'] as int,
          map['quantity'] as int,
        ],
      );
    }
  }

  static Future<NewIdTransactionData?> _pushNewTransaction(
    Batch batch,
    CommitTrack commitTrack,
  ) async {
    try {
      final transaction = await Transaction.getById(commitTrack.recordId);
      if (transaction == null) {
        return null;
      }
      final mapData = transaction.toCloudMap();
      final res = await supabase
          .from(Transaction.tableName)
          .insert(mapData)
          .select('id');
      if (res.isNotEmpty) {
        // Change id of current transaction, changing many.
        // use upsert
        final newId = res[0]['id'] as int;
        if (newId != transaction.id) {
          return (newId: newId, transaction: transaction);
        }
        // Push all of the transaction details
        final tDetails = await transaction.getAllTransactionDetails();
        if (tDetails == null) {
          print("Cant get transaction detail in attemp to push data");
        } else {
          await supabase.from(TransactionDetail.tableName).insert([
            for (final td in tDetails) td.toMap(),
          ]);
        }
      } else {
        print("Cant get the inserted transaction id");
      }
      if (!await commitTrack.destroy(allRelated: true)) {
        print("error on delete commit track");
      }
      return null;
    } catch (err) {
      print("error in _pushNewTransaction $err");
      return null;
    }
  }

  static Future<NewIdProductData?> _pushNewProduct(
    Batch batch,
    CommitTrack commitTrack,
  ) async {
    try {
      final product = await Product.getById(commitTrack.recordId);
      if (product == null) {
        return null;
      }
      final mapData = product.toCloudMap();
      final res = await supabase
          .from(Product.tableName)
          .insert(mapData)
          .select('id');
      if (res.isNotEmpty) {
        // Change id of current product, changing many.
        // use upsert
        final insertedId = res[0]['id'] as int;
        if (insertedId != product.id) {
          return (newId: insertedId, product: product);
        }
      }
      if (!await commitTrack.destroy(allRelated: true)) {
        print("error on delete commit track");
      }
      return null;
    } catch (err) {
      print("error in _pushNewProduct, err: $err");
      return null;
    }
  }

  /// Push Diff
  static Future<void> _processProductDiff(
    Batch batch,
    Iterable<CommitTrack> datas,
  ) async {
    for (final commitTrack in datas) {
      switch (commitTrack.commitType) {
        case CommitType.create:
          continue;
        case CommitType.delete:
          break;
        case CommitType.stockUpdate:
          break;
        case CommitType.update:
          break;
      }
      final product = await Product.getById(commitTrack.recordId);
      if (product == null) {
        print("Error on pushing product with id ${commitTrack.recordId}");
        continue;
      }
      await supabase
          .from(Product.tableName)
          .update(product.toMap())
          .eq('id', product.id);
    }
  }

  /// Push Diff
  static Future<void> _processTransactionDiff(
    Batch batch,
    Iterable<CommitTrack> datas,
  ) async {
    for (final commitTrack in datas) {
      switch (commitTrack.commitType) {
        case CommitType.create:
          continue;
        case CommitType.delete:
          await supabase
              .from(Transaction.tableName)
              .update({'is_deleted': true})
              .eq('id', commitTrack.recordId);
          continue;
        case CommitType.stockUpdate:
          break;
        case CommitType.update:
          break;
      }
      final transaction = await Transaction.getById(commitTrack.recordId);
      if (transaction == null) {
        print("Error on pushing transaction with id ${commitTrack.recordId}");
        continue;
      }
      await supabase
          .from(Transaction.tableName)
          .update(transaction.toMap())
          .eq('id', transaction.id);
    }
  }

  static Future<void> test() async {
    print("Latest Datetime: ${await SyncEngine.readLastSyncStr()}");
    await doSync();
  }
}

// #endregion
