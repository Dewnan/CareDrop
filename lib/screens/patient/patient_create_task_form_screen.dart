import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/task_creation_form_data.dart';
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

  /// Captures an image from the device camera or photo library using ImagePicker.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _formData.attachmentFileName = image.name;
          _formData.localAttachmentPath = image.path;
          _formData.attachmentBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  /// Opens the device document picker to select PDF or image files.
  Future<void> _pickDocument() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        final filePath = file.path;
        dynamic fileBytes;
        if (filePath != null && filePath.isNotEmpty) {
          try {
            fileBytes = await File(filePath).readAsBytes();
          } catch (_) {}
        }
        setState(() {
          _formData.attachmentFileName = file.name;
          _formData.localAttachmentPath = filePath;
          _formData.attachmentBytes = fileBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select document: $e')),
        );
      }
    }
  }

  /// Displays a modal bottom sheet for choosing between camera, photo library, or document files.
  void _showDocumentPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: CareDropTheme.royalBlue),
              title: const Text('Choose Document (PDF / File)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: CareDropTheme.royalBlue),
              title: const Text('Take a Photo (Camera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: CareDropTheme.royalBlue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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

  // Simulate opening map picker dialog for pickup or dropoff location
  void _openMapPicker({required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPickup ? 'Select Pickup Location on Map' : 'Select Drop-off Location on Map',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Map preview placeholder card
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CareDropTheme.royalBlue.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.location_on, color: CareDropTheme.royalBlue, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Map Location Picker',
                        style: TextStyle(fontWeight: FontWeight.bold, color: CareDropTheme.royalBlue),
                      ),
                      Text(
                        'Tap to set precise GPS pin',
                        style: TextStyle(fontSize: 12, color: CareDropTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPickup) {
                        _formData.pickupLat = 6.9271;
                        _formData.pickupLng = 79.8612;
                        if (_pickupHospitalController.text.isEmpty) {
                          _pickupHospitalController.text = 'Pickup Point (Selected via Map)';
                        }
                      } else {
                        _formData.dropoffLat = 6.9275;
                        _formData.dropoffLng = 79.8618;
                        if (_dropoffWardController.text.isEmpty) {
                          _dropoffWardController.text = 'Drop off Point (Selected via Map)';
                        }
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirm Location Pin'),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Hospital / Location Name *',
                        controller: _pickupHospitalController,
                        required: true,
                        hintText: 'e.g. National Hospital / Pharmacy Name',
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.map, color: CareDropTheme.royalBlue),
                      tooltip: 'Select on Map',
                      onPressed: () => _openMapPicker(isPickup: true),
                    ),
                  ],
                ),
                if (_formData.pickupLat != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Map location pinned (${_formData.pickupLat?.toStringAsFixed(4)}, ${_formData.pickupLng?.toStringAsFixed(4)})',
                        style: const TextStyle(fontSize: 11, color: Colors.green),
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
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Drop-off Ward / Address *',
                          controller: _dropoffWardController,
                          required: true,
                          hintText: 'e.g. Discharge Counter / Home Address',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.map, color: CareDropTheme.royalBlue),
                        tooltip: 'Select on Map',
                        onPressed: () => _openMapPicker(isPickup: false),
                      ),
                    ],
                  ),
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
