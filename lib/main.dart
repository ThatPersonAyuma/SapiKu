import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/routing/app_router.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/plugins/management/be/testing.dart';
// import 'package:sapiku/plugins/management/be/uploadImageTest.dart';
import 'package:sapiku/utils/db/cloud_handler.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:workmanager/workmanager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Workmanager().initialize(syncCallback);
  // await Workmanager().registerPeriodicTask(
  //   SyncEngine.taskKeySync,
  //   SyncEngine.taskNameSync,
  //   frequency: SyncEngine.interval,
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   )
  // );
  // // #region setup
  // await CloudHandler.cloudSetup();
  // await LocalDBHandler.setup();
  // await CloudHandler.test();
  // print("Login Res: ${await ManageUtils.login()}");
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
      home: const AppBootstrapScreen(),
      navigatorKey: navigatorKey,
      // initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  String _statusText = 'Memulai aplikasi...';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _errorText = null;
      _statusText = 'Mengatur tugas latar belakang...';
    });

    try {
      await Workmanager().initialize(syncCallback);
      await Workmanager().registerPeriodicTask(
        SyncEngine.taskKeySync,
        SyncEngine.taskNameSync,
        frequency: SyncEngine.interval,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      if (!mounted) return;
      setState(() => _statusText = 'Menyiapkan layanan cloud...');
      await CloudHandler.cloudSetup();

      if (!mounted) return;
      setState(() => _statusText = 'Menyiapkan database lokal...');
      await LocalDBHandler.setup();

      if (!mounted) return;
      setState(() => _statusText = 'Menguji koneksi server...');
      await CloudHandler.test();

      if (!mounted) return;
      setState(() => _statusText = 'Melakukan login otomatis...');
      final loginRes = await ManageUtils.login();
      debugPrint('Login Res: $loginRes');

      if (!mounted) return;
      // Ganti dengan halaman utama aplikasi Anda
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => const TestSync()),
      // );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Gagal memuat aplikasi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Bisa diganti warna tema atau gradient
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _errorText != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeApp,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bisa diganti logo aplikasi atau animasi Lottie
                    // const Image(image: AssetImage("assets/images/logo.png"),),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

