// lib/models/review.dart

class Review {
  final int reviewId;
  final int breadId;
  final int userId;
  final int rating;
  final String content;
  final int? likes;    // 좋아요 수
  final bool? liked;   // 내가 좋아요 눌렀는지 여부 (서버 응답)
  final String? createdAt;
  final String? imageUrl;  // ← 추가: 리뷰 이미지 URL

  Review({
    required this.reviewId,
    required this.breadId,
    required this.userId,
    required this.rating,
    required this.content,
    this.likes,
    this.liked,
    this.createdAt,
    this.imageUrl,
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
      imageUrl: j['imageUrl'], // ← 서버 응답에 imageUrl 있으면 파싱
    );
  }
}
