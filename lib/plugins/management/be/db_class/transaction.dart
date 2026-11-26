import 'package:sapiku/plugins/management/be/db_class/commit.dart' show CommitTrack, CommitType;
import 'package:sapiku/plugins/management/be/db_class/product.dart' show Product;
import 'package:sapiku/plugins/management/be/db_class/transaction_detail.dart' show TransactionDetail, TransactionDetailInsertComponent;
import 'package:sapiku/utils/db/local_handler.dart' show LocalDBHandler;
import 'package:sapiku/utils/utils.dart' show strToDateTime;
import 'package:sqflite/sqflite.dart' show Batch;

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
        td.product_id AS product_id,
        t.datetime AS datetime, 
        td.quantity AS quantity
      FROM $tableName t
      INNER JOIN ${TransactionDetail.tableName} td
        ON t.id = td.transaction_id
      WHERE datetime(t.datetime) >= datetime(?) 
        AND datetime(t.datetime) <= datetime(?)
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
        c.id AS id,
        c.name AS name, 
        c.price AS price,
        SUM(td.quantity) AS selled_quantity,
        c.stock AS current_stock
      FROM ${Product.tableName} c
      INNER JOIN ${TransactionDetail.tableName} td
        ON c.id = td.product_id
      INNER JOIN ${Transaction.tableName} t
        ON t.id = td.transaction_id
      WHERE datetime(t.datetime) >= datetime(?) 
        AND datetime(t.datetime) <= datetime(?)
      GROUP BY c.id
      ORDER BY c.id;
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
class TransactionRecord {
  int id;
  int productId;
  DateTime date;
  int quantity;

  TransactionRecord(this.id, this.productId, this.date, this.quantity);

  static TransactionRecord createFromMap(Map<String, Object?> map) {
    return TransactionRecord(
      map['id'] as int,
      map['product_id'] as int,
      strToDateTime((map["datetime"] as String)),
      map["quantity"] as int,
    );
  }

  static List<TransactionRecord> createFromListMap(
    List<Map<String, Object?>> data,
  ) {
    // Need to create two type of data
    return [for (final map in data) TransactionRecord.createFromMap(map)];
  }
}
