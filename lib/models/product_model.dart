class Product {
  final String id;
  final String name;
  final double price;
  final int sold;
  final int stock;
  final String category;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final bool featured;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.sold,
    required this.stock,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.featured,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> images = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      images = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty) {
      images = [data['imageUrl']];
    }

    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      sold: data['sold'] ?? 0,
      stock: data['stock'] ?? 0,
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? (images.isNotEmpty ? images[0] : ''),
      imageUrls: images,
      featured: data['featured'] ?? false,
    );
  }

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls[0] : imageUrl;
}
