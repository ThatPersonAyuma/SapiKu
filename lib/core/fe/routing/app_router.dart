import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/pages/home_page.dart';
import 'package:sapiku/plugins/detection/fe/pages/camera_page.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_history_page.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_menu_page.dart';

class AppRouter {
  static const String home = '/';
  static const String detection = '/detection';
  static const String detectionCamera = '/detection/camera';
  static const String detectionHistory = '/detection/history';
  static const String management = '/management';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case home:
        return _slide(const HomePage(), s);
      case detection:
        return _slide(const DetectionMenuPage(), s);
      case detectionCamera:
        return _slide(const CameraPage(), s);
      case detectionHistory:
        return _slide(const DetectionHistoryPage(), s);
      default:
        return _slide(const Scaffold(body: Center(child: Text('Route not found'))), s);
    }
  }

  static PageRouteBuilder _slide(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: anim.drive(tween), child: child);
      },
    );
  }
}
