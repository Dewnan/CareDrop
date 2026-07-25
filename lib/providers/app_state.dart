import 'package:flutter/foundation.dart';

enum AppRole { landing, roleSelection, helper, patient }

class CareDropAppState extends ChangeNotifier {
  AppRole _currentRole = AppRole.landing;
  int _currentTab = 0;

  // Getters
  AppRole get currentRole => _currentRole;
  int get currentTab => _currentTab;

  CareDropAppState() {}

  // State Modifiers
  void setRole(AppRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setTab(int tabIndex) {
    _currentTab = tabIndex;
    notifyListeners();
  }
}
