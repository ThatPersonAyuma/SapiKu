import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Pencatatan'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
          children: const [
            Center(child: Text('Pencatatan - placeholder')),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
