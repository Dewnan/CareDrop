import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LocationInfoCard extends StatelessWidget {
  final String pickupAddress;
  final String? dropoffAddress;
  final String? distanceStr;

  const LocationInfoCard({
    super.key,
    required this.pickupAddress,
    this.dropoffAddress,
    this.distanceStr,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: CareDropTheme.royalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup Location',
                      style: TextStyle(
                        color: CareDropTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickupAddress.isNotEmpty ? pickupAddress : 'Not specified',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: CareDropTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dropoffAddress != null && dropoffAddress!.isNotEmpty && dropoffAddress != pickupAddress) ...[
            Padding(
              padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
              child: Container(
                height: 20,
                width: 2,
                color: CareDropTheme.cardBorderColor,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    color: CareDropTheme.royalBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Drop-off Location',
                        style: TextStyle(
                          color: CareDropTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dropoffAddress!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (distanceStr != null) ...[
            const SizedBox(height: 12),
            const Divider(color: CareDropTheme.cardBorderColor, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Distance',
                  style: TextStyle(
                    color: CareDropTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  distanceStr!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: CareDropTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
