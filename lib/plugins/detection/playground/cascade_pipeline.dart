import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class DetectionResult {
  final Rect boundingBox;
  final double yoloScore;
  final String label;
  final double classificationScore;

  DetectionResult({
    required this.boundingBox,
    required this.yoloScore,
    required this.label,
    required this.classificationScore,
  });
}

class ProfilingMetrics {
  int yoloTimeMs = 0;
  int cropTimeMs = 0;
  int mobileNetTimeMs = 0;
  int totalTimeMs = 0;
}

class CascadePipeline {
  IsolateInterpreter? _yoloIsolate;
  IsolateInterpreter? _mobileNetIsolate;
  List<String> _labels = [];

  Future<void> initialize() async {
    final yoloInterp = await Interpreter.fromAsset('assets/models/yolov8n_f32.tflite');
    _yoloIsolate = await IsolateInterpreter.create(address: yoloInterp.address);

    final mobileNetInterp = await Interpreter.fromAsset('assets/models/mobilenetv3_lumpy_f32.tflite');
    _mobileNetIsolate = await IsolateInterpreter.create(address: mobileNetInterp.address);

    _labels = ['healthy', 'lumpy_skin', 'other'];

    final options = InterpreterOptions();
      // Aktifkan GPU Delegate (Android/iOS)
      if (Platform.isAndroid) {
        options.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        options.addDelegate(GpuDelegate());
      }
  }

  Future<Map<String, dynamic>> processImage(File imageFile) async {
    final metrics = ProfilingMetrics();
    final totalWatch = Stopwatch()..start();

    // 1. Decode gambar
    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? originalImg = img.decodeImage(bytes);
    if (originalImg == null) return {'results': <DetectionResult>[], 'metrics': metrics};

    // 2. Preprocess YOLOv8 (640x640)
    final yoloInputImg = img.copyResize(originalImg, width: 640, height: 640);
    final yoloInputBuffer = _imageToFloat32Buffer(yoloInputImg, 640, 640);

    // 3. Inference YOLOv8n (Shape [1, 5, 8400])
    final yoloWatch = Stopwatch()..start();
    var yoloOutput = List.filled(1 * 5 * 8400, 0.0).reshape([1, 5, 8400]);
    await _yoloIsolate!.run(yoloInputBuffer, yoloOutput);
    yoloWatch.stop();
    metrics.yoloTimeMs = yoloWatch.elapsedMilliseconds;

    // 4. Extract ROI & Penerapan NMS
    List<Map<String, dynamic>> allDetections = _parseYoloOutput(
      yoloOutput[0], 
      originalImg.width, 
      originalImg.height
    );

    // 5. Ambil Top 2 ROI Unik Teratas
    final top2Detections = allDetections.take(2).toList();
    List<DetectionResult> finalResults = [];

    // 6. Crop ROI -> MobileNetV3
    final cropWatch = Stopwatch()..start();
    final mobileNetWatch = Stopwatch();

    for (var det in top2Detections) {
      Rect box = det['box'];
      double yoloScore = det['score'];

      cropWatch.start();
      // Validasi boundary cropping
      int cropX = box.left.toInt().clamp(0, originalImg.width - 1);
      int cropY = box.top.toInt().clamp(0, originalImg.height - 1);
      int cropW = box.width.toInt().clamp(1, originalImg.width - cropX);
      int cropH = box.height.toInt().clamp(1, originalImg.height - cropY);

      img.Image croppedRoi = img.copyCrop(
        originalImg,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      img.Image resizedRoi = img.copyResize(croppedRoi, width: 224, height: 224);
      Float32List mobileNetInput = _imageToFloat32Buffer(resizedRoi, 224, 224);
      cropWatch.stop();

      mobileNetWatch.start();
      var clsOutput = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      await _mobileNetIsolate!.run(mobileNetInput, clsOutput);
      mobileNetWatch.stop();

      List<double> scores = List<double>.from(clsOutput[0]);
      int bestClassIdx = 0;
      double maxScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          bestClassIdx = i;
        }
      }

      finalResults.add(DetectionResult(
        boundingBox: box,
        yoloScore: yoloScore,
        label: _labels[bestClassIdx],
        classificationScore: maxScore,
      ));
    }

