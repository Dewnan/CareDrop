import 'package:flutter/material.dart';
import '../models/support_ticket_model.dart';
import '../theme/app_theme.dart';

/// Reusable modular widget representing a support ticket list item card with status and priority badges.
class SupportTicketCardTile extends StatelessWidget {
  final SupportTicketModel ticket;
  final VoidCallback onTap;

  const SupportTicketCardTile({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  /// Resolves status background color according to the ticket lifecycle state.
  Color _getStatusBgColor() {
    switch (ticket.status) {
      case 'open':
        return CareDropTheme.pendingBg;
      case 'in_progress':
        return const Color(0xFFE0F2FE);
      case 'resolved':
        return CareDropTheme.paidBg;
      case 'closed':
      default:
        return CareDropTheme.normalBg;
    }
  }

  /// Resolves status text color matching the ticket status design system tokens.
  Color _getStatusTextColor() {
    switch (ticket.status) {
      case 'open':
        return CareDropTheme.pendingText;
      case 'in_progress':
        return const Color(0xFF0369A1);
      case 'resolved':
        return CareDropTheme.paidText;
      case 'closed':
      default:
        return CareDropTheme.normalText;
    }
  }

  /// Formats the raw status string into readable display text.
  String _getStatusText() {
    switch (ticket.status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return ticket.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${ticket.updatedAt.day}/${ticket.updatedAt.month}/${ticket.updatedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CareDropTheme.cardBorderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusTextColor(),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: CareDropTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CareDropTheme.normalBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.categoryDisplay,
                      style: const TextStyle(
                        color: CareDropTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (ticket.relatedTaskId != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Task #${ticket.relatedTaskId}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CareDropTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
