// lib/models/review.dart
class Review {
  final int reviewId;
  final int userId;
  final int breadId;
  final int rating;
  final String content;
  final int likes;

  Review({
    required this.reviewId,
    required this.userId,
    required this.breadId,
    required this.rating,
    required this.content,
    required this.likes,
  });

  factory Review.fromJson(Map<String,dynamic> j) => Review(
    reviewId: j['reviewId'],
    userId: j['userId'],
    breadId: j['breadId'],
    rating: j['rating'] ?? 0,
    content: j['content'] ?? '',
    likes: j['likes'] ?? 0,
  );
}
