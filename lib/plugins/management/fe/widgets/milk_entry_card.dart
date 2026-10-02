import 'package:flutter/material.dart';

class MilkEntryCard extends StatelessWidget {
  final String date; final double liters; final double price;
  const MilkEntryCard({super.key, required this.date, required this.liters, required this.price});
  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text('$liters L'), subtitle: Text(date), trailing: Text('Rp ${price.toStringAsFixed(0)}')));
  }
}
