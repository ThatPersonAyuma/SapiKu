
import 'package:sapiku/plugins/management/be/db_class/product.dart' show Product;
import 'package:sapiku/plugins/management/be/plugin.dart';
import 'package:sapiku/plugins/management/be/sync.dart';
import 'package:sapiku/utils/db/local_handler.dart';

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
      INSERT INTO ${SyncEngine.commitTableName} (table_name, record_id, type, data)
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
        DELETE FROM ${SyncEngine.commitTableName} 
        WHERE table_name=?
          AND record_id=?
          AND type!=?;
      """,
        [tableName, recordId, CommitType.uploadImage.index],
      );
    } else {
      return await LocalDBHandler.runActionQuery(
        """
        DELETE FROM ${SyncEngine.commitTableName} 
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
      SELECT id FROM ${SyncEngine.commitTableName}
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
        UPDATE ${SyncEngine.commitTableName} 
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
        DELETE FROM ${SyncEngine.commitTableName} 
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

