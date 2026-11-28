import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sapiku/plugins/management/be/db_class/product.dart';
import 'package:sapiku/plugins/management/be/db_class/transaction.dart';
import 'package:sapiku/plugins/management/be/db_class/transaction_detail.dart'
    show TransactionDetail;
import 'package:sapiku/plugins/management/be/plugin.dart';
import 'package:sapiku/plugins/management/be/db_class/commit.dart';
import 'package:sapiku/plugins/management/fe/pages/notifier.dart';
import 'package:sapiku/utils/cloudinary_handler.dart';
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sqflite/sqflite.dart' show Batch;
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void syncCallback() {
  Workmanager().executeTask((task, inputData) async {
    return await doSyncWork();
  });
}

Future<bool> doSyncWork() async {
  print("=== BACKGROUND SYNC STARTED ===");
  final currentSyncSeq = TopSyncNotifier.showSyncing(
    title: 'Menyinkronkan data...',
    message: 'Memproses antrean perubahan lokal',
  );
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await CloudHandler.cloudSetup();
    await LocalDBHandler.setup();

    // Pastikan SyncEngine.doSync mengembalikan boolean (true jika sukses, false jika gagal)
    bool synced = await SyncEngine.runSync();
    if (!synced) {
      // 2a. Selesai dengan gagal -> ganti notifier & mulai timer dismiss baru
      TopSyncNotifier.completeSync(
        isSuccess: false,
        title: 'Sinkronisasi Gagal',
        message: 'Koneksi terputus atau konflik data. Ketuk untuk coba lagi.',
        duration: const Duration(seconds: 5),
        syncSequence: currentSyncSeq,
      );
      return true;
    }

    // 2b. Selesai dengan sukses -> ganti notifier & mulai timer dismiss baru
    TopSyncNotifier.completeSync(
      isSuccess: true,
      title: 'Sinkronisasi Berhasil',
      message: 'Semua data sudah selaras dengan server.',
      duration: const Duration(seconds: 3),
      syncSequence: currentSyncSeq,
    );
    print("=== BACKGROUND SYNC SUCCESS ===");
  } catch (err) {
    TopSyncNotifier.completeSync(
      isSuccess: false,
      title: 'Terjadi Kesalahan',
      message: err.toString(),
      duration: const Duration(seconds: 5),
      syncSequence: currentSyncSeq,
    );
    print("=== BACKGROUND SYNC FAILED ===");
    print("Dispatch Sync error: $err");
  }
  return true;
}

typedef NewIdProductData = ({int newId, Product product});
typedef NewIdTransactionData = ({int newId, Transaction transaction});

class SyncEngine {
  static const commitTableName = "commit_tracks";
  static const _lastSyncsTableName = "last_syncs";
  static const taskNameSync = "SyncTask";
  static const taskKeySync = "ST-001";
  static const _taskNamePull = "SyncTaskPull";
  static const interval = Duration(minutes: 15);
  static bool isSyncing = false;

  static const _cloudPwKey = "cloudPwKey";
  static const _cloudVerifiedKey = "cloudPwVerifiedKey";

  /// Menandai bahwa password cloud sudah diverifikasi. Disimpan permanen agar
  /// dialog sinkronisasi tidak meminta password lagi setelah aplikasi dibuka ulang.
  static bool _cloudSyncVerified = false;
  static Future<bool> isCloudSyncVerified() async {
    if (_cloudSyncVerified) return true;
    final value = await _storage.read(key: _cloudVerifiedKey);
    _cloudSyncVerified = value == '1';
    return _cloudSyncVerified;
  }

  static Future<void> markCloudSyncVerified() async {
    _cloudSyncVerified = true;
    await _storage.write(key: _cloudVerifiedKey, value: '1');
  }

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

  static void setup(Batch batch) {
    batch.execute("""
      CREATE TABLE IF NOT EXISTS $commitTableName (
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
        time DATETIME NULL DEFAULT CURRENT_TIMESTAMP, 
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
      return lastRes;
    } catch (e) {
      return [];
    }
  }

  /// Check if there is local data waiting to be synchronized to the cloud.
  /// Image transfer commits are ignored because product/transaction data can
  /// already be synchronized even when an image upload/download is still pending.
  static Future<bool> hasPendingChanges() async {
    const pendingTypes = [
      CommitType.create,
      CommitType.update,
      CommitType.stockUpdate,
      CommitType.delete,
      CommitType.transactionDetailsPush,
    ];
    final placeholders = List.filled(pendingTypes.length, '?').join(', ');
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT 1 FROM ${SyncEngine.commitTableName}
      WHERE type IN ($placeholders)
      LIMIT 1;
    """,
      [for (final type in pendingTypes) type.index],
    );

    return res != null && res.isNotEmpty;
  }

  static Future<bool> _isNeedPushTables() => hasPendingChanges();

  static Future<List<CommitTrack>?> _getNewlyAddedProduct() async {
    final res = await LocalDBHandler.runRawSelectQuery(
      """
      SELECT * FROM ${SyncEngine.commitTableName}
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
      SELECT * FROM ${SyncEngine.commitTableName}
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
        SUM(CAST(data as INTEGER)) as quantity FROM ${SyncEngine.commitTableName}
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
      SELECT * FROM ${SyncEngine.commitTableName}
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
      SELECT *FROM ${SyncEngine.commitTableName}
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
    if (!CloudHandler.isLogged) {
      if (!await login()) {
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
        // The local update can be overwritten by cloud update
        transactionCommits = transactionCommitDatas.where((e) {
          final isNotIn = !modifiedTransactionByCloudIds!.contains(e.recordId);
          if (!isNotIn) {
            e.destroy();
          }
          return isNotIn;
        });
      }
      print(
        "After filtered: $transactionCommits, modified: $modifiedTransactionByCloudIds",
      );
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
      UPDATE ${SyncEngine.commitTableName}
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
      UPDATE ${SyncEngine.commitTableName}
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
      if (!await commit.destroy()) {
        print("Error on destroy commit track diff product");
      }
      print("success uploaded: $res");
    } else {
      print("error uploaded: $res");
    }
    return res;
  }

  static Future<bool> runSync() async {
    if (SyncEngine.isSyncing) return false;
    final res = await LocalDBHandler.runRawSelectQuery(
      "SELECT id, is_setup FROM ${Plugin.tableName} WHERE name = ?",
      [ManagementPlugin.managementName],
    );
    if (res == null) return false;
    if (res.isNotEmpty) {
      if (res[0]['is_setup'] != 1) return false;
    } else {
      return false;
    }
    SyncEngine.isSyncing = true;
    try {
      final res = await doSync();
      print("Sync Res: $res");
      return res;
    } catch (err) {
      print("Sync error: $err");
      return false;
    } finally {
      SyncEngine.isSyncing = false;
    }
  }

  static Future<void> test() async {
    await runSync();
  }
}
