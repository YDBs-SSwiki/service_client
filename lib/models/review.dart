// lib/models/review.dart

class Review {
  final int reviewId;
  final int breadId;
  final int userId;
  final int rating;
  final String content;
  final int? likes;   // 좋아요 수
  final bool? liked;  // 사용자가 좋아요 눌렀는지 여부
  final String? createdAt;

  Review({
    required this.reviewId,
    required this.breadId,
    required this.userId,
    required this.rating,
    required this.content,
    this.likes,
    this.liked,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) {
    return Review(
      reviewId: j['reviewId'],
      breadId: j['breadId'] ?? 0,
      userId: j['userId'] ?? 0,
      rating: j['rating'] ?? 0,
      content: j['content'] ?? '',
      likes: j['likes'],
      liked: j['liked'],
      createdAt: j['createdAt'],
    );
  }
}
