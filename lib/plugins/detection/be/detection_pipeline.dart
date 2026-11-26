import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';
import 'package:sapiku/plugins/detection/be/db_class/deases.dart' show Deases;
import 'package:sapiku/plugins/detection/be/plugin.dart';
import 'package:sapiku/utils/utils.dart';

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

enum DetectionCondition { success, noBoundingBox, noDetection }

class _YoloCandidate {
  final Rect box;
  final double score;

  const _YoloCandidate({required this.box, required this.score});
}

class CascadePipeline {
  IsolateInterpreter? _yoloIsolate;
  IsolateInterpreter? _mobileNetIsolate;
  List<String> _labels = <String>[];
  static const int yoloInputSize = 320;
  static const double roiPaddingRatio = 0.08; // margin 8% di sekitar bbox

  /// Used for thressholding YOLO bounding box
  static const double yoloThreshold = 0.5;

  /// Thresshold for classification.
  /// Used for identify if classification prediction is good enough
  static const double classificThresshold = 0.8;

  /// PlaceHolder label for label that failed to be detected by MobileNetv3
  static const String failedClassific = "Gagal Mendeteksi";

  Future<void> initialize() async {
    final InterpreterOptions options = InterpreterOptions();
    // Aktifkan GPU Delegate (Android/iOS)
    if (Platform.isAndroid) {
      options.addDelegate(GpuDelegateV2());
    } else if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    // final yoloInterp = await Interpreter.fromAsset('assets/models/yolov8n_f32.tflite');
    final Directory destinationDir = await getApplicationDocumentsDirectory();
    final Interpreter yoloInterp = Interpreter.fromFile(
      File(
        '${destinationDir.path}/${DetectionPlugin.detectionName}/${DetectionPlugin.modelFolderPrefix}/${DetectionPlugin.yoloFileName}',
      ),
      options: options,
    );
    print("YOLO interpreter shape: ${yoloInterp.getInputTensor(0).shape}");
    _yoloIsolate = await IsolateInterpreter.create(address: yoloInterp.address);

    // final mobileNetInterp = await Interpreter.fromAsset('assets/models/mobilenetv3_lumpy_f32.tflite');
    final Interpreter mobileNetInterp = Interpreter.fromFile(
      File(
        '${destinationDir.path}/${DetectionPlugin.detectionName}/${DetectionPlugin.modelFolderPrefix}/${DetectionPlugin.mobNetFileName}',
      ),
      options: options,
    );
    _mobileNetIsolate = await IsolateInterpreter.create(
      address: mobileNetInterp.address,
    );

    _labels = <String>[
      "healthy_cowhide",
      "lumpy",
      "mange",
      "pediculosis",
      "ringworm",
    ];
  }

