import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/pages/home_page.dart';
import 'package:sapiku/plugins/detection/fe/pages/camera_page.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_history_page.dart';
import 'package:sapiku/plugins/detection/fe/pages/detection_menu_page.dart';
import 'package:sapiku/plugins/management/fe/pages/management_menu_page.dart';
import 'package:sapiku/plugins/management/fe/pages/management_page.dart';
import 'package:sapiku/plugins/management/fe/pages/penjualan_detail_page.dart';
import 'package:sapiku/plugins/management/fe/pages/penjualan_page.dart';
import 'package:sapiku/plugins/management/fe/pages/penjualan_tambah_page.dart';

class AppRouter {
  static const String home = '/';
  static const String detection = '/detection';
  static const String detectionCamera = '/detection/camera';
  static const String detectionHistory = '/detection/history';
  static const String management = '/management';
  static const String managementPencatatan = '/management/pencatatan';
  static const String managementPenjualan = '/management/penjualan';
  static const String managementPenjualanDetail = '/management/penjualan/detail';
  static const String managementPenjualanTambah = '/management/penjualan/tambah';

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
      case management:
        return _slide(const ManagementMenuPage(), s);
      case managementPencatatan:
        return _slide(const ManagementPage(), s);
      case managementPenjualan:
        return _slide(const PenjualanPage(), s);
      case managementPenjualanDetail:
        {
          final args = s.arguments as Map<String, dynamic>?;
          if (args != null) {
            final raw = args['items'] as List;
            final items = raw.map<({String name, int qty, String price})>((e) {
              if (e is Map) return (name: e['name'] as String, qty: e['qty'] as int, price: e['price'] as String);
              return e as ({String name, int qty, String price});
            }).toList();
            return _slide(PenjualanDetailPage(timeLabel: args['time'] as String, items: items, totalLabel: args['total'] as String), s);
          }
          return _slide(const PenjualanDetailPage(timeLabel: '10:30 - 12 Januari 2025', items: [(name: 'Susu Segar 1L', qty: 2, price: 'Rp 30.000')], totalLabel: 'Rp 30.000'), s);
        }
      case managementPenjualanTambah:
        return _slide(const PenjualanTambahPage(), s);
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
