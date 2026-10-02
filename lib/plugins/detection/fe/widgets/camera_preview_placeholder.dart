import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';

class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined, size: 48, color: Colors.white54),
            SizedBox(height: 12),
            Text('Preview kamera', style: TextStyle(color: Colors.white54)),
            SizedBox(height: 4),
            Text('Integrasi camera / image_picker di sini', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class ShutterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const ShutterButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.brown, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: const Icon(Icons.camera_alt, size: 32, color: AppColors.darkCard),
      ),
    );
  }
}
