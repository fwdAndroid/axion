import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  bool isChecked = false;

  Future<void> saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('remember_me', isChecked);
  }
}
