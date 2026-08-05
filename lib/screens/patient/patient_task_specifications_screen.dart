import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'patient_task_confirm_screen.dart';

class PatientTaskSpecificationsScreen extends StatefulWidget {
  final String taskTypeName;
  const PatientTaskSpecificationsScreen({super.key, required this.taskTypeName});

  @override
  State<PatientTaskSpecificationsScreen> createState() => _PatientTaskSpecificationsScreenState();
}

class _PatientTaskSpecificationsScreenState extends State<PatientTaskSpecificationsScreen> {
  String _selectedLanguage = 'Sinhala';
  String _selectedGender = 'Any';

  final List<String> _languages = ['Sinhala', 'Tamil', 'English'];
  final List<String> _genders = ['Any', 'Female', 'Male'];

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
          'Preferences',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LANGUAGE SECTION
              const Text(
                'LANGUAGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _languages.map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? CareDropTheme.tealPrimary : CareDropTheme.cardBorderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        lang,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedLanguage = lang;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // GENDER SECTION
              const Text(
                'GENDER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _genders.map((gender) {
                  final isSelected = _selectedGender == gender;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGender = gender;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? CareDropTheme.tealPrimary : CareDropTheme.cardBorderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              gender,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? CareDropTheme.tealPrimary : CareDropTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // REVIEW & CONFIRM BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.tealPrimary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientTaskConfirmScreen(
                          taskTypeName: widget.taskTypeName,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Review & Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
