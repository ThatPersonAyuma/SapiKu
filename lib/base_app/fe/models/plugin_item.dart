import 'package:flutter/widgets.dart';

class PluginItem {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final IconData subIcon;
  const PluginItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.subIcon,
  });
}
