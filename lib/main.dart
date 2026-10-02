import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/routing/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SapiKu',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins'),
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
