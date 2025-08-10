import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _reviewsCollection = 'reviews';

  // Create a review
  Future<String> createReview({
    required String requestId,
    required String responseId,
    required String revieweeId,
    required ReviewType type,
    required double rating,
    required String comment,
    List<String> tags = const [],
    bool isPublic = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final reviewId = _firestore.collection(_reviewsCollection).doc().id;
      
      final review = ReviewModel(
        id: reviewId,
        requestId: requestId,
        responseId: responseId,
        reviewerId: user.uid,
        revieweeId: revieweeId,
        type: type,
        rating: rating,
        comment: comment,
        tags: tags,
        createdAt: DateTime.now(),
        isPublic: isPublic,
      );

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .set(review.toMap());

      // Update user's rating statistics
      await _updateUserRating(revieweeId);

      return reviewId;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Get reviews for a user
  Future<List<ReviewModel>> getUserReviews(String userId, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('revieweeId', isEqualTo: userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reviews: $e');
    }
  }

  // Get reviews for a request
  Future<List<ReviewModel>> getRequestReviews(String requestId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('requestId', isEqualTo: requestId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get request reviews: $e');
    }
  }

  // Check if user has already reviewed
  Future<bool> hasUserReviewed({
    required String requestId,
    required String responseId,
    required String reviewerId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('requestId', isEqualTo: requestId)
          .where('responseId', isEqualTo: responseId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user's average rating
  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('revieweeId', isEqualTo: userId)
          .where('isPublic', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': <int, int>{},
        };
      }

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();

      double totalRating = 0;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final review in reviews) {
        totalRating += review.rating;
        final roundedRating = review.rating.round();
        ratingDistribution[roundedRating] = (ratingDistribution[roundedRating] ?? 0) + 1;
      }

      return {
        'averageRating': totalRating / reviews.length,
        'totalReviews': reviews.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': <int, int>{},
      };
    }
  }

  // Update user's rating statistics in their profile
  Future<void> _updateUserRating(String userId) async {
    try {
      final stats = await getUserRatingStats(userId);
      
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'rating': stats['averageRating'],
        'totalReviews': stats['totalReviews'],
        'ratingDistribution': stats['ratingDistribution'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user rating: $e');
    }
  }

  // Get common review tags
  List<String> getCommonReviewTags(String requestType) {
    final commonTags = <String, List<String>>{
      'service': ['Professional', 'Skilled', 'On Time', 'Quality Work', 'Friendly', 'Reliable'],
      'delivery': ['Fast', 'Careful', 'On Time', 'Professional', 'Safe', 'Communicative'],
      'ride': ['Safe Driver', 'Clean Vehicle', 'On Time', 'Friendly', 'Comfortable', 'Professional'],
      'rental': ['Good Condition', 'Fair Pricing', 'Flexible', 'Helpful', 'Clean', 'Reliable'],
      'item': ['As Described', 'Good Quality', 'Fair Price', 'Fast Response', 'Trustworthy', 'Helpful'],
    };

    return commonTags[requestType] ?? ['Professional', 'Reliable', 'Helpful', 'On Time', 'Quality'];
  }
}
