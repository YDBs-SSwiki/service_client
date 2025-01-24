// lib/models/bread.dart
class Bread {
  final int breadId;
  final String name;
  final String detail;
  final String? imageUrl;
  final int price;

  Bread({
    required this.breadId,
    required this.name,
    required this.detail,
    required this.price,
    this.imageUrl,
  });

  factory Bread.fromJson(Map<String,dynamic> j) => Bread(
    breadId: j['breadId'],
    name: j['name'],
    detail: j['detail'] ?? '',
    price: j['price'] ?? 0,
    imageUrl: j['imageUrl'],
  );
}
