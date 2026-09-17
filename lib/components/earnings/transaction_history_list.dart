import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import '../../models/payout_model.dart';
import '../../theme/app_theme.dart';

/// Renders a unified list of task payments and payout requests
class TransactionHistoryList extends StatelessWidget {
  final List<PayoutModel> payouts;
  final List<PaymentModel> payments;

  const TransactionHistoryList({
    super.key,
    required this.payouts,
    required this.payments,
  });

  /// Formats a DateTime instance into a readable date string
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Payout Requests
        ...payouts.map((po) {
          final dateStr = _formatDateTime(po.createdAt);
          final isDone = po.status == PayoutStatus.completed;
          final isReject = po.status == PayoutStatus.rejected;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CareDropTheme.cardBorderColor),
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
                    borderRadius: BorderRadius.circular(10),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '- ${po.currency} ${po.amount.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isReject ? Colors.red : CareDropTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFFDCFCE7)
                            : isReject
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
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
          final isReleased = p.status == PaymentStatus.released;
          final isCash = p.paymentMethod.toLowerCase().contains('cash');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CareDropTheme.cardBorderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isReleased ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCash ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: isReleased ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCash ? 'Cash Collection Task' : 'Online Escrow Payment',
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+ ${p.currency} ${p.netHelperAmount.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isReleased ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isReleased ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isReleased ? 'RELEASED' : p.status.name.toUpperCase(),
                        style: TextStyle(
                          color: isReleased ? const Color(0xFF15803D) : const Color(0xFFB45309),
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
    );
  }
}
