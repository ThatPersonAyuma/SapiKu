import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/routing/app_router.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:workmanager/workmanager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Workmanager().initialize(syncCallback);
  // Workmanager().registerOneOffTask(
  //   SyncEngine.taskKey,
  //   SyncEngine.taskName,
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );
  // await Workmanager().registerPeriodicTask(
  //   SyncEngine.taskKey,
  //   SyncEngine.taskName,
  //   frequency: SyncEngine.interval,
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   )
  // );
  // #region setup
  await CloudHandler.cloudSetup();
  await LocalDBHandler.setup();
  await CloudHandler.test();
  await SyncEngine.test();
  print("Login Res: ${await ManageUtils.login()}");
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
      // home: DatabaseTestScreen(),
      navigatorKey: navigatorKey,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
