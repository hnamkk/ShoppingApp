import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../services/cart_service.dart';
import '../../services/favorite_service.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final formatCurrency = NumberFormat("#,###", "vi_VN");

  List<Product>? _similarProducts;
  bool _isLoadingSimilar = false;

  @override
  void initState() {
    super.initState();
    _loadSimilarProducts();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _similarProducts = null;
      _loadSimilarProducts();
    }
  }

  Future<void> _loadSimilarProducts() async {
    if (_isLoadingSimilar) return;
    setState(() => _isLoadingSimilar = true);

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!productDoc.exists) {
        setState(() => _isLoadingSimilar = false);
        return;
      }

      final currentProduct = Product.fromFirestore(
        productDoc.data() as Map<String, dynamic>,
        productDoc.id,
      );

      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: currentProduct.category)
          .limit(10)
          .get();

      final products = querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .where((p) => p.id != currentProduct.id)
          .toList();

      products.shuffle();

      setState(() {
        _similarProducts = products;
      });
    } finally {
      setState(() => _isLoadingSimilar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final favoriteService = Provider.of<FavoriteService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Image.asset(
                  'assets/images/cart.png',
                  width: 26,
                  height: 26,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cartService.itemCount > 0)
                Positioned(
                  right: 5,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = Product.fromFirestore(
              snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

          final isFavorite = favoriteService.isFavorite(product.id);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: ProductImageSlider(
                    imageUrls: product.imageUrls.isNotEmpty
                        ? product.imageUrls
                        : [product.imageUrl],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 28,
                            ),
                            onPressed: () async {
                              await favoriteService.toggleFavorite(product.id);
                              if (!mounted) return;
                            },
                          ),
                        ],
                      ),
                      Text(
                        '${formatCurrency.format(product.price)}đ',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text('Đã bán: ${product.sold}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      const Text('Sản phẩm tương tự',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_isLoadingSimilar)
                        const Center(child: CircularProgressIndicator())
                      else if (_similarProducts == null ||
                          _similarProducts!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                              child: Text('Hiện chưa có sản phẩm tương tự',
                                  style: TextStyle(color: Colors.grey[600]))),
                        )
                      else
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _similarProducts!.length,
                            itemBuilder: (context, index) {
                              final similar = _similarProducts![index];
                              final primaryImage = similar.imageUrls.isNotEmpty
                                  ? similar.imageUrls[0]
                                  : '';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailScreen(
                                                productId: similar.id)),
                                  );
                                },
                                child: Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                        child: Image.network(
                                          primaryImage,
                                          height: 130,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            height: 130,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.image,
                                                size: 40, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 36,
                                              child: Text(
                                                similar.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.3),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                                '${formatCurrency.format(similar.price)}đ',
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.green,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text('Đã bán: ${similar.sold}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text('Mô tả sản phẩm',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Divider(
                          height: 1, thickness: 1, color: Colors.grey),
                      const SizedBox(height: 6),
                      if (product.description.isNotEmpty)
                        Text(product.description,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.6))
                      else
                        Text('Chưa có mô tả cho sản phẩm này.',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic)),
                      const SizedBox(height: 24),
                      const Text('Đảm bảo',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!)),
                        child: Column(
                          children: [
                            _buildGuaranteeItem(
                                icon: Icons.verified_outlined,
                                text: 'Đảm bảo chất lượng sản phẩm'),
                            Divider(height: 1, color: Colors.grey[300]),
                            _buildGuaranteeItem(
                                icon: Icons.local_shipping_outlined,
                                text: 'Giao hàng miễn phí'),
                            Divider(height: 1, color: Colors.grey[300]),
                            _buildGuaranteeItem(
                                icon: Icons.monetization_on_outlined,
                                text: 'Hoàn tiền nếu hàng lỗi'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context, cartService),
    );
  }

  Widget _buildGuaranteeItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartService cartService) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final product = Product.fromFirestore(
            snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, -2))
          ]),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    cartService.addItem(product.id, product.name, product.price,
                        product.primaryImage);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Đã thêm ${product.name} vào giỏ hàng'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.green, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Thêm vào giỏ',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    cartService.addItem(product.id, product.name, product.price,
                        product.primaryImage);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Đặt mua',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductImageSlider extends StatefulWidget {
  final List<String> imageUrls;

  const ProductImageSlider({super.key, required this.imageUrls});

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  int _currentImageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentImageIndex = index),
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          return Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                    child: Icon(Icons.image_not_supported,
                        size: 80, color: Colors.grey)),
              );
            },
          );
        },
      ),
      if (widget.imageUrls.length > 1)
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${_currentImageIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      if (widget.imageUrls.length > 1)
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
