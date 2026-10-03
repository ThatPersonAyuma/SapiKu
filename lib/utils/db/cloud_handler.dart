import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> cloudSetup() async {
  /// This setup doesn't need internet
  await Supabase.initialize(
    url: const String.fromEnvironment("SUPABASE_URL"),
    publishableKey: const String.fromEnvironment("SUPABASE_PUBLISHABLE_KEY"),
  );
}

Future<bool> login(String password) async {
  return false;
}

Future<void> test() async {
  final _future = await Supabase.instance.client.from('Test').select();
  // List<Map<String,dynamic>> convertedList = _future.map((element) => Map<String, dynamic>.from(element)).toList();
  print("Hasil cloud: $_future");
}



// Describe all queried data here
