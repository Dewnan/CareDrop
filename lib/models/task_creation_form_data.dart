import 'package:flutter/material.dart';

// Data transfer model holding user input during task creation
class TaskCreationFormData {
  String taskType;
  String description;
  String? additionalInstructions;
  
  // Pickup Location Details & Coordinates
  String pickupHospital;
  String pickupBuilding;
  String pickupWard;
  String pickupRoomBed;
  double? pickupLat;
  double? pickupLng;

  // Drop-off Location Details & Coordinates
  String dropoffWard;
  String dropoffRoomBed;
  double? dropoffLat;
  double? dropoffLng;

  // Schedule & Priority
  bool isAsap;
  DateTime scheduledDate;
  TimeOfDay scheduledTime;
  String priority; // 'Normal', 'Urgent'

  // Budget & Payment (Manual budget kept per user instruction)
  String? budget; // LKR
  String paymentMethod; // 'Cash', 'Online Payment'

  // Item Details
  String? itemName;
  String? itemQuantity;
  String? itemSpecialInstructions;

  // Attachments
  String? attachmentFileName;
  String? attachmentUrl;
  String? localAttachmentPath;
  dynamic attachmentBytes; // Uint8List for web/cross-platform support

  // Caregiver Preferences & Contact Method
  String serviceDuration; // '2 Hours', '4 Hours', '8 Hours', '12 Hours'
  String preferredLanguage; // 'Sinhala', 'Tamil', 'English'
  String preferredGender; // 'Any', 'Male', 'Female'
  String contactPreference; // 'In-app Chat', 'Phone Call', 'Either'

  TaskCreationFormData({
    this.taskType = 'Medicine Pickup',
    this.description = '',
    this.additionalInstructions,
    this.pickupHospital = '',
    this.pickupBuilding = '',
    this.pickupWard = '',
    this.pickupRoomBed = '',
    this.pickupLat,
    this.pickupLng,
    this.dropoffWard = '',
    this.dropoffRoomBed = '',
    this.dropoffLat,
    this.dropoffLng,
    this.isAsap = true,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    this.priority = 'Normal',
    this.budget,
    this.paymentMethod = 'Cash',
    this.itemName,
    this.itemQuantity,
    this.itemSpecialInstructions,
    this.attachmentFileName,
    this.serviceDuration = '2 Hours',
    this.preferredLanguage = 'Sinhala',
    this.preferredGender = 'Any',
    this.contactPreference = 'In-app Chat',
  })  : scheduledDate = scheduledDate ?? DateTime.now(),
        scheduledTime = scheduledTime ?? TimeOfDay.now();
}
