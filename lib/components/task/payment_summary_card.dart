import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'task_price_row.dart';

class PaymentSummaryCard extends StatelessWidget {
  final double baseFee;
  final String paymentMethod;
  final double platformFee;
  final double totalFee;
  final bool isCashPayment;

  const PaymentSummaryCard({
    super.key,
    required this.baseFee,
    required this.paymentMethod,
    required this.platformFee,
    required this.totalFee,
    required this.isCashPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CareDropTheme.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: CareDropTheme.royalBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          TaskPriceRow(
            label: 'Offered Budget',
            price: 'LKR ${baseFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          TaskPriceRow(label: 'Payment Method', price: paymentMethod),
          const SizedBox(height: 8),
          TaskPriceRow(
            label: 'Service Platform Fee',
            price: isCashPayment
                ? 'LKR 0.00 (Cash)'
                : 'LKR ${platformFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'LKR ${totalFee.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: CareDropTheme.royalBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
