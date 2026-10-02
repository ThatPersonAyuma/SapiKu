import 'package:flutter/foundation.dart';

class HomeProvider extends ChangeNotifier {
  List<String> installedPlugins = [];
  void setPlugins(List<String> p) { installedPlugins = p; notifyListeners(); }
}
