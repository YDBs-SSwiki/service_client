// lib/models/bread.dart

class StoreInfo {
  final int storeId;
  final String storeName;
  final String address;
  final String phoneNumber;

  StoreInfo({
    required this.storeId,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> j) => StoreInfo(
    storeId: j['storeId'],
    storeName: j['storeName'],
    address: j['address'],
    phoneNumber: j['phoneNumber'],
  );
}

class Bread {
  final int breadId;
  final String name;
  final String? imageUrl;
  final int? price;
  final String? detail;    // 마크다운
  final int? count;
  final String? createdAt;
  final String? updatedAt;
  final List<StoreInfo>? stores;

  Bread({
    required this.breadId,
    required this.name,
    this.imageUrl,
    this.price,
    this.detail,
    this.count,
    this.createdAt,
    this.updatedAt,
    this.stores,
  });

  factory Bread.fromJson(Map<String, dynamic> j) {
    List<StoreInfo>? storeList;
    if (j['stores'] != null) {
      final arr = j['stores'] as List<dynamic>;
      storeList = arr.map((e) => StoreInfo.fromJson(e)).toList();
    }

    return Bread(
      breadId: j['breadId'],
      name: j['name'],
      imageUrl: j['imageUrl'],
      price: j['price'],
      detail: j['detail'],
      count: j['count'],
      createdAt: j['createdAt'],
      updatedAt: j['updatedAt'],
      stores: storeList,
    );
  }
}
