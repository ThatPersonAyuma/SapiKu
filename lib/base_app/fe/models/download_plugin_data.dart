import 'package:flutter/material.dart';
import 'package:sapiku/utils/db/local_handler.dart';

class DownloadPluginData {
  final String title;
  final String name;
  final String subtitle;
  final IconData icon;
  final Future<bool> Function(VoidCallback, String) downloadCallback;
  final Future<void> Function() removeCallback;
  Plugin? plugin;
  final String version;
  DownloadPluginData({
    required this.title,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.downloadCallback,
    required this.removeCallback,
    this.plugin,
    required this.version
  });
}
