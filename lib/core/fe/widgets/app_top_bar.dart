import 'package:flutter/material.dart';

class SapikuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const SapikuAppBar({super.key, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white
      ),
      centerTitle: false,
      titleSpacing: 2,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            )
          : null,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/cloud-top.png'), fit: BoxFit.cover),
        ),
      ),
      actions: [
        Row(
          children: [
            const Text('SAPIKU', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Image.asset('assets/images/logo.png', width: 42, height: 42),
            const SizedBox(width: 24),
          ],
        ),
      ],
    );
  }
}
