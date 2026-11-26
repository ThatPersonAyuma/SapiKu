import 'package:sapiku/utils/db/local_handler.dart';

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

class TransactionDetailInsertComponent {
  int productId;
  int quantity;

  TransactionDetailInsertComponent(this.productId, this.quantity);
}
