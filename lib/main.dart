import 'package:flutter/material.dart';
import 'package:sapiku/plugins/detection/playground/main_screen.dart';
import 'package:sapiku/plugins/management/fe_app.dart';
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // #region setup
  await cloudSetup();
  await test();
  await LocalDBHandler.setup();
  // #endregion

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sapiku',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      // home: HomeScreen() // Try Detection
      home: TextFormFieldExample(), // Try QR Feature
    );
  }
}
