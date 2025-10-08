import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../services/cart_service.dart';
import '../../widgets/product_card.dart';
import '../home/cart_screen.dart';
import '../home/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim().toLowerCase();

    if (trimmedQuery.isEmpty) {
      setState(() {
        _products = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = trimmedQuery;
    });

    try {
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: trimmedQuery)
          .where('stock', isGreaterThan: 0)
          .get();

      List<Product> categoryProducts = categorySnapshot.docs
          .map((doc) => Product.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      QuerySnapshot tagsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('tags', arrayContains: trimmedQuery)
          .where('stock', isGreaterThan: 0)
          .get();

      List<Product> tagProducts = tagsSnapshot.docs
          .map((doc) => Product.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      QuerySnapshot allSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('stock', isGreaterThan: 0)
          .limit(100)
          .get();

      List<Product> filteredProducts = allSnapshot.docs
          .map((doc) => Product.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((product) {
        final nameLower = product.name.toLowerCase();
        final descLower = product.description.toLowerCase();
        final categoryLower = product.category.toLowerCase();

        return nameLower.contains(trimmedQuery) ||
            descLower.contains(trimmedQuery) ||
            categoryLower.contains(trimmedQuery);
      }).toList();

      final allProducts = [
        ...categoryProducts,
        ...tagProducts,
        ...filteredProducts
      ];
      final uniqueProducts = <String, Product>{};

      for (var product in allProducts) {
        uniqueProducts[product.id] = product;
      }

      setState(() {
        _products = uniqueProducts.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey[400]!,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.asset(
                  'assets/images/search.png',
                  width: 20,
                  height: 20,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  onSubmitted: _performSearch,
                  onChanged: (value) {
                    if (value.length >= 2) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value &&
                            value.length >= 2) {
                          _performSearch(value);
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _products = [];
                  _searchQuery = '';
                });
              },
            ),
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
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              if (cartService.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/search.png',
              width: 100,
              height: 100,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Tìm kiếm sản phẩm',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập từ khóa để tìm kiếm',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.green,
      ));
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          width: double.infinity,
          child: Text(
            'Tìm thấy ${_products.length} sản phẩm',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: product.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.green[50],
        labelStyle: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
