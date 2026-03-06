import 'package:flutter/foundation.dart';

class SessionStore {
  static final ValueNotifier<String?> nickname = ValueNotifier<String?>(null);

  static void login(String value) {
    nickname.value = value;
  }

  static void logout() {
    nickname.value = null;
  }
}
