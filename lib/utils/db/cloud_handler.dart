import 'package:sapiku/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> cloudSetup() async {
  /// This setup doesn't need internet
  await Supabase.initialize(
    url: const String.fromEnvironment("SUPABASE_URL"),
    publishableKey: const String.fromEnvironment("SUPABASE_PUBLISHABLE_KEY"),
  );
}

Future<bool> ensureSignedIn() async {
  final session = supabase.auth.currentSession;

  if (session == null) {
    return false;
  }

  if (session.isExpired) {
    try {
      final response = await supabase.auth.refreshSession();
      return response.session != null;
    } catch (e) {
      return false;
    }
  }

  return true;
}

Future<bool> cloudLogin(String email, String password) async {
  try {
    final AuthResponse res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.session != null;
  } catch (e) {
    return false;
  }
}

Future<void> test() async {
  final res = await checkInternetConnection();
  if (!res) return;
  final _future = await Supabase.instance.client.from('Test').select();
  // List<Map<String,dynamic>> convertedList = _future.map((element) => Map<String, dynamic>.from(element)).toList();
  print("Hasil cloud: $_future");
}

// Describe all queried data here
