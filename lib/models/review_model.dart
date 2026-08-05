class ReviewItem {
  final String id;
  final String reviewerName;
  final String avatarInitials;
  final double rating;
  final String comment;
  final String dateStr;

  ReviewItem({
    required this.id,
    required this.reviewerName,
    required this.avatarInitials,
    required this.rating,
    required this.comment,
    required this.dateStr,
  });
}
