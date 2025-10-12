import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../services/cart_service.dart';
import '../../services/firestore_pagination.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'Tất cả';
  int _currentSlide = 0;
  bool _isSwitchingCategory = false;

  late FirestorePagination<Product> _pagination;
  final ScrollController _scrollController = ScrollController();

  final List<String> bannerImages = [
    'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800',
    'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800',
    'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800',
  ];

  final List<String> categories = [
    'Tất cả',
    'Thịt sạch',
    'Bánh kẹo',
    'Rau củ quả',
    'Sữa và chế phẩm từ sữa',
  ];

  @override
  void initState() {
    super.initState();
    _initializePagination();
    _scrollController.addListener(_onScroll);
  }

  void _initializePagination() {
    Query query = FirebaseFirestore.instance.collection('products');

    if (selectedCategory == 'Tất cả') {
      query = query.orderBy('createdAt', descending: true);
    } else {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    _pagination = FirestorePagination<Product>(
      query: query,
      fromFirestore: (data, id) {
        final product = Product.fromFirestore(data, id);
        return product;
      },
      pageSize: 10,
      filterCondition: (product) => product.stock > 0,
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await _pagination.loadMore();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_pagination.isLoading && _pagination.hasMore) {
      try {
        await _pagination.loadMore();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error loading more: $e');
      }
    }
  }

  Future<void> _onCategoryChanged(String category) async {
    if (_isSwitchingCategory) return;

    setState(() {
      _isSwitchingCategory = true;
      selectedCategory = category;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _pagination.clear();

    Query query = FirebaseFirestore.instance
        .collection('products')
        .where('stock', isGreaterThan: 0);

    if (selectedCategory != 'Tất cả') {
      query = query.where('category', isEqualTo: selectedCategory);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    _pagination = FirestorePagination<Product>(
      query: query,
      fromFirestore: (data, id) => Product.fromFirestore(data, id),
      pageSize: 10,
    );

    try {
      await _pagination.loadMore();
    } catch (e) {
      debugPrint('Error switching category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đổi danh mục: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSwitchingCategory = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _categoryToAssetPath(String categoryName) {
    final cleanName = removeDiacritics(
      categoryName.toLowerCase().replaceAll(' ', '-'),
    );
    return 'assets/images/category/$cleanName.png';
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _pagination.refresh();
          if (mounted) setState(() {});
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      viewportFraction: 0.9,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 8),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 1500),
                      enlargeCenterPage: true,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentSlide = index;
                        });
                      },
                    ),
                    items: bannerImages.map((imageUrl) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.green[100]),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 20,
                              top: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Giảm đến 30%',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Gì cũng rẻ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Mua ngay',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              top: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(15)),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: 180,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bannerImages.asMap().entries.map((entry) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentSlide == entry.key
                              ? Colors.green
                              : Colors.grey[300],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return GestureDetector(
                      onTap: () => _onCategoryChanged(category),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green[50]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  _categoryToAssetPath(category),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? Colors.green : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_isSwitchingCategory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_pagination.isEmpty && !_pagination.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Không có sản phẩm'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _pagination.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _pagination.items.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProductCard(product: _pagination.items[index]),
                      );
                    } else {
                      if (_pagination.hasMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else {
                        return const SizedBox(height: 16);
                      }
                    }
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
