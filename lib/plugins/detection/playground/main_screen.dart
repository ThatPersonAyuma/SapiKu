import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cascade_pipeline.dart';
import 'bounding_box_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CascadePipeline _pipeline = CascadePipeline();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  List<DetectionResult> _results = [];
  ProfilingMetrics? _metrics;
  Size _imageSize = Size.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pipeline.initialize();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _isLoading = true;
    });

    final output = await _pipeline.processImage(_selectedImage!);

    setState(() {
      _results = output['results'];
      _metrics = output['metrics'];
      _imageSize = Size(
        (output['imageWidth'] ?? 1).toDouble(), 
        (output['imageHeight'] ?? 1).toDouble()
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cascade TFLite Pipeline'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Column(
        children: [
          // Display Area Gambar & Overlay
          Expanded(
            child: _selectedImage == null
                ? const Center(child: Text('Pilih gambar dari kamera/galeri'))
                : Stack(
                    children: [
                      Center(child: Image.file(_selectedImage!)),
                      // Di dalam Stack pada main_screen.dart:
                      if (_selectedImage != null)
                        Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _imageSize.width,
                              height: _imageSize.height,
                              child: CustomPaint(
                                painter: BoundingBoxPainter(
                                  results: _results,
                                  originalImageSize: _imageSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Center(
                          child: AspectRatio(
                            aspectRatio: _imageSize.width / _imageSize.height,
                            child: CustomPaint(
                              painter: BoundingBoxPainter(
                                results: _results,
                                originalImageSize: _imageSize,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // Profiling Performance Dashboard
          if (_metrics != null) _buildProfilingDashboard(),

          // Button Bar (Camera & Gallery)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blueGrey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickAndProcessImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickAndProcessImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfilingDashboard() {
    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metrik Profiling Performa:', 
            style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('• YOLOv8n Latency        : ${_metrics!.yoloTimeMs} ms', style: _metricStyle),
          Text('• Crop & Resize Top 2 ROI : ${_metrics!.cropTimeMs} ms', style: _metricStyle),
          Text('• MobileNetV3 Latency    : ${_metrics!.mobileNetTimeMs} ms', style: _metricStyle),
          const Divider(color: Colors.white24),
          Text('• Total Latency Pipeline  : ${_metrics!.totalTimeMs} ms (${(1000 / (_metrics!.totalTimeMs == 0 ? 1 : _metrics!.totalTimeMs)).toStringAsFixed(1)} FPS)', 
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  final TextStyle _metricStyle = const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace');
}