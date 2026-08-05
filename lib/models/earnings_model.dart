class EarningsItem {
  final String id;
  final String title;
  final String timeStr;
  final String currency;
  final double amount;
  final bool isPending;

  EarningsItem({
    required this.id,
    required this.title,
    required this.timeStr,
    required this.currency,
    required this.amount,
    required this.isPending,
  });
}
