import 'package:flutter/foundation.dart';

class ManagementProvider extends ChangeNotifier {
  List<Map<String, dynamic>> entries = [];
  void addEntry(Map<String, dynamic> e) { entries.add(e); notifyListeners(); }
  double get totalLiters => entries.fold(0, (s, e) => s + (e['liters'] as double));
}
