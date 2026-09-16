import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../components/feedback_banner.dart';
import '../../components/loading_indicator.dart';
import '../../models/payment_model.dart';
import '../../models/payout_model.dart';
import '../../providers/app_state.dart';
import '../../services/payment_service.dart';
import '../../services/payout_service.dart';
import '../../theme/app_theme.dart';
import 'payout_settings_screen.dart';

/// Renders the helper earnings dashboard, streaming real-time payments, wallet balance, and payout withdrawal management
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  /// Opens modal sheet to enter withdrawal amount and submit payout request
  Future<void> _showRequestPayoutModal(
    BuildContext context, {
    required String helperId,
    required double availableBalance,
  }) async {
    final bankDetails = await PayoutService.getBankDetails(helperId);

    if (!context.mounted) return;

    if (bankDetails == null || !bankDetails.isComplete) {
      FeedbackBanner.show(
        context,
        message: 'Please set up your Bank Details before requesting a payout.',
        type: FeedbackType.error,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PayoutSettingsScreen()),
      );
      return;
    }

    if (availableBalance < PayoutService.minPayoutThreshold) {
      FeedbackBanner.show(
        context,
        message:
            'Minimum withdrawal threshold is LKR ${PayoutService.minPayoutThreshold.toStringAsFixed(0)}.',
        type: FeedbackType.error,
      );
      return;
    }

    final amountController = TextEditingController(
      text: availableBalance.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Request Payout Withdrawal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Destination Bank Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CareDropTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CareDropTheme.cardBorderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance,
                              color: CareDropTheme.royalBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bankDetails.bankName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: CareDropTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${bankDetails.accountHolderName} · ${bankDetails.accountNumber}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: CareDropTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Withdrawal Amount (LKR)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: CareDropTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CareDropTheme.royalBlue,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'LKR ',
                        filled: true,
                        fillColor: CareDropTheme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: CareDropTheme.cardBorderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: CareDropTheme.cardBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: CareDropTheme.royalBlue),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter withdrawal amount';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed < PayoutService.minPayoutThreshold) {
                          return 'Minimum withdrawal is LKR ${PayoutService.minPayoutThreshold.toStringAsFixed(0)}';
                        }
                        if (parsed > availableBalance) {
                          return 'Exceeds available balance of LKR ${availableBalance.toStringAsFixed(2)}';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CareDropTheme.royalBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSubmitting = true);

                                try {
                                  final reqAmount = double.parse(
                                      amountController.text.trim());
                                  await PayoutService.requestPayout(
                                    helperId: helperId,
                                    amount: reqAmount,
                                    availableBalance: availableBalance,
                                  );

                                  if (modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                    FeedbackBanner.show(
                                      context,
                                      message:
                                          'Payout request of LKR ${reqAmount.toStringAsFixed(2)} submitted successfully!',
                                      type: FeedbackType.success,
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (modalContext.mounted) {
                                    FeedbackBanner.show(
                                      modalContext,
                                      message: e.toString().replaceAll('Exception: ', ''),
                                      type: FeedbackType.error,
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppLoadingIndicator(
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : const Text(
                                'Confirm Withdrawal Request',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final helperId = FirebaseAuth.instance.currentUser?.uid ??
        appState.currentUserModel?.id ??
        '';

    if (helperId.isEmpty) {
      return const Scaffold(
        backgroundColor: CareDropTheme.backgroundColor,
        body: Center(
          child: Text(
            'Please log in to view earnings.',
            style: TextStyle(color: CareDropTheme.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      body: StreamBuilder<List<PaymentModel>>(
        stream: PaymentService.streamHelperPayments(helperId),
        builder: (context, paymentSnap) {
          return StreamBuilder<List<PayoutModel>>(
            stream: PayoutService.streamHelperPayouts(helperId),
            builder: (context, payoutSnap) {
              final payments = paymentSnap.data ?? [];
              final payouts = payoutSnap.data ?? [];

              // Calculate released online earnings (PayHere / Card) vs escrowed earnings
              double totalReleasedOnline = 0.0;
              double totalEscrowOnline = 0.0;
              double totalMonthlyEarned = 0.0;
              final now = DateTime.now();

              for (final p in payments) {
                final isCurrentMonth = p.createdAt.year == now.year &&
                    p.createdAt.month == now.month;

                if (p.status == PaymentStatus.released) {
                  totalReleasedOnline += p.netHelperAmount;
                  if (isCurrentMonth) {
                    totalMonthlyEarned += p.netHelperAmount;
                  }
                } else if (p.status == PaymentStatus.escrow) {
                  totalEscrowOnline += p.netHelperAmount;
                }
              }

              // Calculate payouts requested or completed
              double totalRequestedPayouts = 0.0;
              for (final po in payouts) {
                if (po.status == PayoutStatus.requested ||
                    po.status == PayoutStatus.processing ||
                    po.status == PayoutStatus.completed) {
                  totalRequestedPayouts += po.amount;
                }
              }

              final availableWalletBalance =
                  (totalReleasedOnline - totalRequestedPayouts) > 0
                      ? totalReleasedOnline - totalRequestedPayouts
                      : 0.0;

              return Column(
                children: [
                  // Top Royal Blue Banner
                  Container(
                    width: double.infinity,
                    color: CareDropTheme.royalBlue,
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Earnings & Wallet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Balance Cards Grid
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Wallet',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'LKR ${availableWalletBalance.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending Escrow',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'LKR ${totalEscrowOnline.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Request Payout Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: CareDropTheme.royalBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.payments_outlined,
                                size: 20, color: CareDropTheme.royalBlue),
                            label: const Text(
                              'Request Payout Withdrawal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: CareDropTheme.royalBlue,
                              ),
                            ),
                            onPressed: () => _showRequestPayoutModal(
                              context,
                              helperId: helperId,
                              availableBalance: availableWalletBalance,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transaction History Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction Activity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'This Month: LKR ${totalMonthlyEarned.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CareDropTheme.royalBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List of Payments and Payout Requests
                  Expanded(
                    child: (paymentSnap.connectionState == ConnectionState.waiting &&
                            payoutSnap.connectionState == ConnectionState.waiting)
                        ? const Center(child: AppLoadingIndicator(size: 28))
                        : (payments.isEmpty && payouts.isEmpty)
                            ? const Center(
                                child: Text(
                                  'No payment or payout transactions recorded yet.',
                                  style: TextStyle(
                                    color: CareDropTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                children: [
                                  // Payout Requests
                                  ...payouts.map((po) {
                                    final dateStr = _formatDateTime(po.createdAt);
                                    final isDone =
                                        po.status == PayoutStatus.completed;
                                    final isReject =
                                        po.status == PayoutStatus.rejected;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: CareDropTheme.cardBorderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isDone
                                                  ? const Color(0xFFDCFCE7)
                                                  : isReject
                                                      ? const Color(0xFFFEE2E2)
                                                      : const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.outbox_rounded,
                                              size: 20,
                                              color: isDone
                                                  ? const Color(0xFF16A34A)
                                                  : isReject
                                                      ? Colors.red
                                                      : const Color(0xFFD97706),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Bank Payout Withdrawal',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: CareDropTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${po.bankDetails.bankName} · $dateStr',
                                                  style: const TextStyle(
                                                    color: CareDropTheme.textMuted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '- ${po.currency} ${po.amount.toInt()}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isReject
                                                      ? Colors.red
                                                      : CareDropTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDone
                                                      ? const Color(0xFFDCFCE7)
                                                      : isReject
                                                          ? const Color(0xFFFEE2E2)
                                                          : const Color(0xFFFEF3C7),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  po.status.name.toUpperCase(),
                                                  style: TextStyle(
                                                    color: isDone
                                                        ? const Color(0xFF15803D)
                                                        : isReject
                                                            ? Colors.red
                                                            : const Color(0xFFB45309),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  // Task Payments
                                  ...payments.map((p) {
                                    final dateStr = _formatDateTime(p.createdAt);
                                    final isReleased =
                                        p.status == PaymentStatus.released;
                                    final isCash = p.paymentMethod
                                        .toLowerCase()
                                        .contains('cash');

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: CareDropTheme.cardBorderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isReleased
                                                  ? const Color(0xFFDCFCE7)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              isCash
                                                  ? Icons.payments_outlined
                                                  : Icons.account_balance_wallet_outlined,
                                              size: 20,
                                              color: isReleased
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFD97706),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isCash
                                                      ? 'Cash Collection Task'
                                                      : 'Online Escrow Payment',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: CareDropTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(
                                                    color: CareDropTheme.textMuted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '+ ${p.currency} ${p.netHelperAmount.toInt()}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isReleased
                                                      ? const Color(0xFF16A34A)
                                                      : const Color(0xFFD97706),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isReleased
                                                      ? const Color(0xFFDCFCE7)
                                                      : const Color(0xFFFEF3C7),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isReleased
                                                      ? 'RELEASED'
                                                      : p.status.name.toUpperCase(),
                                                  style: TextStyle(
                                                    color: isReleased
                                                        ? const Color(0xFF15803D)
                                                        : const Color(0xFFB45309),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Formats a DateTime instance into a readable date string without external dependencies
String _formatDateTime(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final month = months[dt.month - 1];
  final day = dt.day.toString().padLeft(2, '0');
  final year = dt.year;
  final hourNum = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final hour = hourNum.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$month $day, $year · $hour:$minute $period';
}
