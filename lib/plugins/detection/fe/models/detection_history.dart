import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';

class DetectionHistory {
  final String id;
  final File imageFile;
  final List<DetectionResult> results;
  final ProfilingMetrics metrics;
  final Size imageSize;
  final DateTime date;
  const DetectionHistory({
    required this.id,
    required this.imageFile,
    required this.results,
    required this.metrics,
    required this.imageSize,
    required this.date,
  });
  String get primaryLabel => results.isEmpty ? 'Tidak terdeteksi' : results.first.label;
  double get primaryConfidence => results.isEmpty ? 0 : results.first.classificationScore;
}
