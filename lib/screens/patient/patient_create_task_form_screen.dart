import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../components/document_picker.dart';
import '../../components/location_picker_map.dart';
import '../../models/task_creation_form_data.dart';
import '../../services/geoapify_service.dart';
import '../../theme/app_theme.dart';
import 'patient_task_confirm_screen.dart';


/// Screen allowing patients to quickly create a task.
/// Includes inline task type selector, map location pickers, and dynamic/conditional forms.
class PatientCreateTaskFormScreen extends StatefulWidget {
  final String initialTaskType;

  const PatientCreateTaskFormScreen({
    super.key,
    this.initialTaskType = 'Medicine Pickup',
  });

  @override
  State<PatientCreateTaskFormScreen> createState() =>
      _PatientCreateTaskFormScreenState();
}

class _PatientCreateTaskFormScreenState
    extends State<PatientCreateTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TaskCreationFormData _formData;

  // Form field controllers
  late TextEditingController _pickupHospitalController;
  late TextEditingController _pickupBuildingController;
  late TextEditingController _pickupWardController;
  late TextEditingController _pickupRoomBedController;
  late TextEditingController _dropoffWardController;
  late TextEditingController _dropoffRoomBedController;
  late TextEditingController _descriptionController;
  late TextEditingController _addInstructionsController;
  late TextEditingController _budgetController;
  late TextEditingController _itemNameController;
  late TextEditingController _itemQuantityController;
  late TextEditingController _itemInstructionsController;

  // Address autocomplete search state
  List<GeoapifySearchResult> _pickupSearchResults = [];
  bool _isSearchingPickup = false;
  Timer? _pickupDebounceTimer;

  List<GeoapifySearchResult> _dropoffSearchResults = [];
  bool _isSearchingDropoff = false;
  Timer? _dropoffDebounceTimer;

  // Pre-defined Task Types without icons
  final List<String> _taskTypeOptions = [
    'Medicine Pickup',
    'Pharmacy Purchase',
    'Queue/Token Assistance',
    'Document Delivery',
    'Food Pickup',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _formData = TaskCreationFormData(taskType: widget.initialTaskType);
    _pickupHospitalController = TextEditingController(text: _formData.pickupHospital);
    _pickupBuildingController = TextEditingController(text: _formData.pickupBuilding);
    _pickupWardController = TextEditingController(text: _formData.pickupWard);
    _pickupRoomBedController = TextEditingController(text: _formData.pickupRoomBed);
    _dropoffWardController = TextEditingController(text: _formData.dropoffWard);
    _dropoffRoomBedController = TextEditingController(text: _formData.dropoffRoomBed);
    _descriptionController = TextEditingController(text: _formData.description);
    _addInstructionsController = TextEditingController(text: _formData.additionalInstructions);
    _budgetController = TextEditingController(text: _formData.budget ?? '250');
    _itemNameController = TextEditingController(text: _formData.itemName);
    _itemQuantityController = TextEditingController(text: _formData.itemQuantity);
    _itemInstructionsController = TextEditingController(text: _formData.itemSpecialInstructions);
  }

  @override
  void dispose() {
    _pickupDebounceTimer?.cancel();
    _dropoffDebounceTimer?.cancel();
    _pickupHospitalController.dispose();
    _pickupBuildingController.dispose();
    _pickupWardController.dispose();
    _pickupRoomBedController.dispose();
    _dropoffWardController.dispose();
    _dropoffRoomBedController.dispose();
    _descriptionController.dispose();
    _addInstructionsController.dispose();
    _budgetController.dispose();
    _itemNameController.dispose();
    _itemQuantityController.dispose();
    _itemInstructionsController.dispose();
    super.dispose();
  }

  /// Handles real-time search query changes for pickup or dropoff location with debounce.
  void _onLocationSearchChanged(String query, {required bool isPickup}) {
    if (isPickup) {
      _pickupDebounceTimer?.cancel();
      if (query.trim().length < 3) {
        setState(() => _pickupSearchResults = []);
        return;
      }
      _pickupDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
        setState(() => _isSearchingPickup = true);
        final results = await GeoapifyService.searchAddress(query);
        if (mounted) {
          setState(() {
            _pickupSearchResults = results;
            _isSearchingPickup = false;
          });
        }
      });
    } else {
      _dropoffDebounceTimer?.cancel();
      if (query.trim().length < 3) {
        setState(() => _dropoffSearchResults = []);
        return;
      }
      _dropoffDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
        setState(() => _isSearchingDropoff = true);
        final results = await GeoapifyService.searchAddress(query);
        if (mounted) {
          setState(() {
            _dropoffSearchResults = results;
            _isSearchingDropoff = false;
          });
        }
      });
    }
  }

  /// Binds selected autocomplete address and coordinates to the task form data.
  void _selectLocationResult(GeoapifySearchResult result, {required bool isPickup}) {
    setState(() {
      if (isPickup) {
        _formData.pickupLat = result.latitude;
        _formData.pickupLng = result.longitude;
        _pickupHospitalController.text = result.formattedAddress;
        _pickupSearchResults = [];
      } else {
        _formData.dropoffLat = result.latitude;
        _formData.dropoffLng = result.longitude;
        _dropoffWardController.text = result.formattedAddress;
        _dropoffSearchResults = [];
      }
    });
  }

  // Determine which form sections are required based on selected task type
  bool get _requiresDropoff =>
      _formData.taskType == 'Medicine Pickup' ||
      _formData.taskType == 'Pharmacy Purchase' ||
      _formData.taskType == 'Document Delivery' ||
      _formData.taskType == 'Food Pickup';

  bool get _requiresItemDetails =>
      _formData.taskType == 'Medicine Pickup' ||
      _formData.taskType == 'Pharmacy Purchase' ||
      _formData.taskType == 'Food Pickup';

  bool get _requiresAttachment =>
      _formData.taskType == 'Medicine Pickup' ||
      _formData.taskType == 'Pharmacy Purchase' ||
      _formData.taskType == 'Document Delivery';

  /// Prompts user with shared modal bottom sheet to pick a document or image file.
  Future<void> _showDocumentPickerOptions() async {
    final pickedFile = await showDocumentPicker(context);
    if (pickedFile != null && mounted) {
      setState(() {
        _formData.attachmentFileName = pickedFile.name;
        _formData.localAttachmentPath = pickedFile.path;
        _formData.attachmentBytes = pickedFile.bytes;
      });
    }
  }

  Future<void> _selectDate() async {

    final picked = await showDatePicker(
      context: context,
      initialDate: _formData.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _formData.scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _formData.scheduledTime,
    );
    if (picked != null) {
      setState(() {
        _formData.scheduledTime = picked;
      });
    }
  }

  // Opens interactive LocationPickerMap component for pickup or dropoff selection
  Future<void> _openMapPicker({required bool isPickup}) async {
    final initialLocation = isPickup
        ? (_formData.pickupLat != null && _formData.pickupLng != null
            ? LatLng(_formData.pickupLat!, _formData.pickupLng!)
            : null)
        : (_formData.dropoffLat != null && _formData.dropoffLng != null
            ? LatLng(_formData.dropoffLat!, _formData.dropoffLng!)
            : null);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          title: isPickup ? 'Select Pickup Location' : 'Select Drop-off Location',
          initialLocation: initialLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      final location = result['location'] as LatLng?;
      final address = result['address'] as String?;

      if (location != null) {
        setState(() {
          if (isPickup) {
            _formData.pickupLat = location.latitude;
            _formData.pickupLng = location.longitude;
            if (address != null && address.isNotEmpty) {
              _pickupHospitalController.text = address;
            }
          } else {
            _formData.dropoffLat = location.latitude;
            _formData.dropoffLng = location.longitude;
            if (address != null && address.isNotEmpty) {
              _dropoffWardController.text = address;
            }
          }
        });
      }
    }
  }


  // Validates and submits task creation form with null safety
  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _formData.description = _descriptionController.text.trim();
      _formData.additionalInstructions = _addInstructionsController.text.trim();
      _formData.pickupHospital = _pickupHospitalController.text.trim();
      _formData.pickupBuilding = _pickupBuildingController.text.trim();
      _formData.pickupWard = _pickupWardController.text.trim();
      _formData.pickupRoomBed = _pickupRoomBedController.text.trim();
      _formData.dropoffWard = _dropoffWardController.text.trim();
      _formData.dropoffRoomBed = _dropoffRoomBedController.text.trim();
      _formData.budget = _budgetController.text.trim();
      _formData.itemName = _itemNameController.text.trim();
      _formData.itemQuantity = _itemQuantityController.text.trim();
      _formData.itemSpecialInstructions = _itemInstructionsController.text.trim();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientTaskConfirmScreen(formData: _formData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: CareDropTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Task',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. INLINE TASK TYPE SELECTOR HEADER
              const Text(
                'SELECT TASK TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _taskTypeOptions.length,
                  itemBuilder: (context, index) {
                    final optionName = _taskTypeOptions[index];
                    final isSelected = _formData.taskType == optionName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text(
                          optionName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : CareDropTheme.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: CareDropTheme.royalBlue,
                        backgroundColor: Colors.white,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _formData.taskType = optionName;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 2. TASK DETAILS & DESCRIPTION
              _buildSectionHeader('1. TASK DETAILS & DESCRIPTION'),
              const SizedBox(height: 8),
              _buildCard([
                _buildTextField(
                  label: 'Task Description *',
                  controller: _descriptionController,
                  required: true,
                  maxLines: 3,
                  hintText: 'Explain what the helper needs to do...',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Additional Instructions (Optional)',
                  controller: _addInstructionsController,
                  maxLines: 2,
                  hintText: 'e.g. Contact upon arrival',
                ),
              ]),

              const SizedBox(height: 20),

              // 3. PICKUP LOCATION WITH MAP BUTTON
              _buildSectionHeader('2. PICKUP / SERVICE LOCATION'),
              const SizedBox(height: 8),
              _buildCard([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Hospital / Location Name *',
                            controller: _pickupHospitalController,
                            required: true,
                            hintText: 'Type address or search location...',
                            onChanged: (val) => _onLocationSearchChanged(val, isPickup: true),
                          ),
                          if (_isSearchingPickup)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          if (_pickupSearchResults.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: CareDropTheme.cardBorderColor),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              constraints: const BoxConstraints(maxHeight: 180),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _pickupSearchResults.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final res = _pickupSearchResults[index];
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    leading: const Icon(Icons.location_on_outlined, size: 18, color: CareDropTheme.royalBlue),
                                    title: Text(res.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    subtitle: Text(res.formattedAddress, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    onTap: () => _selectLocationResult(res, isPickup: true),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: IconButton(
                        icon: const Icon(Icons.map, color: CareDropTheme.royalBlue),
                        tooltip: 'Select on Map',
                        onPressed: () => _openMapPicker(isPickup: true),
                      ),
                    ),
                  ],
                ),
                if (_formData.pickupLat != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Map location pinned (${_formData.pickupLat?.toStringAsFixed(4)}, ${_formData.pickupLng?.toStringAsFixed(4)})',
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Building / Department',
                  controller: _pickupBuildingController,
                  hintText: 'e.g. Main OPD / Pharmacy Counter',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Ward / Section',
                        controller: _pickupWardController,
                        hintText: 'e.g. Ward 4',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Room / Bed / Counter',
                        controller: _pickupRoomBedController,
                        hintText: 'e.g. Bed 12 / Desk A',
                      ),
                    ),
                  ],
                ),
              ]),

              // 4. DROP-OFF LOCATION (CONDITIONALLY SHOWN)
              if (_requiresDropoff) ...[
                const SizedBox(height: 20),
                _buildSectionHeader('3. DROP-OFF LOCATION'),
                const SizedBox(height: 8),
                _buildCard([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              label: 'Drop-off Ward / Address *',
                              controller: _dropoffWardController,
                              required: true,
                              hintText: 'Type address or search location...',
                              onChanged: (val) => _onLocationSearchChanged(val, isPickup: false),
                            ),
                            if (_isSearchingDropoff)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            if (_dropoffSearchResults.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: CareDropTheme.cardBorderColor),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: _dropoffSearchResults.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final res = _dropoffSearchResults[index];
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      leading: const Icon(Icons.location_on_outlined, size: 18, color: CareDropTheme.royalBlue),
                                      title: Text(res.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      subtitle: Text(res.formattedAddress, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      onTap: () => _selectLocationResult(res, isPickup: false),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: IconButton(
                          icon: const Icon(Icons.map, color: CareDropTheme.royalBlue),
                          tooltip: 'Select on Map',
                          onPressed: () => _openMapPicker(isPickup: false),
                        ),
                      ),
                    ],
                  ),
                  if (_formData.dropoffLat != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Map location pinned (${_formData.dropoffLat?.toStringAsFixed(4)}, ${_formData.dropoffLng?.toStringAsFixed(4)})',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Room / Bed / Desk Number',
                    controller: _dropoffRoomBedController,
                    hintText: 'e.g. Room 204',
                  ),
                ]),
              ],

              // 5. ITEM DETAILS (CONDITIONALLY SHOWN)
              if (_requiresItemDetails) ...[
                const SizedBox(height: 20),
                _buildSectionHeader('ITEM DETAILS'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildTextField(
                    label: 'Item / Medicine Name',
                    controller: _itemNameController,
                    hintText: 'e.g. Paracetamol 500mg',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Quantity',
                          controller: _itemQuantityController,
                          hintText: 'e.g. 2 Packets',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Special Notes',
                          controller: _itemInstructionsController,
                          hintText: 'e.g. Keep chilled',
                        ),
                      ),
                    ],
                  ),
                ]),
              ],

              // 6. ATTACHMENTS (CONDITIONALLY SHOWN)
              if (_requiresAttachment) ...[
                const SizedBox(height: 20),
                _buildSectionHeader('ATTACHMENT (PRESCRIPTION / DOC)'),
                const SizedBox(height: 8),
                _buildCard([
                  InkWell(
                    onTap: _showDocumentPickerOptions,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CareDropTheme.cardBorderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_outlined, color: CareDropTheme.royalBlue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formData.attachmentFileName ?? 'Attach Prescription or Document (PDF / Image)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _formData.attachmentFileName != null
                                    ? CareDropTheme.textPrimary
                                    : CareDropTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_formData.attachmentFileName != null)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                              onPressed: () {
                                setState(() {
                                  _formData.attachmentFileName = null;
                                  _formData.attachmentUrl = null;
                                  _formData.localAttachmentPath = null;
                                  _formData.attachmentBytes = null;
                                });
                              },
                            )
                          else
                            TextButton.icon(
                              onPressed: _showDocumentPickerOptions,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Select'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],


              const SizedBox(height: 20),

              // 7. SCHEDULE & PRIORITY
              _buildSectionHeader('SCHEDULE & PRIORITY'),
              const SizedBox(height: 8),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('ASAP')),
                        selected: _formData.isAsap,
                        selectedColor: CareDropTheme.royalBlue,
                        labelStyle: TextStyle(
                          color: _formData.isAsap ? Colors.white : CareDropTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _formData.isAsap = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Schedule Later')),
                        selected: !_formData.isAsap,
                        selectedColor: CareDropTheme.royalBlue,
                        labelStyle: TextStyle(
                          color: !_formData.isAsap ? Colors.white : CareDropTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _formData.isAsap = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (!_formData.isAsap) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            '${_formData.scheduledDate.day}/${_formData.scheduledDate.month}/${_formData.scheduledDate.year}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(
                            _formData.scheduledTime.format(context),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Normal', 'Urgent'].map((priority) {
                    final isSel = _formData.priority == priority;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Center(child: Text(priority)),
                          selected: isSel,
                          selectedColor: priority == 'Urgent'
                              ? const Color(0xFFEF4444)
                              : CareDropTheme.royalBlue,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : CareDropTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _formData.priority = priority;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 20),

              // 8. BUDGET AMOUNT & PAYMENT
              _buildSectionHeader('OFFER BUDGET & PAYMENT'),
              const SizedBox(height: 8),
              _buildCard([
                _buildTextField(
                  label: 'Offered Budget (LKR)',
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  hintText: 'e.g. 250',
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Cash', 'Online Payment'].map((method) {
                    final isSel = _formData.paymentMethod == method;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Center(child: Text(method)),
                          selected: isSel,
                          selectedColor: CareDropTheme.royalBlue,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : CareDropTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _formData.paymentMethod = method;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 28),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                  ),
                  onPressed: _submitForm,
                  child: const Text(
                    'Review & Post Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: CareDropTheme.royalBlue,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CareDropTheme.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: CareDropTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
