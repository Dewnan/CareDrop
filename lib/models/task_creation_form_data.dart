import 'package:flutter/material.dart';

class TaskCreationFormData {
  String taskType;
  String description;
  String? additionalInstructions;
  
  // Pickup Location
  String pickupHospital;
  String pickupBuilding;
  String pickupWard;
  String pickupRoomBed;

  // Drop-off Location
  String dropoffWard;
  String dropoffRoomBed;

  // Date & Time
  bool isAsap;
  DateTime scheduledDate;
  TimeOfDay scheduledTime;

  // Priority
  String priority; // 'Normal', 'Urgent'

  // Budget & Payment
  String? budget; // LKR
  String paymentMethod; // 'Cash', 'Online Payment'

  // Item Details
  String? itemName;
  String? itemQuantity;
  String? itemSpecialInstructions;

  // Attachments
  String? attachmentFileName;

  // Helper Preferences
  String preferredLanguage; // 'Sinhala', 'Tamil', 'English'
  String preferredGender; // 'No preference', 'Male', 'Female'

  // Contact Preference
  String contactPreference; // 'In-app Chat', 'Phone Call', 'Either'

  TaskCreationFormData({
    this.taskType = 'Medicine Pickup',
    this.description = '',
    this.additionalInstructions,
    this.pickupHospital = '',
    this.pickupBuilding = '',
    this.pickupWard = '',
    this.pickupRoomBed = '',
    this.dropoffWard = '',
    this.dropoffRoomBed = '',
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
    this.preferredLanguage = 'Sinhala',
    this.preferredGender = 'No preference',
    this.contactPreference = 'In-app Chat',
  })  : scheduledDate = scheduledDate ?? DateTime.now(),
        scheduledTime = scheduledTime ?? TimeOfDay.now();
}
