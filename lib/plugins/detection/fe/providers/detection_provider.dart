import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:sapiku/plugins/detection/be/detection_pipeline.dart';
import 'package:sapiku/plugins/detection/fe/models/detection_history.dart';

class DetectionProvider extends ChangeNotifier {
  static final DetectionProvider _instance = DetectionProvider._internal();
  factory DetectionProvider() => _instance;
  DetectionProvider._internal();

  final CascadePipeline pipeline = CascadePipeline();
  bool initialized = false;
  bool loading = false;
  String? error;

  List<DetectionResult> results = [];
  ProfilingMetrics? metrics;
  Size imageSize = Size.zero;
  File? lastImage;

  final List<DetectionHistory> history = [];

  Future<void> init() async {
    if (initialized) return;
    await pipeline.initialize();
    initialized = true;
  }

  Future<DetectionHistory?> processImage(File file) async {
    loading = true; error = null; notifyListeners();
    try {
      await init();
      final out = await pipeline.processImage(file);
      results = (out['results'] as List).cast<DetectionResult>();
      metrics = out['metrics'] as ProfilingMetrics;
      final imageWidth = out['imageWidth'] as int? ?? 0;
      final imageHeight = out['imageHeight'] as int? ?? 0;
      imageSize = Size(imageWidth.toDouble(), imageHeight.toDouble());
      lastImage = file;
      final entry = DetectionHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageFile: file,
        results: List.of(results),
        metrics: metrics!,
        imageSize: imageSize,
        date: DateTime.now(),
      );
      history.insert(0, entry);
      return entry;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      loading = false; notifyListeners();
    }
  }
}
