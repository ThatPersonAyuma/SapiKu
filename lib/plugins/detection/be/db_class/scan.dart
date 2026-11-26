class ScanComponent {
  int labelId;
  double xCenter;
  double yCenter;
  double width;
  double height;
  String detectionResult;
  double confident;

  ScanComponent(
    this.labelId,
    this.xCenter,
    this.yCenter,
    this.width,
    this.height,
    this.detectionResult,
    this.confident,
  );
}

class Scan {
  static const tableName = "scans";

  int id;
  int labelId;
  int detectionId;

  /// Has value in range [0,1], ratio of the image
  double xCenter;

  /// Has value in range [0,1], ratio of the image
  double yCenter;

  /// Has value in range [0,1], ratio of the image
  double width;

  /// Has value in range [0,1], ratio of the image
  double height;
  String detectionResult;
  double confident;

  Scan(
    this.id,
    this.labelId,
    this.detectionId,
    this.xCenter,
    this.yCenter,
    this.width,
    this.height,
    this.detectionResult,
    this.confident,
  );

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'label_id': labelId,
      'detection_id': detectionId,
      'x_cebter': xCenter,
      'y_center': yCenter,
      'width': width,
      'height': height,
      'result': detectionResult,
      'confident': confident,
    };
  }

  @override
  String toString() {
    return 'Deases{id: $id, labelId: $labelId, xCenter: $xCenter, yCenter: $yCenter, width: $width, height: $height, detectionResult: $detectionResult, confident: $confident}';
  }
}
