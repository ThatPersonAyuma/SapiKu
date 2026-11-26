import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sapiku/plugins/management/be/db_class/product.dart' show Product;
import 'package:sapiku/plugins/management/be/db_class/transaction.dart' show TransactionRecord, Transaction;
import 'package:sapiku/plugins/management/be/db_class/transaction_detail.dart' show TransactionDetail;
import 'package:sapiku/plugins/management/be/plugin.dart';
import 'package:sapiku/plugins/management/be/report.dart' show ProductReport;
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/file_handler.dart';
import 'package:sapiku/utils/utils.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

/// Class to access utils method for management feature
class Report {

  static void _applyThinBorder(Range range) {
    range.cellStyle.borders.all.lineStyle = LineStyle.thin;
    range.cellStyle.borders.all.color = '#E5E7EB';
  }

  /// Format the excel for transaction detail report
  static Future<(int, int)?> _createTransReportExcel(
    DateTime start,
    DateTime end,
    Worksheet sheet,
    List<TransactionRecord>? reportData,
    Map<int, ProductReport> productData,
  ) async {
    const List<String> columnNames = [
      "ID Transaksi",
      "Tanggal",
      "Nama Produk",
      "Jumlah",
      "Harga Satuan",
      "Subtotal",
    ];
    reportData ??= await createTransReport(start, end);
    if (reportData == null) return null;

    final Range secATitle = sheet.getRangeByName('A3:F3');
    secATitle.merge();
    secATitle.setText('A. Riwayat Transaksi Penjualan');
    secATitle.cellStyle.bold = true;
    secATitle.cellStyle.fontSize = 12;
    sheet.getRangeByIndex(3, 1).rowHeight = 22;

    for (int i = 0; i < columnNames.length; i++) {
      final Range cell = sheet.getRangeByIndex(4, i + 1);
      cell.setText(columnNames[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#F3F4F6';
      cell.cellStyle.vAlign = VAlignType.center;
      cell.cellStyle.hAlign = i >= 3 ? HAlignType.right : HAlignType.left;
      cell.columnWidth = 20;
      _applyThinBorder(cell);
    }
    sheet.getRangeByIndex(4, 1).rowHeight = 24;
    int currentRow = 5;
    final startRow = currentRow;
    for (var trx in reportData) {
      sheet.getRangeByIndex(currentRow, 1).setText(trx.id.toString());
      sheet.getRangeByIndex(currentRow, 2).setDateTime(trx.date);
      String? pdName = productData[trx.id]?.name;
      pdName ??= "Product tidak Ditemukan";
      sheet.getRangeByIndex(currentRow, 3).setText(pdName);

      // Jumlah (Format angka dengan satuan "botol")
      final Range qtyCell = sheet.getRangeByIndex(currentRow, 4);
      qtyCell.setNumber((trx.quantity).toDouble());
      qtyCell.numberFormat = '0" botol"';
      qtyCell.cellStyle.hAlign = HAlignType.right;

      // Harga Satuan (Format Rupiah)
      double? pdPrice = productData[trx.id]?.price;
      pdPrice ??= 0;
      final Range priceCell = sheet.getRangeByIndex(currentRow, 5);
      priceCell.setNumber(pdPrice);
      priceCell.numberFormat = '"Rp"#,##0';
      priceCell.cellStyle.hAlign = HAlignType.right;

      // Subtotal (Rumus: Jumlah * Harga Satuan)
      final Range subCell = sheet.getRangeByIndex(currentRow, 6);
      subCell.setFormula('=D$currentRow*E$currentRow');
      subCell.numberFormat = '"Rp"#,##0';
      subCell.cellStyle.hAlign = HAlignType.right;

      // Terapkan border & tinggi baris
      for (int col = 1; col <= 6; col++) {
        final Range cell = sheet.getRangeByIndex(currentRow, col);
        cell.cellStyle.vAlign = VAlignType.center;
        _applyThinBorder(cell);
      }
      sheet.getRangeByIndex(currentRow, 1).rowHeight = 20;
      currentRow++;
    }

    return (startRow, currentRow - 1);
  }

  static void _createTotalIncome(
    Worksheet sheet,
    int currentRow,
    int startRow,
    int endRow,
  ) async {
    final Range secCTitle = sheet.getRangeByName('H$currentRow:J$currentRow');
    secCTitle.merge();
    secCTitle.setText('Total Pendapatan');
    secCTitle.cellStyle.bold = true;
    secCTitle.cellStyle.fontSize = 12;
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 22;
    currentRow++;
    final Range boxLabel = sheet.getRangeByIndex(currentRow, 8, currentRow, 10);
    boxLabel.merge();
    boxLabel.setText('Total Pendapatan Selama Periode Laporan');
    boxLabel.cellStyle.fontSize = 10;
    boxLabel.cellStyle.fontColor = '#4B5563';
    boxLabel.cellStyle.backColor = '#F9FAFB';
    boxLabel.cellStyle.vAlign = VAlignType.bottom;
    boxLabel.cellStyle.borders.top.lineStyle = LineStyle.thin;
    boxLabel.cellStyle.borders.top.color = '#D1D5DB';
    boxLabel.cellStyle.borders.left.lineStyle = LineStyle.thin;
    boxLabel.cellStyle.borders.left.color = '#D1D5DB';
    boxLabel.cellStyle.borders.right.lineStyle = LineStyle.thin;
    boxLabel.cellStyle.borders.right.color = '#D1D5DB';

    currentRow++;
    final Range boxValue = sheet.getRangeByName('H$currentRow:J$currentRow');
    boxValue.merge();
    boxValue.setFormula('=SUM(F$startRow:F$endRow)');
    boxValue.numberFormat = '"Rp"#,##0';
    boxValue.cellStyle.bold = true;
    boxValue.cellStyle.fontSize = 16;
    boxValue.cellStyle.fontColor = '#16A34A'; // Hijau
    boxValue.cellStyle.backColor = '#F9FAFB';
    boxValue.cellStyle.hAlign = HAlignType.left;
    boxValue.cellStyle.vAlign = VAlignType.center;
    boxValue.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
    boxValue.cellStyle.borders.bottom.color = '#D1D5DB';
    boxValue.cellStyle.borders.left.lineStyle = LineStyle.thin;
    boxValue.cellStyle.borders.left.color = '#D1D5DB';
    boxValue.cellStyle.borders.right.lineStyle = LineStyle.thin;
    boxValue.cellStyle.borders.right.color = '#D1D5DB';
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 28;
  }

  static Map<int, List<TransactionRecord>> _groupTransaction(
    List<TransactionRecord> data,
  ) {
    Map<int, List<TransactionRecord>> grouped = {};
    for (final tr in data) {
      final id = tr.id;

      // Buat header transaksi jika t.id belum ada di dalam Map
      grouped.putIfAbsent(id, () => [tr]);

      // Tambahkan sisa kolom ke dalam list 'data'
      (grouped[id]!).add(tr);
    }
    return grouped;
  }

  static Map<int, ProductReport> _createMapProductReport(
    List<ProductReport> data,
  ) {
    Map<int, ProductReport> grouped = {};
    for (final pr in data) {
      final id = pr.id;

      // Buat header transaksi jika t.id belum ada di dalam Map
      grouped.putIfAbsent(id, () => pr);
    }
    return grouped;
  }

  /// Format the excel sheet for product statistic reports
  static Future<int> _createProductReportExcel(
    DateTime start,
    DateTime end,
    Worksheet sheet,
    List<ProductReport> reportData,
  ) async {
    const List<String> columnNames = [
      "Nama Produk",
      "Total Terjual",
      "Stock Saat Ini",
    ];
    for (int i = 0; i < columnNames.length; i++) {
      final Range cell = sheet.getRangeByIndex(4, i + 8);
      cell.setText(columnNames[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#F3F4F6';
      cell.cellStyle.hAlign = HAlignType.left;
      cell.cellStyle.vAlign = VAlignType.center;
      cell.columnWidth = 20;
      _applyThinBorder(cell);
    }
    sheet.getRangeByIndex(4, 1).rowHeight = 24;

    int currentRow = 5;
    final int startRow = currentRow;
    for (final product in reportData) {
      final Range name = sheet.getRangeByIndex(currentRow, 8);
      name.merge();
      name.setText(product.name);
      name.cellStyle.hAlign = HAlignType.left;
      name.cellStyle.vAlign = VAlignType.center;
      name.columnWidth = 24;
      _applyThinBorder(name);

      // Stok Terjual
      final Range totalSold = sheet.getRangeByIndex(currentRow, 9);
      totalSold.setNumber(product.selledQuantity.toDouble());
      totalSold.numberFormat = '0" botol"';

      // Stok Saat Ini
      final Range masukCell = sheet.getRangeByIndex(currentRow, 10);
      masukCell.setNumber(product.currentStock.toDouble());
      masukCell.numberFormat = '0" botol"';

      for (int col = 9; col <= 10; col++) {
        final Range cell = sheet.getRangeByIndex(currentRow, col);
        cell.cellStyle.hAlign = HAlignType.right;
        cell.cellStyle.vAlign = VAlignType.center;
        _applyThinBorder(cell);
      }
      sheet.getRangeByIndex(currentRow, 1).rowHeight = 20;
      currentRow++;
    }
    final int endRowB = currentRow - 1;
    // Total
    final Range totalLabel = sheet.getRangeByIndex(currentRow, 8);
    totalLabel.merge();
    totalLabel.setText('Total');
    totalLabel.cellStyle.bold = true;
    totalLabel.cellStyle.vAlign = VAlignType.center;
    _applyThinBorder(totalLabel);
    final List<String> colLetters = ['I', 'J'];
    for (int i = 0; i < colLetters.length; i++) {
      final String col = colLetters[i];
      final Range totalCell = sheet.getRangeByIndex(currentRow, i + 9);
      totalCell.setFormula('=SUM($col$startRow:$col$endRowB)');
      totalCell.numberFormat = '#,##0';
      totalCell.cellStyle.bold = true;
      totalCell.cellStyle.hAlign = HAlignType.right;
      totalCell.cellStyle.vAlign = VAlignType.center;
      _applyThinBorder(totalCell);
    }
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 22;
    currentRow += 2;
    return currentRow;
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

  static Future<List<Map<String, Object?>>?> getTransactionReportShow(
    DateTime start, // Add end
    DateTime end,
  ) async {
    List<Map<String, Object?>>? dbDatas =
        await LocalDBHandler.runRawSelectQuery(
          """
      SELECT 
        t.datetime AS datetime, 
        SUM(td.quantity * COALESCE(c.price, 0.0)) AS total_price
      FROM ${Transaction.tableName} t
      INNER JOIN ${TransactionDetail.tableName} td
        ON t.id = td.transaction_id
      INNER JOIN ${Product.tableName} c
        ON c.id = td.product_id
      WHERE datetime(t.datetime) >= datetime(?) 
        AND datetime(t.datetime) <= datetime(?)
      GROUP BY t.id
      ORDER BY datetime(t.datetime) ASC;
      """,
          [start.toIso8601String(), end.toIso8601String()],
        );
    if (dbDatas == null) return null;
    List<Map<String, Object?>> datas = [for (final d in dbDatas) Map.of(d)];
    for (int i = 0; i < datas.length; ++i) {
      datas[i]["datetime"] = strToDateTime((datas[i]["datetime"] as String));
      if (datas[i]["total_price"] is int) {
        datas[i]["total_price"] = (datas[i]["total_price"] as int).toDouble();
      }
    }
    return datas;
  }

  static Future<Map<int, List<TransactionRecord>>?> createTransReportGrouped(
    DateTime start, // Add end
    DateTime end,
    List<TransactionRecord>? data,
  ) async {
    data ??= await Report.createTransReport(start, end);
    if (data == null) return null;
    return _groupTransaction(data);
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
    final filePath =
        'Laporan_Penjualan_${start.toIso8601String()}-${end.toIso8601String()}.xlsx';
    final Workbook wb = Workbook();
    final Worksheet sheet = wb.worksheets[0];
    sheet.name = 'Laporan SapiKu';
    final Range titleRange = sheet.getRangeByName('A1:F1');
    titleRange.merge();
    titleRange.setText('Laporan Penjualan dan Stok SapiKu');
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontSize = 15;
    titleRange.cellStyle.vAlign = VAlignType.center;
    sheet.getRangeByIndex(1, 1).rowHeight = 28;
    productData ??= await createProdReport(start, end);
    if (productData == null) return false;
    final startEndRow = await _createTransReportExcel(
      start,
      end,
      sheet,
      reportData,
      _createMapProductReport(productData),
    );
    if (startEndRow == null) return false;

    final currentRow = await _createProductReportExcel(
      start,
      end,
      sheet,
      productData,
    );
    _createTotalIncome(sheet, currentRow, startEndRow.$1, startEndRow.$2);
    FileHandler.saveFileWithPicker(
      bytes: wb.saveAsStream(),
      fileName: filePath,
    );
    wb.dispose();
    return true;
  }

  // static Future<void>
}
