import 'package:flutter/material.dart';
import '../../models/task_creation_form_data.dart';
import '../../theme/app_theme.dart';
import 'patient_task_confirm_screen.dart';

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

  // Controllers
  late TextEditingController _descriptionController;
  late TextEditingController _addInstructionsController;
  late TextEditingController _pickupHospitalController;
  late TextEditingController _pickupBuildingController;
  late TextEditingController _pickupWardController;
  late TextEditingController _pickupRoomBedController;
  late TextEditingController _dropoffWardController;
  late TextEditingController _dropoffRoomBedController;
  late TextEditingController _budgetController;
  late TextEditingController _itemNameController;
  late TextEditingController _itemQuantityController;
  late TextEditingController _itemInstructionsController;

  final List<String> _taskTypes = [
    'Medicine Pickup',
    'Food Pickup',
    'Document Delivery',
    'Queue/Token Assistance',
    'Pharmacy Purchase',
    'Other',
  ];

  final List<String> _languages = ['Sinhala', 'Tamil', 'English'];
  final List<String> _genders = ['No preference', 'Male', 'Female'];
  final List<String> _contactPreferences = ['In-app Chat', 'Phone Call', 'Either'];

  @override
  void initState() {
    super.initState();
    _formData = TaskCreationFormData(
      taskType: _taskTypes.contains(widget.initialTaskType)
          ? widget.initialTaskType
          : 'Medicine Pickup',
      pickupHospital: 'Padukka Base Hospital',
      pickupBuilding: 'Main Block',
      pickupWard: 'Ward 4',
      pickupRoomBed: 'Bed 12',
      dropoffWard: 'Discharge Counter',
      dropoffRoomBed: 'Desk B',
      description: 'Please collect medications as per prescription.',
    );

    _descriptionController =
        TextEditingController(text: _formData.description);
    _addInstructionsController =
        TextEditingController(text: _formData.additionalInstructions);
    _pickupHospitalController =
        TextEditingController(text: _formData.pickupHospital);
    _pickupBuildingController =
        TextEditingController(text: _formData.pickupBuilding);
    _pickupWardController = TextEditingController(text: _formData.pickupWard);
    _pickupRoomBedController =
        TextEditingController(text: _formData.pickupRoomBed);
    _dropoffWardController =
        TextEditingController(text: _formData.dropoffWard);
    _dropoffRoomBedController =
        TextEditingController(text: _formData.dropoffRoomBed);
    _budgetController = TextEditingController(text: _formData.budget ?? '250');
    _itemNameController = TextEditingController(text: _formData.itemName ?? '');
    _itemQuantityController =
        TextEditingController(text: _formData.itemQuantity ?? '');
    _itemInstructionsController =
        TextEditingController(text: _formData.itemSpecialInstructions ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addInstructionsController.dispose();
    _pickupHospitalController.dispose();
    _pickupBuildingController.dispose();
    _pickupWardController.dispose();
    _pickupRoomBedController.dispose();
    _dropoffWardController.dispose();
    _dropoffRoomBedController.dispose();
    _budgetController.dispose();
    _itemNameController.dispose();
    _itemQuantityController.dispose();
    _itemInstructionsController.dispose();
    super.dispose();
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
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
      _formData.itemSpecialInstructions =
          _itemInstructionsController.text.trim();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientTaskConfirmScreen(formData: _formData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: CareDropTheme.textPrimary),
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
            padding: const EdgeInsets.all(20),
            children: [
              // 1. TASK TYPE & DESCRIPTION
              _buildSectionHeader('1. TASK TYPE & DESCRIPTION'),
              const SizedBox(height: 12),
              _buildCard([
                const Text(
                  'Task Type *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _formData.taskType,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: _taskTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _formData.taskType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Task Description *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                  decoration: const InputDecoration(
                    hintText: 'Explain what the helper needs to do in detail...',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Optional Additional Instructions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addInstructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Any extra notes (e.g. handle with care)',
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // 2. PICKUP LOCATION
              _buildSectionHeader('2. PICKUP LOCATION'),
              const SizedBox(height: 12),
              _buildCard([
                _buildTextField(
                  label: 'Hospital Name *',
                  controller: _pickupHospitalController,
                  required: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Building / Department *',
                  controller: _pickupBuildingController,
                  required: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Ward *',
                        controller: _pickupWardController,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Room / Bed Number *',
                        controller: _pickupRoomBedController,
                        required: true,
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 24),

              // 3. DROP-OFF LOCATION
              _buildSectionHeader('3. DROP-OFF LOCATION'),
              const SizedBox(height: 12),
              _buildCard([
                _buildTextField(
                  label: 'Ward / Department *',
                  controller: _dropoffWardController,
                  required: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Room / Bed Number *',
                  controller: _dropoffRoomBedController,
                  required: true,
                ),
              ]),

              const SizedBox(height: 24),

              // 4. DATE & TIME & PRIORITY
              _buildSectionHeader('4. DATE, TIME & PRIORITY'),
              const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
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
                const SizedBox(height: 20),
                const Text(
                  'Priority *',
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

              const SizedBox(height: 24),

              // 5. BUDGET & PAYMENT
              _buildSectionHeader('5. BUDGET & PAYMENT METHOD'),
              const SizedBox(height: 12),
              _buildCard([
                _buildTextField(
                  label: 'Budget Amount (LKR)',
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  hintText: 'e.g. 250',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
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

              const SizedBox(height: 24),

              // 6. ITEM DETAILS & ATTACHMENTS
              _buildSectionHeader('6. ITEM DETAILS & ATTACHMENTS (OPTIONAL)'),
              const SizedBox(height: 12),
              _buildCard([
                _buildTextField(
                  label: 'Item Name',
                  controller: _itemNameController,
                  hintText: 'e.g. Metformin 500mg',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Quantity',
                  controller: _itemQuantityController,
                  hintText: 'e.g. 2 Boxes',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Special Instructions',
                  controller: _itemInstructionsController,
                  hintText: 'e.g. Check expiry date',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Attachment (Prescription / Document)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CareDropTheme.cardBorderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: CareDropTheme.royalBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formData.attachmentFileName ?? 'Prescription_Image.jpg',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _formData.attachmentFileName = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // 7. HELPER PREFERENCES & CONTACT
              _buildSectionHeader('7. HELPER PREFERENCES & CONTACT'),
              const SizedBox(height: 12),
              _buildCard([
                const Text(
                  'Preferred Language',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _languages.map((lang) {
                    final isSel = _formData.preferredLanguage == lang;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Center(child: Text(lang, style: const TextStyle(fontSize: 12))),
                          selected: isSel,
                          selectedColor: CareDropTheme.royalBlue,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : CareDropTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _formData.preferredLanguage = lang;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gender Preference',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _genders.map((gen) {
                    final isSel = _formData.preferredGender == gen;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Center(child: Text(gen, style: const TextStyle(fontSize: 11))),
                          selected: isSel,
                          selectedColor: CareDropTheme.royalBlue,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : CareDropTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _formData.preferredGender = gen;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contact Preference',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _contactPreferences.map((pref) {
                    final isSel = _formData.contactPreference == pref;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Center(child: Text(pref, style: const TextStyle(fontSize: 11))),
                          selected: isSel,
                          selectedColor: CareDropTheme.royalBlue,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : CareDropTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _formData.contactPreference = pref;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 32),

              // REVIEW & SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                  ),
                  onPressed: _submitForm,
                  child: const Text(
                    'Review Task & Confirm',
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
        fontSize: 12,
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
          keyboardType: keyboardType,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
