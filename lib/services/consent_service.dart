import 'package:shared_preferences/shared_preferences.dart';

class ConsentService {
  static const String _acceptedKey = 'consentAccepted';
  static const String _acceptedAtKey = 'consentAcceptedAt';
  static const String _versionKey = 'consentVersion';
  static const String _dismissedKey = 'consentDismissed';
  static const String currentVersion = '1.0';

  Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedKey) ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_acceptedKey, true);
    await prefs.setBool(_dismissedKey, false);
    await prefs.setString(_acceptedAtKey, DateTime.now().toIso8601String());
    await prefs.setString(_versionKey, currentVersion);
  }

  Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedKey) ?? false;
  }

  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  Future<void> revoke() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_acceptedKey);
    await prefs.remove(_acceptedAtKey);
    await prefs.remove(_versionKey);
    await prefs.remove(_dismissedKey);
  }
}
