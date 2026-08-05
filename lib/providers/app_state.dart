import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/helper_model.dart';
import '../models/task_model.dart';
import '../models/earnings_model.dart';
import '../models/review_model.dart';

enum AppRole { landing, roleSelection, helper, patient }

class CareDropAppState extends ChangeNotifier {
  AppRole _currentRole = AppRole.landing;
  int _currentTab = 0;
  // All the mock data will be replaced when the backed is connected.
  // Helper User
  HelperModel _helperUser = HelperModel(
    id: 'helper_001',
    fullName: 'Dewnan Chamithka',
    icNumber: '200300000000',
    phoneNumber: '+94 70 000 0000',
    email: 'dewnanc@proton.me',
    rating: 4.9,
    totalTasksCompleted: 247,
    todayEarnings: 500.0,
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
  final List<TaskModel> _availableTasks = [
    TaskModel(
      id: 'task_001',
      title: 'Medication Pickup',
      hospital: 'Padukka Base Hospital',
      locationDetail: 'City Pharmacy',
      distanceStr: '0.6 km away',
      distanceKm: 0.6,
      currency: 'RS',
      price: 220.0,
      isUrgent: false,
      category: TaskCategory.medicine,
      deadline: 'Within 30 minutes',
      patientInfo: 'Pesara Ranthila',
      description:
          'Collect 3 prescription medications. Photograph receipt and bag upon collection.',
      startTimeStr: '10:12 AM',
      progressStep: TaskProgressStep.taskAccepted,
      proofItems: [
        ProofItem(
          title: 'Photo of Completed Task',
          isRequired: true,
          isUploaded: true,
        ),
        ProofItem(
          title: 'Receipt / Documentation',
          isRequired: true,
          isUploaded: true,
        ),
        ProofItem(
          title: 'Additional Photo',
          isRequired: false,
          isUploaded: false,
        ),
      ],
    ),
    TaskModel(
      id: 'task_002',
      title: 'Collect Lab report',
      hospital: 'KDH',
      locationDetail: 'KDH Medical Records Office',
      distanceStr: '0.2 km away',
      distanceKm: 0.2,
      currency: 'RS',
      price: 200.0,
      isUrgent: true,
      category: TaskCategory.filing,
      deadline: 'Within 15 minutes',
      patientInfo: 'Pulindu',
      description: 'Submit the recept and collect the report.',
      startTimeStr: '11:30 AM',
      proofItems: [
        ProofItem(title: 'Photo of Stamped Document', isRequired: true),
        ProofItem(title: 'Receipt / Counter Slip', isRequired: true),
      ],
    ),
  ];

  // Earnings History
  final List<EarningsItem> _earningsHistory = [
    EarningsItem(
      id: 'earn_01',
      title: 'Medication Pickup',
      timeStr: 'Today, 10:45 AM',
      currency: 'RS',
      amount: 220.0,
      isPending: true,
    ),
    EarningsItem(
      id: 'earn_02',
      title: 'Collect Lab report',
      timeStr: 'Today, 8:30 AM',
      currency: 'RS',
      amount: 200.0,
      isPending: false,
    ),
  ];

  // Reviews List
  final List<ReviewItem> _reviews = [
    ReviewItem(
      id: 'rev_01',
      reviewerName: 'Pesara Ranthila',
      avatarInitials: 'SA',
      rating: 5.0,
      comment: 'Very prompt and careful with medications.',
      dateStr: '2 hours ago',
    ),
    ReviewItem(
      id: 'rev_02',
      reviewerName: 'Pulindu',
      avatarInitials: 'AB',
      rating: 5.0,
      comment: 'Fast responce.',
      dateStr: 'Yesterday',
    ),
  ];

  // Getters
  AppRole get currentRole => _currentRole;
  int get currentTab => _currentTab;
  HelperModel get helperUser => _helperUser;
  List<TaskModel> get availableTasks => _availableTasks;
  TaskModel? get activeTask => _activeTask ?? _availableTasks.first;
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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _activeTimerSeconds++;
      notifyListeners();
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

  void toggleOnlineAvailability() {
    _helperUser = _helperUser.copyWith(isOnline: !_helperUser.isOnline);
    notifyListeners();
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

  void completeActiveTask() {
    if (_activeTask != null) {
      _activeTask = _activeTask!.copyWith(
        progressStep: TaskProgressStep.completed,
      );
      _earningsHistory.insert(
        0,
        EarningsItem(
          id: 'earn_${DateTime.now().millisecondsSinceEpoch}',
          title: _activeTask!.title,
          timeStr: 'Just now',
          currency: _activeTask!.currency,
          amount: _activeTask!.price,
          isPending: true,
        ),
      );
      _helperUser = _helperUser.copyWith(
        totalTasksCompleted: _helperUser.totalTasksCompleted + 1,
        todayEarnings: _helperUser.todayEarnings + _activeTask!.price,
      );
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
