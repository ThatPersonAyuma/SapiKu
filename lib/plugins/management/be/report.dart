/// We can only calculate selledQuantity because the product quantity itself is dynamic.
/// And we dont store the quantity on that day.
class ProductReport {
  int id;
  String name;
  double price;
  int selledQuantity;
  int currentStock;

  ProductReport(
    this.id,
    this.name,
    this.price,
    this.selledQuantity,
    this.currentStock,
  );

  static ProductReport createFromMap(Map<String, Object?> map) {
    return ProductReport(
      map['id'] as int,
      map['name'] as String,
      map['price'] as double,
      map["selled_quantity"] as int,
      map["current_stock"] as int,
    );
  }

  static List<ProductReport> createFromListMap(
    List<Map<String, Object?>> data,
  ) {
    // Need to create two type of data
    return [for (final map in data) ProductReport.createFromMap(map)];
  }
}
