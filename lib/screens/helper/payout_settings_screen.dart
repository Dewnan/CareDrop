import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../components/feedback_banner.dart';
import '../../components/loading_indicator.dart';
import '../../models/payout_model.dart';
import '../../providers/app_state.dart';
import '../../services/payout_service.dart';
import '../../theme/app_theme.dart';

/// Screen enabling helpers to configure and update their bank account details for direct payout transfers
class PayoutSettingsScreen extends StatefulWidget {
  const PayoutSettingsScreen({super.key});

  @override
  State<PayoutSettingsScreen> createState() => _PayoutSettingsScreenState();
}

class _PayoutSettingsScreenState extends State<PayoutSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _branchController = TextEditingController();
  final _branchCodeController = TextEditingController();

  String _selectedBank = 'Commercial Bank';
  final List<String> _bankOptions = [
    'Commercial Bank',
    'Sampath Bank',
    'Bank of Ceylon (BOC)',
    'Hatton National Bank (HNB)',
    'People\'s Bank',
    'Nations Trust Bank (NTB)',
    'Seylan Bank',
    'DFCC Bank',
    'Union Bank',
    'National Savings Bank (NSB)',
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingBankDetails();
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _branchController.dispose();
    _branchCodeController.dispose();
    super.dispose();
  }

  /// Loads previously saved bank account credentials from Firestore
  Future<void> _loadExistingBankDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ??
        context.read<CareDropAppState>().currentUserModel?.id;

    if (uid != null && uid.isNotEmpty) {
      final existing = await PayoutService.getBankDetails(uid);
      if (existing != null && mounted) {
        setState(() {
          if (_bankOptions.contains(existing.bankName)) {
            _selectedBank = existing.bankName;
          }
          _holderController.text = existing.accountHolderName;
          _accountController.text = existing.accountNumber;
          _branchController.text = existing.branchName;
          _branchCodeController.text = existing.branchCode ?? '';
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Submits and saves bank details to helper profile
  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ??
        context.read<CareDropAppState>().currentUserModel?.id;

    if (uid == null || uid.isEmpty) {
      FeedbackBanner.show(
        context,
        message: 'User authentication required.',
        type: FeedbackType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    final details = BankDetailsModel(
      bankName: _selectedBank,
      accountHolderName: _holderController.text.trim(),
      accountNumber: _accountController.text.trim(),
      branchName: _branchController.text.trim(),
      branchCode: _branchCodeController.text.trim(),
    );

    final success = await PayoutService.saveBankDetails(
      helperId: uid,
      bankDetails: details,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        FeedbackBanner.show(
          context,
          message: 'Bank payout details updated successfully!',
          type: FeedbackType.success,
        );
        Navigator.pop(context, true);
      } else {
        FeedbackBanner.show(
          context,
          message: 'Failed to update bank details. Please try again.',
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payout Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CareDropTheme.normalBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator(size: 32))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CareDropTheme.royalBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              color: CareDropTheme.royalBlue,
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bank Payout Credentials',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: CareDropTheme.royalBlue,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Direct transfers are deposited into your registered bank account upon withdrawal request. Ensure account holder matches your legal name.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CareDropTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bank Name Selection
                      const Text(
                        'Select Bank',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CareDropTheme.cardBorderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBank,
                            isExpanded: true,
                            items: _bankOptions.map((bank) {
                              return DropdownMenuItem<String>(
                                value: bank,
                                child: Text(
                                  bank,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: CareDropTheme.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBank = val);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Account Holder Name
                      const Text(
                        'Account Holder Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _holderController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Perera A.B.C.',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: CareDropTheme.royalBlue),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Account holder name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Account Number
                      const Text(
                        'Account Number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. 8001234567',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: CareDropTheme.royalBlue),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Account number is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Branch Name & Code Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Branch Name',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: CareDropTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _branchController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Colombo Fort',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: CareDropTheme.royalBlue),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Branch name required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Branch Code',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: CareDropTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _branchCodeController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 001',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: CareDropTheme.cardBorderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: CareDropTheme.royalBlue),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CareDropTheme.royalBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveBankDetails,
                          child: _isSaving
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppLoadingIndicator(size: 20, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      'Saving Details...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Save Bank Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
