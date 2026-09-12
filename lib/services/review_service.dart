import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

/// Service managing CRUD operations and real-time streaming for the separate 'reviews' Firestore collection.
class ReviewService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'reviews';

  /// Saves a new patient review document into the 'reviews' collection and updates the helper's average rating in Firestore.
  static Future<String> createReview({
    required String taskId,
    required String reviewerId,
    required String reviewerName,
    required String helperId,
    required double rating,
    String comment = '',
    List<String> tags = const [],
  }) async {
    if (helperId.isEmpty) return '';

    try {
      final docRef = _db.collection(_collection).doc();

      final review = ReviewModel(
        id: docRef.id,
        taskId: taskId,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        helperId: helperId,
        rating: rating,
        comment: comment,
        tags: tags,
      );

      await docRef.set(review.toMap());

      // Update helper average rating in users collection
      _updateHelperAverageRating(helperId);

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating review: $e');
      return '';
    }
  }

  /// Recalculates and updates helper average rating in the 'users' collection.
  static Future<void> _updateHelperAverageRating(String helperId) async {
    try {
      final snapshot = await _db.collection(_collection).where('helperId', isEqualTo: helperId).get();
      if (snapshot.docs.isNotEmpty) {
        final total = snapshot.docs.fold<double>(
          0.0,
          (accumulator, doc) => accumulator + ((doc.data()['rating'] as num?)?.toDouble() ?? 5.0),
        );
        final avg = total / snapshot.docs.length;
        await _db.collection('users').doc(helperId).update({
          'rating': double.parse(avg.toStringAsFixed(1)),
          'reviewCount': snapshot.docs.length,
        });
      }
    } catch (e) {
      debugPrint('Error updating helper average rating: $e');
    }
  }

  /// Streams real-time reviews written for a specific helper user.
  static Stream<List<ReviewModel>> streamHelperReviews(String helperId) {
    if (helperId.isEmpty) return Stream.value([]);
    return _db
        .collection(_collection)
        .where('helperId', isEqualTo: helperId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
