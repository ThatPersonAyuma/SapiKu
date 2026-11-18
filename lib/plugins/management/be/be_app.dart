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
      'scaled_1000274711.jpg',
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
      'scaled_1000274710.jpg',
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
      'scaled_1000274712.jpg',
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
    if (imgPath != null) {
      print("path: ${imgPath.split("/").last}");
      await CommitTrack.upsert(
        tableName,
        id,
        CommitType.uploadImage,
        data: imgPath.split("/").last,
      );
    }
    await CommitTrack.create(Product.tableName, id, CommitType.create);
    return Product(id, name, price, stock, imgPath, null);
  }

  /// Save current Product, return int of count if success otherwise null
  Future<int?> saveToDb({Batch? batch}) async {
    if (batch == null) {
      return await LocalDBHandler.runRawUpdateQuery(
        "UPDATE $tableName SET name = ?, price = ?, stock = ?, image_path = ?, qr_image_path = ? WHERE id = ?;",
        [name, price, stock, imagePath, qrImagePath, id],
      );
    } else {
      batch.rawUpdate(
        "UPDATE $tableName SET name = ?, price = ?, stock = ?, image_path = ?, qr_image_path = ? WHERE id = ?;",
        [name, price, stock, imagePath, qrImagePath, id],
      );
      return null;
    }
  }

  /// Update stock produk, return int of count if success otherwise null
  /// This will automatically change this.stock, so don't change the stock value directly
  /// Use saveAll to save all of new data
  Future<bool> updateStock({
    required int newStock,
    bool saveAll = false,
  }) async {
    print("Update Stock, product: $this");
    final diff = newStock - stock;
    int? res;
    if (saveAll) {
      res = await LocalDBHandler.runRawUpdateQuery(
        "UPDATE $tableName SET stock = ? WHERE id = ?;",
        [newStock, id],
      );
    } else {
      res = await LocalDBHandler.runRawUpdateQuery(
        "UPDATE $tableName SET name = ?, price = ?, stock = ?, image_path = ?, qr_image_path = ? WHERE id = ?;",
        [name, price, newStock, imagePath, qrImagePath, id],
      );
    }
    if (res == null) return false;
    final isSuccess = res == 1;
    if (!isSuccess) return false;
    stock = newStock;
    final commitId = await CommitTrack.create(
      tableName,
      id,
      CommitType.stockUpdate,
      data: diff.toString(),
    );
    if (commitId == null) return false;
    return isSuccess;
  }

  /// Change product image and destroy before if exist also change current imagePath and save to the database
  Future<void> changeProductImage(XFile img) async {
    imagePath = await FileHandler.storeImage(
      productImgPath,
      img,
      oldImagePath: imagePath,
    );
    if (imagePath != null) {
      await CommitTrack.upsert(
        tableName,
        id,
        CommitType.uploadImage,
        data: imagePath!.split("/").last,
      );
    }
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
       SET name=deleted_||name,is_deleted=?
       WHERE id=?""",
      [boolToInt(true), id],
    );
  }

  /// Delete self from local database. Note this is not destroy the instance but only delete from the local database
  Future<bool> destroy() async {
    // Delete related transaction details first due to foreign key constraint
    print("Destroyed Product");
    // return false;
    final res = await CommitTrack.create(
      Product.tableName,
      id,
      CommitType.delete,
    );
    if (res == null) {
      print("Error saat membuat data commit track");
    }
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
    return {'id': id, "datetime": datetime.toIso8601String()};
  }

  Map<String, Object?> toCloudMap() {
    return {"datetime": datetime.toIso8601String()};
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

  Future<int?> saveToDB({Batch? batch}) async {
    if (batch == null) {
      return await LocalDBHandler.runRawUpdateQuery(
        """
        UPDATE $tableName 
        SET datetime = ?
        WHERE id=?;
        """,
        [datetime, id],
      );
    } else {
      batch.rawUpdate(
        """
        UPDATE $tableName 
        SET datetime = ?
        WHERE id=?;
        """,
        [datetime, id],
      );
      return null;
    }
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
        p.updateStock(newStock: p.stock - detail.quantity);
        // This should be batch in the end consider to change into sql update string rather than execute one to avoid changing while there would be an error
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
    await CommitTrack.create(Transaction.tableName, id, CommitType.delete);
    return await LocalDBHandler.runActionQuery(
      "DELETE FROM $tableName WHERE id=?",
      [id],
    );
  }

  /// Delete self from local database. Note this is not destroy the instance but only delete from the local database
  Future<bool> destroy() async {
    await CommitTrack.create(Transaction.tableName, id, CommitType.delete);
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
    final success = await CloudHandler.cloudLogin(
      const String.fromEnvironment("SUPABASE_USER_EMAIL"),
      pw,
      // const String.fromEnvironment("SUPABASE_USER_KEY"),
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

  static Future<bool> saveTransactionReport(
    DateTime start,
    DateTime end, {
    List<TransactionRecord>? reportData,
  }) async {
    final filePath =
        'Laporan_Penjualan_${start.toIso8601String()}-${end.toIso8601String()}.xlsx';
    final Workbook wb = Workbook();
    final Worksheet sheet = wb.worksheets[0];
    await _createTransReportExcel(start, end, sheet, reportData);
    FileHandler.saveFileWithPicker(
      bytes: wb.saveAsStream(),
      fileName: filePath,
    );
    wb.dispose();
    return true;
  }

  static Future<bool> saveProductReport(
    DateTime start,
    DateTime end, {
    List<ProductReport>? reportData,
  }) async {
    final filePath =
        'Laporan_Pencatatan_${start.toIso8601String()}-${end.toIso8601String()}.xlsx';
    final Workbook wb = Workbook();
    final Worksheet sheet = wb.worksheets[0];
    await _createProductReportExcel(start, end, sheet, reportData);
    FileHandler.saveFileWithPicker(
      bytes: wb.saveAsStream(),
      fileName: filePath,
    );
    wb.dispose();
    return true;
  }

  static Future<void> pushImageFile(int productId) async {}

  // static Future<void>
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
  transactionDetailsPush,
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
      INSERT INTO ${SyncEngine._commitTableName} (table_name, record_id, type, data)
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
      return await LocalDBHandler.runActionQuery(
        """
        DELETE FROM ${SyncEngine._commitTableName} 
        WHERE table_name=?
          AND record_id=?
          AND type!=?;
      """,
        [tableName, recordId, CommitType.uploadImage.index],
      );
    } else {
      return await LocalDBHandler.runActionQuery(
        """
        DELETE FROM ${SyncEngine._commitTableName} 
        WHERE id=?;
      """,
        [id],
      );
    }
  }

  /// Insert operation that check first if the data exist
  /// If exist update otherwise insert
  static Future<int?> upsert(
    String tableName,
    int recordId,
    CommitType type, {
    String? data,
  }) async {
    final idData = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT id FROM ${SyncEngine._commitTableName}
      WHERE table_name=? AND record_id=? AND type=?;
    """,
      [tableName, recordId, type.index],
    );
    if (idData == null) {
      print("Gagal mengambil data commit track pada upsert commit track");
      return null;
    }
    if (idData.isNotEmpty) {
      /// Meaning there is record that match the specific data, do update.
      /// Update the data column
      final id = idData[0]['id'] as int;
      return await LocalDBHandler.runRawUpdateQuery(
        """
        UPDATE ${SyncEngine._commitTableName} 
        SET data=?
        WHERE id=?;
      """,
        [data, id],
      );
    } else {
      // No such data, do insert
      return CommitTrack.create(tableName, recordId, type, data: data);
    }
  }

  @override
  String toString() {
    return 'CommitTrack{id: $id, tableName: $tableName, record_id: $recordId,  type: $commitType,  data: $data}';
  }
}

