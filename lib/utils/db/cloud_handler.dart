import 'package:sapiku/utils/db/local_handler.dart';
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
  final future = await Supabase.instance.client.from('Test').select();
  // List<Map<String,dynamic>> convertedList = future.map((element) => Map<String, dynamic>.from(element)).toList();
  print("Hasil cloud: $future");
}

Future<List<PluginConf>?> getPluginData() async {
  try {
    final res = await Supabase.instance.client
        .from('plugins')
        .select('name, version, track');
    print("plugin data: $res");
    return [for (final map in res) PluginConf.createFromMap(map)];
  } catch (e) {
    PopUpMessage.showOkMessage(
      PopUpTitle.error,
      "Terjadi kesalahan ketika mengambil data plugin dari database.",
    );
    return null;
  }
}

class PluginConf {
  String name;
  String version;
  String track;

  PluginConf(this.name, this.version, this.track);

  static PluginConf createFromMap(Map<String, Object?> map) {
    return PluginConf(
      map['name'] as String,
      map['version'] as String,
      map['track'] as String,
    );
  }
}

// Describe all queried data here