  /// Proces Image. Return map.
  /// Return empty if failed to get image or there is no bounding box detected by YOLO that satisfy the yoloThreeshold
  Future<Map<String, dynamic>> processImage(File imageFile) async {
    final ProfilingMetrics metrics = ProfilingMetrics();
    final Stopwatch totalWatch = Stopwatch()..start();

    // 1. Decode gambar
    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? originalImg = img.decodeImage(bytes);
    if (originalImg == null) {
      PopUpMessage.showOkMessage(
        PopUpTitle.error,
        "Gagal pada saat memproses gambar.",
      );
      return <String, dynamic>{
        'results': <DetectionResult>[],
        'metrics': metrics,
        'imageWidth': 0,
        'imageHeight': 0,
      };
    }

    // 2. Preprocess YOLOv8 (320x320)
    final img.Image yoloInputImg = img.copyResize(
      originalImg,
      width: yoloInputSize,
      height: yoloInputSize,
    );
    final Float32List yoloInputBuffer = _imageToFloat32Buffer(
      yoloInputImg,
      yoloInputSize,
      yoloInputSize,
      normalizeDiv255: true,
      isNCHW: true,
    );

    // 3. Inference YOLOv8n (Shape [1, 5, 2100])
    final Stopwatch yoloWatch = Stopwatch()..start();
    final List<List<List<double>>> yoloOutput = _createYoloOutputBuffer();
    await _yoloIsolate!.run(yoloInputBuffer, yoloOutput);
    yoloWatch.stop();
    metrics.yoloTimeMs = yoloWatch.elapsedMilliseconds;

    // 4. Extract ROI & Penerapan NMS
    final List<_YoloCandidate> allDetections = _parseYoloOutput(
      yoloOutput[0],
      originalImg.width,
      originalImg.height,
    );
    if (allDetections.isEmpty) {
      // Meaning there is no yolo bounding box detectedd that satisfy. Show error
      // final resFallback = await _fallback(yoloInputImg);
      // return <String, dynamic>{
      //   'results': <DetectionResult>[
      //     DetectionResult(
      //       boundingBox: Rect.fromLTWH(
      //         (yoloInputImg.width - 224) / 2,
      //         (yoloInputImg.height - 224) / 2,
      //         224,
      //         224,
      //       ),
      //       yoloScore: -1,
      //       label: resFallback.$2,
      //       classificationScore: resFallback.$1,
      //     ),
      //   ],
      //   'metrics': metrics,
      //   'imageWidth': originalImg.width,
      //   'imageHeight': originalImg.height,
      // };
      return <String, dynamic>{
        'results': <DetectionResult>[],
        'metrics': metrics,
        'imageWidth': 0,
        'imageHeight': 0,
      };
    }

    // 5. Ambil Top 2 ROI Unik Teratas
    final List<_YoloCandidate> top2Detections = allDetections.take(1).toList();
    final List<DetectionResult> finalResults = <DetectionResult>[];

    // 6. Crop ROI -> MobileNetV3
    final Stopwatch cropWatch = Stopwatch()..start();
    final Stopwatch mobileNetWatch = Stopwatch();

    for (final _YoloCandidate det in top2Detections) {
      final Rect box = det.box;
      final double yoloScore = det.score;

      cropWatch.start();
      // Validasi boundary cropping
      final double padW = box.width * roiPaddingRatio;
      final double padH = box.height * roiPaddingRatio;

      final int cropX = (box.left - padW).floor().clamp(
        0,
        originalImg.width - 1,
      );
      final int cropY = (box.top - padH).floor().clamp(
        0,
        originalImg.height - 1,
      );
      final int right = (box.right + padW).ceil().clamp(
        cropX + 1,
        originalImg.width,
      );
      final int bottom = (box.bottom + padH).ceil().clamp(
        cropY + 1,
        originalImg.height,
      );

      final int cropW = right - cropX;
      final int cropH = bottom - cropY;

      final img.Image croppedRoi = img.copyCrop(
        originalImg,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final img.Image resizedRoi = img.copyResize(
        croppedRoi,
        width: 224,
        height: 224,
      );
      // Sesuai Python: input float32 0..255 tanpa dibagi 255.0
      final Float32List mobileNetInput = _imageToFloat32Buffer(
        resizedRoi,
        224,
        224,
        normalizeDiv255: false,
      );
      cropWatch.stop();

      mobileNetWatch.start();
      final List<List<double>> clsOutput = _createMobileNetOutputBuffer(
        _labels.length,
      );
      await _mobileNetIsolate!.run(mobileNetInput, clsOutput);
      mobileNetWatch.stop();

      final List<double> scores = List<double>.from(clsOutput[0]);
      int bestClassIdx = 0;
      double maxScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          bestClassIdx = i;
        }
      }
      final String label = (maxScore >= classificThresshold)
          ? _labels[bestClassIdx]
          : failedClassific;

      finalResults.add(
        DetectionResult(
          boundingBox: box,
          yoloScore: yoloScore,
          label: label,
          classificationScore: maxScore,
        ),
      );
    }

    metrics.cropTimeMs = cropWatch.elapsedMilliseconds;
    metrics.mobileNetTimeMs = mobileNetWatch.elapsedMilliseconds;