class CommitStockUpdated {
  int recordId;
  int quantity;
  CommitStockUpdated(this.recordId, this.quantity);
  static CommitStockUpdated createFromMap(Map<String, Object?> map) {
    return CommitStockUpdated(map['record_id'] as int, map['quantity'] as int);
  }

  static List<CommitStockUpdated> createFromMaps(
    List<Map<String, Object?>> maps,
  ) {
    return [for (final map in maps) CommitStockUpdated.createFromMap(map)];
  }

  Future<bool> destroy() async {
    try {
      await LocalDBHandler.runActionQuery(
        """
        DELETE FROM ${SyncEngine._commitTableName} 
        WHERE table_name=? AND record_id=?;
      """,
        [Product.tableName, recordId],
      );
      return true;
    } catch (err) {
      print("Error on destroying CommitStockUpdate\n$err");
      return false;
    }
  }

  @override
  String toString() {
    return 'CommitStockUpdated{record_id: $recordId, quantity: $quantity}';
  }
}

typedef NewIdProductData = ({int newId, Product product});
typedef NewIdTransactionData = ({int newId, Transaction transaction});

class SyncEngine {
  static const _commitTableName = "commit_tracks";
  static const _lastSyncsTableName = "last_syncs";
  static const taskNameSync = "SyncTask";
  static const taskKeySync = "ST-001";
  static const _taskNamePull = "SyncTaskPull";
  static const interval = Duration(minutes: 15);
  static bool isSyncing = false;

