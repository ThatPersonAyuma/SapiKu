// #region DB Table Class Bridge
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart' show Gal;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:sapiku/plugins/management/be/db_class/commit.dart'
    show CommitTrack, CommitType;
import 'package:sapiku/plugins/management/utils/qr.dart';
import 'package:sapiku/utils/db/local_handler.dart' show LocalDBHandler;
import 'package:sapiku/utils/file_handler.dart' show FileHandler;
import 'package:sapiku/utils/utils.dart'
    show boolToInt, PopUpMessage, PopUpTitle;
import 'package:sqflite/sqflite.dart' show Batch;

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

// #endregion
