import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/widgets/plugin_card.dart';

class AvailablePluginData {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final IconData subIcon;
  final PluginCallback? onTap;
  const AvailablePluginData(
    {required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.subIcon,
    required this.onTap,}
  );
}