  static void setup(Batch batch) {
    batch.execute("""
      CREATE TABLE IF NOT EXISTS $_commitTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name VARCHAR(255) NOT NULL,
        record_id INTEGER NOT NULL,
        type INTEGER NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        data TEXT NULL
      );
    """);
    batch.execute("""
      CREATE TABLE IF NOT EXISTS $_lastSyncsTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(255) NOT NULL,
        data TEXT NULL
      );
    """);
  }

  static Future<DateTime?> _getLastPullProduct() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
    SELECT time FROM $_lastSyncsTableName 
    WHERE name=?;
    """,
      [_taskNamePull + Product.tableName],
    );
    if (res == null) return null;
    if (res.isEmpty) {
      final date = DateTime.parse('2026-11-07 02:28:50.534194+00');
      await _setLastPullProduct(date);
      return date;
    } else {
      return DateTime.parse(res[0]['time'] as String);
    }
  }

  static Future<int?> _setLastPullProduct(DateTime time) async {
    final updatedId = await LocalDBHandler.runRawUpdateQuery(
      """
    UPDATE $_lastSyncsTableName 
    SET time=?
    WHERE name=?;
    """,
      [time.toUtc().toIso8601String(), _taskNamePull + Product.tableName],
    );
    return updatedId;
  }

  static Future<DateTime?> _getLastPullTransaction() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
    SELECT time FROM $_lastSyncsTableName 
    WHERE name=?;
    """,
      [_taskNamePull + Transaction.tableName],
    );
    if (res == null) return null;
    if (res.isEmpty) {
      final date = DateTime.parse('2026-11-07 02:28:50.534194+00');
      await _setLastPullTransaction(date);
      return date;
    } else {
      return DateTime.parse(res[0]['time'] as String);
    }
  }

  static Future<int?> _setLastPullTransaction(DateTime time) async {
    final updatedId = await LocalDBHandler.runRawUpdateQuery(
      """
    UPDATE $_lastSyncsTableName 
    SET time=?
    WHERE name=?;
    """,
      [time.toUtc().toIso8601String(), _taskNamePull + Transaction.tableName],
    );
    return updatedId;
  }

  static Future<List<Map<String, dynamic>>> _needToSyncProduct({
    required String lastSync,
  }) async {
    try {
      final lastRes = await supabase
          .from('last_edited_tables')
          .select()
          .eq('table_name', Product.tableName)
          .gt('updated_at', lastSync)
          .order('table_name', ascending: true);
      print("Res needToSync Product: $lastRes");

      return lastRes;
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _needToSynTransaction({
    required String lastSync,
  }) async {
    try {
      final lastRes = await supabase
          .from('last_edited_tables')
          .select()
          .eq('table_name', Transaction.tableName)
          .gt('updated_at', lastSync)
          .order('table_name', ascending: true);
      print("Res needToSync Transaction: $lastRes");
      // for (final {
      //       'id': id as int,
      //       'table_name': tableName as String,
      //       'updated_at': updatedAt as String,
      //     }
      //     in lastRes) {
      //   print(
      //     "id: $id, table_name: $tableName, updated_at: ${DateTime.parse(updatedAt)}, need_to_sync: ${DateTime.parse(lastSync).isBefore(DateTime.parse(updatedAt))}",
      //   );
      // }
      return lastRes;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> _isNeedPushTables() async {
    final res = await LocalDBHandler.runRawSelectQuery("""
      SELECT 1 FROM ${SyncEngine._commitTableName} LIMIT 1;
    """);

    return res != null && res.isNotEmpty;
  }

  static Future<List<CommitTrack>?> _getNewlyAddedProduct() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT * FROM ${SyncEngine._commitTableName}
      WHERE table_name=? AND type=?
      ORDER BY table_name ASC, DATETIME(created_at) ASC; 
    """,
      [Product.tableName, CommitType.create.index],
    );
    if (res != null) return CommitTrack.createFromMaps(res);
    return null;
  }

  static Future<List<CommitTrack>?> _getNewlyAddedTransaction() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT * FROM ${SyncEngine._commitTableName}
      WHERE table_name=? AND type=?
      ORDER BY table_name ASC, DATETIME(created_at) ASC; 
    """,
      [Transaction.tableName, CommitType.create.index],
    );
    if (res != null) return CommitTrack.createFromMaps(res);
    return null;
  }

  static Future<List<CommitStockUpdated>?> _getProductUpdateStock() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT 
        record_id, 
        SUM(CAST(data as INTEGER)) as quantity FROM ${SyncEngine._commitTableName}
      WHERE table_name=? AND type=?
      GROUP BY record_id
      ORDER BY table_name ASC, DATETIME(created_at) ASC; 
    """,
      [Product.tableName, CommitType.stockUpdate.index],
    );
    if (res != null) return CommitStockUpdated.createFromMaps(res);
    return null;
  }

  /// CommitTrack that excluded of create and stockUpdate.
  /// Use after push newly added, because this method query only check
  /// if type IS NOT stockUpdate
  static Future<List<CommitTrack>?> _getProductCommitWorks() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT * FROM ${SyncEngine._commitTableName}
      WHERE table_name=? AND type!=?
      GROUP BY record_id
      ORDER BY table_name ASC, DATETIME(created_at) ASC; 
    """,
      [Product.tableName, CommitType.stockUpdate.index],
    );
    if (res != null) return CommitTrack.createFromMaps(res);
    return null;
  }

  /// CommitTrack that excluded of create and stockUpdate.
  /// Use after push newly added, because this method query only check
  /// if type IS NOT stockUpdate
  static Future<List<CommitTrack>?> _getTransactionCommitWorks() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT *FROM ${SyncEngine._commitTableName}
      WHERE table_name=? AND type!=?
      ORDER BY DATETIME(created_at) ASC; 
    """,
      [Transaction.tableName, CommitType.stockUpdate.index],
    );
    if (res != null) return CommitTrack.createFromMaps(res);
    return null;
  }

  static Future<void> _handleUpdateStock(
    List<CommitStockUpdated> updatedStock,
  ) async {
    // Push quantity commit
    for (final commit in updatedStock) {
      try {
        await supabase.rpc(
          'increment_product_stock',
          params: {
            'p_product_id': commit.recordId,
            'p_quantity': commit.quantity,
          },
        );
        await commit.destroy();
      } catch (err) {
        print("Error on update stock");
      }
    }
  }

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
    print("Products: ${await Product.getAll()}");
    if (CloudHandler.isLogged) {
      if (!await ManageUtils.login()) {
        // Failed to login
        return true; // try again next
      }
    }

    // CloudTableChanged?
    // Push new Product/Transaction?
    final needToPush = await _isNeedPushTables();
    if (needToPush) {
      // Batch commit
      final Batch? batch = LocalDBHandler.getBatch();
      if (batch == null) return false;
      // Push Newly Created
      final List<CommitTrack>? newlyAddedProducts =
          await _getNewlyAddedProduct();
      if (newlyAddedProducts == null) {
        print("Null on newly added product");
      }
      if (newlyAddedProducts != null && newlyAddedProducts.isNotEmpty) {
        // Meaning there is product commit
        List<NewIdProductData> newData = [];
        for (final addProduct in newlyAddedProducts) {
          print("pushing product: ${addProduct}");
          final data = await _pushNewProduct(batch, addProduct);
          if (data != null) {
            newData.add(data);
          }
        }

        // Rearrange the local ID
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
        // if (newlyAddedProducts.isNotEmpty) isCloudProductChange = true;
      }
      final List<CommitTrack>? newlyAddedTransaction =
          await _getNewlyAddedTransaction();
      if (newlyAddedTransaction == null) {
        print("Error on getting newly added transaction");
      }
      if (newlyAddedTransaction != null && newlyAddedTransaction.isNotEmpty) {
        List<NewIdTransactionData> newData = [];
        for (final transData in newlyAddedTransaction) {
          // Dont forget to push for new data
          final data = await _pushNewTransaction(batch, transData);
          if (data != null) {
            newData.add(data);
          }
        }
        if (newData.isNotEmpty) {
          newData.sort((b, a) => a.newId.compareTo(b.newId));
          for (final data in newData) {
            _updateLocalNewlyAddedTransaction(
              batch,
              data.newId,
              data.transaction,
            );
          }
        }
        // if (newlyAddedTransaction.isNotEmpty) isCloudTransactionChange = true;
      }
      await batch.commit(noResult: true);
      print("End of Push New Added");
    }
    // Push update stock first, so the pull will get the accumulation
    final List<CommitStockUpdated>? updatedStock =
        await _getProductUpdateStock();
    if (updatedStock != null) {
      print("Update Stock: $updatedStock");
      if (updatedStock.isNotEmpty) {
        await _handleUpdateStock(updatedStock);
      }
    } else {
      print("Error on getting updatedStock");
    }
    // Pull Product
    final datetimeTime = await _getLastPullProduct();
    if (datetimeTime == null) {
      print("Gagal mendapatkan last pull product");
      return false;
    }
    final datetime = datetimeTime.toIso8601String();
    final syncTables = await SyncEngine._needToSyncProduct(lastSync: datetime);
    List<int>? modifiedProductByCloudIds;
    // Pull Sync
    if (syncTables.isNotEmpty) {
      // Need to pull
      print("Pulling |Sync|");
      final serverDateTime = await _getServerTimestamp();
      if (serverDateTime == null) {
        print("Error on getting server timestamp");
        return false;
      }
      String syncDatetimeStr = serverDateTime.toIso8601String();
      // Batch commit
      final Batch? batch = LocalDBHandler.getBatch();
      if (batch == null) return false;
      // try {
      // Map<String, Object> pulledDta = {};
      final newProducts = await _getNewCloudProduct(datetime, syncDatetimeStr);
      final modifiedProducts = await _getCloudProduct(
        datetime,
        syncDatetimeStr,
      );
      final placeholders = List.filled(newProducts.length, '?').join(', ');
      // Check does there is id/name with the same name with the new product form cloud
      // Name Conflict, Strategy=>change the local to 'local_{name}'
      if (newProducts.isNotEmpty) {
        final namesToInclude = newProducts.map((p) => p.name).toList();
        print("names: $namesToInclude");
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
      }
      // Then resolve conflicted ID
      // Strategy=>Upsert, insert if not exist, update if exist.
      // Drawback can alter the product data

      // Continue, download all imageThat didn't exist in local.
      // This will result in commit track download image
      // that will searching the image on Cloudinary server
      for (final product in newProducts + modifiedProducts) {
        String? imgPath = product.imagePath;
        if (imgPath != null) {
          print("Data: imgPath: $imgPath");
          // Download asset if not exist
          // Add Download Task/Commit
          if (!await FileHandler.fileExistFullPath(imgPath)) {
            print("Product didn't exist");
            CommitTrack.upsert(
              Product.tableName,
              product.id,
              CommitType.downloadImage,
              data: imgPath.split('/').last,
            );
            // We've track that image Path need to be downloaded
            // So make it null to avoid error
            imgPath = null;
          } else {
            print("Product exist");
          }
        }
        // print("new Product: $product");
        Product.upsert(batch, product, imgPath);
      }
      modifiedProductByCloudIds = [];
      // Save modified cloud data
      for (final modifiedProduct in modifiedProducts) {
        // await modifiedProduct.saveToDb(batch: batch);
        modifiedProductByCloudIds.add(modifiedProduct.id);
      }
      await batch.commit(noResult: true);
      _setLastPullProduct(serverDateTime);
    }

    // Pull Sync Transaction
    final datetimeTime2 = await _getLastPullTransaction();
    if (datetimeTime2 == null) {
      print("Gagal mendapatkan last pull transaction");
      return false;
    }
    final datetimeT = datetimeTime2.toIso8601String();
    final syncTablesT = await SyncEngine._needToSynTransaction(
      lastSync: datetimeT,
    );
    List<int>? modifiedTransactionByCloudIds;
    if (syncTablesT.isNotEmpty) {
      // Need to pull
      print("Pulling |Sync|");
      final serverDateTime = await _getServerTimestamp();
      if (serverDateTime == null) {
        print("Error on getting server timestamp");
        return false;
      }
      // Batch commit
      final Batch? batch = LocalDBHandler.getBatch();
      if (batch == null) return false;
      // try {
      // Map<String, Object> pulledDta = {};
      final newTransactions = await _getNewCloudTransaction(datetimeT);
      final excludedIds = [
        for (final transaction in newTransactions) transaction.id,
      ];
      print("Excluded id: $excludedIds");
      final modifiedTransaction = await _getCloudTransaction(
        datetimeT,
        serverDateTime.toIso8601String(),
        excludedIds,
      );
      // For transaction the only problem is conflicted ID
      // Resolve with Upsert strategy
      for (final transaction in newTransactions) {
        if (transaction.isDeleted) continue;
        Transaction.upsert(batch, transaction);
      }

      // Then we also need to insert any transaction detail of its related transaction
      final tdData = await _getNewCloudTransactionDetails(excludedIds);
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
          await transaction.saveToDB(batch: batch);
        }
        modifiedTransactionByCloudIds.add(transaction.id);
      }
      await batch.commit(noResult: true);
      _setLastPullTransaction(serverDateTime);
      print("Pull Sync Transaction success");
    }
    print("Start Push |Sync|");
    // Push Diff CHANGE
    // try {
    // Batch commit
    final Batch? batch = LocalDBHandler.getBatch();
    if (batch == null) return false;
    List<CommitTrack>? productCommitDatas = await _getProductCommitWorks();
    if (productCommitDatas == null) {
      print("Product commit tidak dapat diambil");
    }
    if (productCommitDatas != null && productCommitDatas.isNotEmpty) {
      // Before pull diff, filter from modified from cloud
      // Deletion must be run, it will be handled in processProductDiff
      // Push Diff delete and update
      // Handle downloadImage and uploadImage
      print("Product Commit datas: $productCommitDatas");
      const nonDependentCommit = [
        CommitType.downloadImage,
        CommitType.uploadImage,
      ];
      await _processProductDiff(
        batch,
        productCommitDatas,
        modifiedProductByCloudIds,
        nonDependentCommit,
      );
      // isCloudProductChange = true;
      // Handle stockUpdate
    }
    // Push Diff must be used after pull CHANGE
    List<CommitTrack>? transactionCommitDatas =
        await _getTransactionCommitWorks();
    if (transactionCommitDatas == null) {
      print("Product commit tidak dapat diambil");
      return false;
    }
    print("Commit data transaction: $transactionCommitDatas");

    if (transactionCommitDatas.isNotEmpty) {
      // Before pull diff, filter from modified from cloud
      // Deletion must be run
      Iterable<CommitTrack> transactionCommits = transactionCommitDatas;
      if (modifiedTransactionByCloudIds != null) {
        transactionCommits = transactionCommitDatas.where(
          (e) => !modifiedTransactionByCloudIds!.contains(e.recordId),
        );
      }
      print("After filtered: $transactionCommits");
      await _processTransactionDiff(batch, transactionCommits);
      // isCloudTransactionChange = true;
    }
    await batch.commit(noResult: true);
    print("END Push |Sync|");
    // }
    // catch (err) {
    //   print("Error on push diff: $err");
    //   return false;
    // }
    return true;
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
  /// Remember that imagePath from this are null or filename
  static Future<List<Product>> _getNewCloudProduct(
    String datetime,
    String serverTime,
  ) async {
    final res = await supabase
        .from(Product.tableName)
        .select('id, name, price, stock, image_name, is_deleted')
        .gt('created_at', datetime)
        .lte('created_at', serverTime);
    for (final map in res) {
      final imgName = map['image_name'] as String?;
      map['image_path'] = (imgName != null)
          ? await FileHandler.getFilePath(Product.productImgPath, imgName)
          : null;
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
    String serverTime,
    // List<int> excludedId,
  ) async {
    final res = await supabase
        .from(Product.tableName)
        .select('id, name, price, stock, image_name, is_deleted, updated_at')
        .gt('updated_at', datetime)
        .lte('updated_at', serverTime)
        .lte('created_at', datetime);
    for (final map in res) {
      map['is_deleted'] = (map['is_deleted'] as bool) ? 1 : 0;
      map['image_path'] = map['image_name'];
      if (map['price'] is int) {
        map['price'] = map['price'].toDouble();
      }
    }
    print("Prodyct get cloud data: $res");
    return [for (final map in res) Product.createFromMap(map)];
  }

  /// Get the transaction data that are updated or newly created in cloud
  static Future<List<Transaction>> _getCloudTransaction(
    String datetime,
    String serverTime,
    List<int> excludedId,
  ) async {
    final res = await supabase
        .from(Transaction.tableName)
        .select('id, datetime, is_deleted')
        .gt('updated_at', datetime)
        .lte('updated_at', serverTime)
        .not('id', 'in', excludedId);
    print("Updated Transaction: $res");
    return [for (final map in res) Transaction.createFromMap(map)];
  }

  /// Get the transaction data that are updated or newly created in cloud
  static Future<List<Transaction>> _getNewCloudTransaction(
    String datetime,
  ) async {
    final res = await supabase
        .from(Transaction.tableName)
        .select('id, datetime, is_deleted')
        .gt('created_at', datetime)
        .eq('is_deleted', false);
    print("New Transaction: $res");
    return [for (final map in res) Transaction.createFromMap(map)];
  }

  /// Get the transaction_Detail data for related transaction id that known as newly added in cloud
  static Future<List<Map<String, dynamic>>> _getNewCloudTransactionDetails(
    List<int> ids,
  ) async {
    final res = await supabase
        .from(TransactionDetail.tableName)
        .select('product_id, transaction_id, quantity')
        .inFilter('transaction_id', ids);
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
      NewIdTransactionData? returnData;
      if (res.isNotEmpty) {
        // Change id of current transaction, changing many.
        // use upsert
        final newId = res[0]['id'] as int;

        if (newId != transaction.id) {
          returnData = (newId: newId, transaction: transaction);
          print("Success pushing");
        }
        if (!await commitTrack.destroy(allRelated: true)) {
          print("error on delete commit track");
        } else {
          // Need to push new transaction
          await CommitTrack.create(
            Transaction.tableName,
            newId,
            CommitType.transactionDetailsPush,
          );
        }
      } else {
        print("Cant get the inserted transaction id");
      }
      return returnData;
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
          .select('id, name');
      NewIdProductData? returnData;
      if (res.isNotEmpty) {
        // Change id of current product, changing many.
        // use upsert
        final name = res[0]['name'] as String;
        if (name != product.name) {
          batch.rawUpdate(
            """
            UPDATE ${Product.tableName}
            SET name = ?
            WHERE id=?;
          """,
            [name, product.id],
          );
        }
        final insertedId = res[0]['id'] as int;
        if (insertedId != product.id) {
          returnData = (newId: insertedId, product: product);
        }
        if (!await commitTrack.destroy(allRelated: true)) {
          print("error on delete commit track");
        }
      } else {
        print("Can't get cloud inserted ID");
      }
      return returnData;
    } catch (err) {
      print("error in _pushNewProduct, err: $err");
      return null;
    }
  }

  /// Update cloud newly added and change the local
  static Future<void> _updateLocalNewlyAddedProduct(
    Batch batch,
    int newId,
    Product product,
  ) async {
    product.name = "oldsync_${product.name}";
    await product.saveToDb();
    final lastId = product.id;
    product.id = newId;
    Product.upsert(batch, product, product.imagePath);
    batch.rawUpdate(
      """
      UPDATE ${TransactionDetail.tableName}
      SET product_id=?
      WHERE product_id=?;
    """,
      [product.id, lastId],
    );
    batch.rawUpdate(
      """
      UPDATE ${SyncEngine._commitTableName}
      SET record_id=?
      WHERE record_id=?;
    """,
      [lastId, product.id],
    );
  }

  /// Update cloud newly added and change the local
  static void _updateLocalNewlyAddedTransaction(
    Batch batch,
    int newId,
    Transaction transaction,
  ) {
    final lastId = transaction.id;
    transaction.id = newId;
    Transaction.upsert(batch, transaction);
    batch.rawUpdate(
      """
      UPDATE ${TransactionDetail.tableName}
      SET transaction_id=?
      WHERE transaction_id=?;
    """,
      [transaction.id, lastId],
    );

    batch.rawUpdate(
      """
      UPDATE ${SyncEngine._commitTableName}
      SET record_id=?
      WHERE record_id=?;
    """,
      [transaction.id, lastId],
    );
  }

  /// Push Diff
  static Future<void> _processProductDiff(
    Batch batch,
    List<CommitTrack> datas,
    List<int>? modifiedIds,
    List<CommitType> nonDependentCommit,
  ) async {
    for (final commitTrack in datas) {
      if (modifiedIds != null &&
          modifiedIds.contains(commitTrack.recordId) &&
          !nonDependentCommit.contains(commitTrack.commitType)) {
        if (!await commitTrack.destroy()) {
          print("Error on destroy commit track diff product");
        }
        continue;
      }
      switch (commitTrack.commitType) {
        case CommitType.create:
          continue;
        case CommitType.delete:
          break;
        case CommitType.update:
          break;
        case CommitType.downloadImage:
          // COmmit destroyed inside
          await _downloadImage(commitTrack);
          continue;
        case CommitType.uploadImage:
          await _uploadImage(commitTrack);
          continue;
        default:
          continue;
      }
      final product = await Product.getById(
        commitTrack.recordId,
        includeDeleted: true,
      );
      if (product == null) {
        print("Error on pushing product with id ${commitTrack.recordId}");
        continue;
      }
      final mapData = product.toCloudMap();
      mapData.remove(
        "stock",
      ); // Stock will be push by updateStock so we avoid thisy
      await supabase
          .from(Product.tableName)
          .update(mapData)
          .eq('id', product.id);
      if (!await commitTrack.destroy()) {
        print("Error on destroy commit track diff product");
      }
    }
  }

  /// Push Diff
  static Future<void> _processTransactionDiff(
    Batch batch,
    Iterable<CommitTrack> datas,
  ) async {
    for (final commitTrack in datas) {
      switch (commitTrack.commitType) {
        case CommitType.delete:
          await supabase
              .from(Transaction.tableName)
              .update({'is_deleted': true})
              .eq('id', commitTrack.recordId);
          break;
        case CommitType.update:
          final transaction = await Transaction.getById(commitTrack.recordId);
          if (transaction == null) {
            print(
              "Error on pushing transaction with id ${commitTrack.recordId}",
            );
            continue;
          }
          await supabase
              .from(Transaction.tableName)
              .update(transaction.toMap())
              .eq('id', transaction.id);
          break;
        case CommitType.transactionDetailsPush:
          // Push all of the transaction details
          print("pushing transaction detail data");
          final transaction = await Transaction.getById(commitTrack.recordId);
          if (transaction == null) {
            print(
              "Gagal mendapatkan data transaksi, id: ${commitTrack.recordId}",
            );
            print("Datas: ${await Transaction.getAll()}");
            continue;
          }

          final tDetails = await transaction.getAllTransactionDetails();
          if (tDetails == null || tDetails.isEmpty) {
            print(
              """Transaction Details: ${await LocalDBHandler.runRawSelectQuery("SELECT * FROM ${TransactionDetail.tableName}")}""",
            );
            print(
              "Cant get transaction detail or details are empty in attempt to push data, : $tDetails",
            );
          } else {
            try {
              // Lakukan insert ke Supabase
              final res = await supabase
                  .from(TransactionDetail.tableName)
                  .insert([for (final td in tDetails) td.toMap()]);

              // Jika sampai sini tanpa exception, berarti berhasil
              print("Success push transaction detail: $res");
              if (!await commitTrack.destroy()) {
                print("Error saat mencob menghapus");
              } else {
                print("Success on deleting");
              }
            } catch (e) {
              // Tangkap error jika terjadi kendala pada database / jaringan
              print("Error saat insert ke Supabase: $e");
            }
          }
          continue;
        default:
          continue;
      }
      if (!await commitTrack.destroy()) {
        print("Error on destroy commit track diff product");
      }
    }
  }

  static Future<void> _downloadImage(CommitTrack commit) async {
    print("commit download: $commit");
    if (commit.data == null) return;
    final downloadedPath = await CloudinaryHandler.downloadCloudImage(
      ManagementPlugin.managementName,
      commit.data!,
    );
    if (downloadedPath == null) {
      print("Error on downloading");
    } else {
      final product = await Product.getById(commit.recordId);
      if (product == null) {
        print("Failed to query product in download image, commit: $commit");
        return;
      }
      product.imagePath = downloadedPath;
      await product.saveToDb();
      if (!await commit.destroy()) {
        print("Error on destroy commit track diff product");
      }
    }
  }

  static Future<String?> _uploadImage(CommitTrack commit) async {
    print("upload image");
    final product = await Product.getById(commit.recordId);
    if (product == null) {
      print("error on getting product");
      return null;
    }
    final filePath = product.imagePath;
    if (filePath == null) {
      print("Image Path Kosong, product: $product");
      return null;
    }
    final filename = filePath.split("/").last;
    if (filename != commit.data) {
      print("Data mismatch for upload commit filename: $commit");
      return null;
    }
    final file = FileHandler.getFile(filePath);
    if (file == null) {
      print("Cant get file in downoad image");
      return null;
    }
    final res = await CloudinaryHandler.uploadIfNotExists(
      file: file,
      fileName: filename,
    );
    if (res != null) {
      // if (!await commit.destroy()) {
      //   print("Error on destroy commit track diff product");
      // }
      print("success uploaded: $res");
    } else {
      print("error uploaded: $res");
    }
    return res;
  }

  static Future<void> runSync() async {
    if (SyncEngine.isSyncing) return;
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM ${Plugin.tableName} WHERE name = ?",
      [ManagementPlugin.managementName],
    );
    if (res == null) return;
    if (res.isNotEmpty) {
      if (res[0]['is_setup'] != 1) return;
    } else {
      return;
    }
    SyncEngine.isSyncing = true;
    await doSync();
    SyncEngine.isSyncing = false;
  }

  static Future<void> test() async {
    await runSync();
  }
}

// #endregion
