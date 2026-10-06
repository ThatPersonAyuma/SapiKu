import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/routing/app_router.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/be/testing.dart';
import 'package:sapiku/plugins/management/fe_app.dart';
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // #region setup
  await cloudSetup();
  await test();
  await LocalDBHandler.setup();
  await managementSetup();
  // #endregion

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SapiKu',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins'),
      home: DatabaseTestScreen(),
      // initialRoute: AppRouter.home,
      // onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
