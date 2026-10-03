import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';
import 'package:sapiku/utils/db/local_handler.dart';

class Product {
  static String tableName = "products";
  static String qrPhotoPath = "qr_images";
  static String productImgPath = "product_images";

  int id;
  String productName;
  double price;
  int stock;
  String? imagePath;
  String? qrImagePath;
  Product(
    this.id,
    this.productName,
    this.price,
    this.stock,
    this.imagePath,
    this.qrImagePath,
  ) {
    _ensureQrImage;
  }
  Map<String, Object?> toMap() {
    return {
      'id': id,
      "productName": productName,
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
    return 'Product{id: $id, productName:$productName price:$price stock:$stock imagePath: $imagePath qrImagePath: $qrImagePath}';
  }

  static Product createFromMap(Map<String, Object?> map) {
    return Product(
      map["id"] as int,
      map["product_name"] as String,
      map["price"] as double,
      map["stock"] as int,
      map["image_path"] as String?,
      map["qr_image_path"] as String?,
    );
  }

  Future<void> _ensureQrImage() async {
    if (qrImagePath == null) {
      final bytes = await getQrPngbyId(id);
      if (bytes != null) {
        // 2. Dapatkan direktori penyimpanan dokumen
        final directory = await getApplicationDocumentsDirectory();

        // 3. Tentukan path file yang akan disimpan
        final filePath =
            '${directory.path}/$qrPhotoPath/${DateTime.now().millisecondsSinceEpoch}.png';

        // 4. Buat file dan tulis bytes ke dalamnya
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        qrImagePath = file.path;
        saveToDb();
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
    String productName,
    double price,
    int stock,
    String? imagePath,
    String? qrImagePath,
  ) async {
    int? id = await LocalDBHandler.runRawInsertQuery(
      "INSERT INTO $tableName(product_name, price, stock, image_path, qr_image_path) VALUES(?, ?, ?, ?, ?)",
      [productName, price, stock, imagePath, qrImagePath],
    );
    if (id == null) return null;
    return Product(id, productName, price, stock, imagePath, qrImagePath);
  }

  /// Save current Product, return int of count if success otherwise null
  Future<int?> saveToDb() async {
    return await LocalDBHandler.runRawUpdateQuery(
      "UPDATE $tableName SET product_name = ?, price = ?, stock = ?, image_path = ?, qr_image_path = ? WHERE id = ?",
      [productName, price, stock, imagePath, qrImagePath, id],
    );
  }

  /// Change product image and destroy before if exist also change current imagePath and save to the database
  Future<void> changeProductImage(XFile img) async {
    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        '${directory.path}/$productImgPath/${DateTime.now().millisecondsSinceEpoch}.png';
    final bytes = await img.readAsBytes();
    final File newFile = File(filePath);
    await newFile.writeAsBytes(bytes);
    if (imagePath != null) {
      // if image before exist, destroy
      final File oldFile = File(imagePath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
    imagePath = filePath;
    saveToDb();
  }
}


class Transaction {
  
}