    totalWatch.stop();
    metrics.totalTimeMs = totalWatch.elapsedMilliseconds;

    if (finalResults.first.label == failedClassific) {
      final resFallback = await _fallback(originalImg);
      finalResults[0] = DetectionResult(
        boundingBox: Rect.fromLTWH((320 - 224) / 2, (320 - 224) / 2, 224, 224),
        yoloScore: -1,
        label: resFallback.$2,
        classificationScore: resFallback.$1,
      );
    }

    return <String, dynamic>{
      'results': finalResults,
      'metrics': metrics,
      'imageWidth': originalImg.width,
      'imageHeight': originalImg.height,
    };
  }

  List<List<List<double>>> _createYoloOutputBuffer() {
    return List<List<List<double>>>.generate(
      1,
      (_) =>
          List<List<double>>.generate(5, (_) => List<double>.filled(2100, 0.0)),
    );
  }

  List<List<double>> _createMobileNetOutputBuffer(int numClasses) {
    return List<List<double>>.generate(
      1,
      (_) => List<double>.filled(numClasses, 0.0),
    );
  }

  Float32List _imageToFloat32Buffer(
    img.Image image,
    int width,
    int height, {
    bool normalizeDiv255 = true,
    bool isNCHW = false,
  }) {
    final Float32List buffer = Float32List(1 * width * height * 3);
    int pixelIndex = 0;
    final double divisor = normalizeDiv255 ? 255.0 : 1.0;
    if (isNCHW) {
      final int channelSize = width * height;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final img.Pixel pixel = image.getPixel(x, y);
          final int idx = y * width + x;
          buffer[idx] = pixel.r / divisor;
          buffer[channelSize + idx] = pixel.g / divisor;
          buffer[2 * channelSize + idx] = pixel.b / divisor;
        }
      }
    }else{
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final img.Pixel pixel = image.getPixel(x, y);
          buffer[pixelIndex++] = pixel.r / divisor;
          buffer[pixelIndex++] = pixel.g / divisor;
          buffer[pixelIndex++] = pixel.b / divisor;
        }
      }
    }
    return buffer;
  }

  /// Fungsi pembantu Sigmoid jika model mengeluarkan raw logits
  // ignore: unused_element
  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

  /// Parsing YOLO output also applay threshold.
  /// If List empty menaing there is no bounding box that satisfy the yoloThrehold
  List<_YoloCandidate> _parseYoloOutput(
    List<List<double>> output,
    int imgW,
    int imgH,
  ) {
    final List<_YoloCandidate> rawBoxes = <_YoloCandidate>[];

    double maxScoreFoundInModel = 0.0;

    for (int i = 0; i < 2100; i++) {
      final double rawScore = output[4][i];
      final double score = rawScore;

      if (score > maxScoreFoundInModel) {
        maxScoreFoundInModel = score;
      }

      if (score > yoloThreshold) {
        final double rawCx = output[0][i];
        final double rawCy = output[1][i];
        final double rawW = output[2][i];
        final double rawH = output[3][i];

        // Detect Otomatis: Apakah koordinat piksel (0-320) atau ternormalisasi (0-1)
        final bool isNormalized =
            rawCx <= 1.0 && rawCy <= 1.0 && rawW <= 1.0 && rawH <= 1.0;

        final double cx = isNormalized
            ? rawCx * imgW
            : (rawCx / yoloInputSize) * imgW;
        final double cy = isNormalized
            ? rawCy * imgH
            : (rawCy / yoloInputSize) * imgH;
        final double w = isNormalized
            ? rawW * imgW
            : (rawW / yoloInputSize) * imgW;
        final double h = isNormalized
            ? rawH * imgH
            : (rawH / yoloInputSize) * imgH;

        final Rect rect = Rect.fromLTWH(cx - (w / 2), cy - (h / 2), w, h);
        rawBoxes.add(_YoloCandidate(box: rect, score: score));
      }
    }

    // Debug Log ke Konsol untuk memastikan skor tertinggi yang ditemukan YOLO
    debugPrint(
      "YOLO Max Score Found: ${maxScoreFoundInModel.toStringAsFixed(4)} | Total Deteksi Lolos: ${rawBoxes.length}",
    );

    return _applyNMS(rawBoxes, iouThreshold: 0.45);
  }

  // Non-Maximum Suppression (NMS)
  List<_YoloCandidate> _applyNMS(
    List<_YoloCandidate> boxes, {
    required double iouThreshold,
  }) {
    final List<_YoloCandidate> sortedBoxes = List<_YoloCandidate>.from(
      boxes,
    )..sort((_YoloCandidate a, _YoloCandidate b) => b.score.compareTo(a.score));
    final List<_YoloCandidate> selected = <_YoloCandidate>[];

    for (final _YoloCandidate box in sortedBoxes) {
      bool keep = true;
      for (final _YoloCandidate sel in selected) {
        if (_calculateIoU(box.box, sel.box) > iouThreshold) {
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
    final Rect intersection = a.intersect(b);
    if (intersection.width <= 0 || intersection.height <= 0) return 0.0;
    final double interArea = intersection.width * intersection.height;
    final double unionArea =
        (a.width * a.height) + (b.width * b.height) - interArea;
    return unionArea <= 0 ? 0.0 : interArea / unionArea;
  }

  img.Image _extract224From320(
    img.Image img320, {
    double? centerX320,
    double? centerY320,
  }) {
    const int patchSize = 224;
    final double cx = centerX320 ?? (img320.width / 2.0);
    final double cy = centerY320 ?? (img320.height / 2.0);

    final int x = (cx - patchSize / 2.0).round().clamp(
      0,
      img320.width - patchSize,
    );
    final int y = (cy - patchSize / 2.0).round().clamp(
      0,
      img320.height - patchSize,
    );

    return img.copyCrop(
      img320,
      x: x,
      y: y,
      width: patchSize,
      height: patchSize,
    );
  }

  Future<(double, String)> _fallback(img.Image oriImage) async {
    final resizedImage = _extract224From320(oriImage);
    final Float32List mobileNetInput = _imageToFloat32Buffer(
      resizedImage,
      224,
      224,
      normalizeDiv255: false,
    );
    final List<List<double>> clsOutput = _createMobileNetOutputBuffer(
      _labels.length,
    );
    await _mobileNetIsolate!.run(mobileNetInput, clsOutput);

    final List<double> scores = List<double>.from(clsOutput[0]);
    int bestClassIdx = 0;
    double maxScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        bestClassIdx = i;
      }
    }
    final String label = (maxScore >= classificThresshold)
        ? _labels[bestClassIdx]
        : failedClassific;
    return (maxScore, label);
  }

  /// Use for get the Text Showed in the detetection result.
  static String getTextResult(DetectionResult detectionResult) {
    if (detectionResult.label == failedClassific) {
      return "Maaf, Sistem kurang yakin terhadap hasil. Disarankan menggunakan gambar yang lebih jelas.";
    } else {
      return "Sapi Terdeteksi Mengalami Penyakit ${detectionResult.label} pada Bagian Kulit";
    }
  }

  /// Query deases class and get its solution.
  /// Consider to cache this because, this method need to do database query.
  static Future<String> getCareMethod(DetectionResult detectionResult) async {
    if (detectionResult.label == failedClassific) {
      return "Deteksi gagal. Maka dari itu belum ada penanganan yang ada.";
    } else {
      final res = await Deases.getByName(detectionResult.label);
      if (res == null) {
        return "Data deases tidak ditemukan.";
      }
      return res.solution;
    }
  }

  /// Method to check wheter detection failed or not.
  /// You can also manually check by checking if the dectionresult list is not empty.
  static bool isSucces(List<DetectionResult> finalResults) {
    return finalResults.isNotEmpty;
  }
}