    metrics.cropTimeMs = cropWatch.elapsedMilliseconds;
    metrics.mobileNetTimeMs = mobileNetWatch.elapsedMilliseconds;
    
    totalWatch.stop();
    metrics.totalTimeMs = totalWatch.elapsedMilliseconds;

    return {
      'results': finalResults,
      'metrics': metrics,
      'imageWidth': originalImg.width,
      'imageHeight': originalImg.height,
    };
  }

  Float32List _imageToFloat32Buffer(img.Image image, int width, int height) {
    var buffer = Float32List(1 * width * height * 3);
    int pixelIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return buffer;
  }

  // Parsing Dinamis Output YOLOv8 [5, 8400]
  

  // Fungsi pembantu Sigmoid jika model mengeluarkan raw logits
  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

  List<Map<String, dynamic>> _parseYoloOutput(List<List<double>> output, int imgW, int imgH) {
    List<Map<String, dynamic>> rawBoxes = [];
    int numChannels = output.length; // 5 kanal
    
    // 1. Turunkan threshold awal untuk inspeksi deteksi
    double threshold = 0.01; // 
    double maxScoreFoundInModel = 0.0;

    for (int i = 0; i < 8400; i++) {
      double rawScore = output[4][i];
      
      // Terapkan Sigmoid jika nilai score di luar rentang [0.0, 1.0]
      double score = (rawScore < 0.0 || rawScore > 1.0) ? _sigmoid(rawScore) : rawScore;

      if (score > maxScoreFoundInModel) {
        maxScoreFoundInModel = score;
      }

      if (score > threshold) {
        double rawCx = output[0][i];
        double rawCy = output[1][i];
        double rawW = output[2][i];
        double rawH = output[3][i];

        // Detect Otomatis: Apakah koordinat piksel (0-640) atau ternormalisasi (0-1)
        bool isNormalized = rawCx <= 1.0 && rawCy <= 1.0 && rawW <= 1.0 && rawH <= 1.0;

        double cx = isNormalized ? rawCx * imgW : (rawCx / 640.0) * imgW;
        double cy = isNormalized ? rawCy * imgH : (rawCy / 640.0) * imgH;
        double w  = isNormalized ? rawW * imgW  : (rawW / 640.0) * imgW;
        double h  = isNormalized ? rawH * imgH  : (rawH / 640.0) * imgH;

        Rect rect = Rect.fromLTWH(cx - (w / 2), cy - (h / 2), w, h);
        rawBoxes.add({'box': rect, 'score': score});
      }
    }

    // Debug Log ke Konsol untuk memastikan skor tertinggi yang ditemukan YOLO
    debugPrint("YOLO Max Score Found: ${maxScoreFoundInModel.toStringAsFixed(4)} | Total Deteksi Lolos: ${rawBoxes.length}");

    return _applyNMS(rawBoxes, iouThreshold: 0.45);
  }

  // Non-Maximum Suppression (NMS)
  List<Map<String, dynamic>> _applyNMS(List<Map<String, dynamic>> boxes, {required double iouThreshold}) {
    boxes.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    List<Map<String, dynamic>> selected = [];

    for (var box in boxes) {
      bool keep = true;
      for (var sel in selected) {
        if (_calculateIoU(box['box'] as Rect, sel['box'] as Rect) > iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) {
        selected.add(box);
      }
    }
    return selected;
  }

  double _calculateIoU(Rect a, Rect b) {
    Rect intersection = a.intersect(b);
    if (intersection.width <= 0 || intersection.height <= 0) return 0.0;
    double interArea = intersection.width * intersection.height;
    double unionArea = (a.width * a.height) + (b.width * b.height) - interArea;
    return unionArea <= 0 ? 0.0 : interArea / unionArea;
  }
}