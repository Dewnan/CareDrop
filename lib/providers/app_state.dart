import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/helper_model.dart';
import '../models/task_model.dart';
import '../models/earnings_model.dart';
import '../models/review_model.dart';
import '../services/user_session_service.dart';
import '../services/location_tracker_service.dart';
import '../services/fcm_notification_service.dart';

enum AppRole { landing, roleSelection, helper, patient }

class CareDropAppState extends ChangeNotifier {
  AppRole _currentRole = AppRole.landing;
  int _currentTab = 0;
  UserModel? _currentUserModel;

  HelperModel _helperUser = HelperModel(
    id: '',
    fullName: 'Helper User',
    icNumber: '',
    phoneNumber: '',
    email: '',
    rating: 0.0,
    totalTasksCompleted: 0,
    todayEarnings: 0.0,
    verificationStatus: 'Verified',
    isOnline: true,
  );

  // Settings
  bool _taskAlerts = true;
  bool _paymentUpdates = true;
  bool _promotions = false;
  bool _autoAcceptTasks = false;
  bool _showOnMap = true;

  // Active Task state
  TaskModel? _activeTask;
  int _activeTimerSeconds = 0;
  Timer? _timer;


  // Available Tasks
  final List<TaskModel> _availableTasks = [];

  // Earnings History
  final List<EarningsItem> _earningsHistory = [];

  // Reviews List
  final List<ReviewItem> _reviews = [];

  // Getters
  AppRole get currentRole => _currentRole;
  int get currentTab => _currentTab;
  UserModel? get currentUserModel => _currentUserModel;
  HelperModel get helperUser => _helperUser;
  List<TaskModel> get availableTasks => _availableTasks;
  TaskModel? get activeTask => _activeTask;

  List<EarningsItem> get earningsHistory => _earningsHistory;
  List<ReviewItem> get reviews => _reviews;
  int get activeTimerSeconds => _activeTimerSeconds;

  bool get taskAlerts => _taskAlerts;
  bool get paymentUpdates => _paymentUpdates;
  bool get promotions => _promotions;
  bool get autoAcceptTasks => _autoAcceptTasks;
  bool get showOnMap => _showOnMap;

  CareDropAppState() {
    _startTimer();
  }

  void setUserModel(UserModel user) {
    _currentUserModel = user;
    final isHelperRole = user.role.toLowerCase() == 'helper';
    _currentRole = isHelperRole ? AppRole.helper : AppRole.patient;

    _helperUser = HelperModel(
      id: user.id,
      fullName: user.fullName,
      icNumber: user.icNumber,
      phoneNumber: user.phone,
      email: user.email,
      profilePictureUrl: user.profilePictureUrl,
      rating: _helperUser.rating,
      totalTasksCompleted: _helperUser.totalTasksCompleted,
      todayEarnings: _helperUser.todayEarnings,
      verificationStatus: 'Verified',
      isOnline: _helperUser.isOnline,
    );

    UserSessionService.saveCachedUser(user);
    FcmNotificationService.registerFcmToken(uid: user.id);
    notifyListeners();
  }

  void clearSession() {
    _currentUserModel = null;
    _currentRole = AppRole.landing;
    _currentTab = 0;
    UserSessionService.clearCache();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_activeTask != null) {
        _activeTimerSeconds++;
        notifyListeners();
      }
    });
  }


  String get formattedTimer {
    final minutes = (_activeTimerSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_activeTimerSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // State Modifiers
  void setRole(AppRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setTab(int tabIndex) {
    _currentTab = tabIndex;
    notifyListeners();
  }

  /// Toggles the online availability of the helper, starts/stops background location tracking, and syncs status to backend
  void toggleOnlineAvailability({double? latitude, double? longitude}) {
    final newStatus = !_helperUser.isOnline;
    _helperUser = _helperUser.copyWith(
      isOnline: newStatus,
      latitude: latitude ?? _helperUser.latitude,
      longitude: longitude ?? _helperUser.longitude,
    );
    notifyListeners();

    if (_currentUserModel != null && _currentUserModel!.id.isNotEmpty) {
      final uid = _currentUserModel!.id;
      if (newStatus) {
        LocationTrackerService.startTracking(uid: uid);
      } else {
        LocationTrackerService.stopTracking(uid: uid);
      }
    }
  }

  void updateHelperInfo({
    String? name,
    String? ic,
    String? phone,
    String? email,
  }) {
    _helperUser = _helperUser.copyWith(
      fullName: name,
      icNumber: ic,
      phoneNumber: phone,
      email: email,
    );
    notifyListeners();
  }


  void acceptTask(TaskModel task) {
    _activeTask = task.copyWith(progressStep: TaskProgressStep.taskAccepted);
    _activeTimerSeconds = 0;
    notifyListeners();
  }

  void updateTaskProgressStep(TaskProgressStep step) {
    if (_activeTask != null) {
      _activeTask = _activeTask!.copyWith(progressStep: step);
      notifyListeners();
    }
  }

  void completeProofItem(int index) {
    if (_activeTask != null && index < _activeTask!.proofItems.length) {
      final updatedList = List<ProofItem>.from(_activeTask!.proofItems);
      updatedList[index] = updatedList[index].copyWith(isUploaded: true);
      _activeTask = _activeTask!.copyWith(proofItems: updatedList);
      notifyListeners();
    }
  }

  /// Completes the active task, updates earnings and history, and clears the active task reference.
  void completeActiveTask() {
    if (_activeTask != null) {
      final taskToComplete = _activeTask!;
      _earningsHistory.insert(
        0,
        EarningsItem(
          id: 'earn_${DateTime.now().millisecondsSinceEpoch}',
          title: taskToComplete.title,
          timeStr: 'Just now',
          currency: taskToComplete.currency,
          amount: taskToComplete.price,
          isPending: true,
        ),
      );
      _helperUser = _helperUser.copyWith(
        totalTasksCompleted: _helperUser.totalTasksCompleted + 1,
        todayEarnings: _helperUser.todayEarnings + taskToComplete.price,
      );
      _activeTask = null;
      _activeTimerSeconds = 0;
      notifyListeners();
    }
  }

  // Toggles for settings
  void toggleTaskAlerts(bool v) {
    _taskAlerts = v;
    notifyListeners();
  }

  void togglePaymentUpdates(bool v) {
    _paymentUpdates = v;
    notifyListeners();
  }

  void togglePromotions(bool v) {
    _promotions = v;
    notifyListeners();
  }

  void toggleAutoAcceptTasks(bool v) {
    _autoAcceptTasks = v;
    notifyListeners();
  }

  void toggleShowOnMap(bool v) {
    _showOnMap = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
