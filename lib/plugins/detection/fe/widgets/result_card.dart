import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String label; final double confidence;
  const ResultCard({super.key, required this.label, required this.confidence});
  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text(label), subtitle: Text('${(confidence * 100).toStringAsFixed(1)}%')));
  }
}
