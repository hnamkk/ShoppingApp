import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../screens/home/product_detail_screen.dart';
import '../services/cart_service.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Future<void> _addToCart() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final currentQuantity = cartService.items[widget.product.id]?.quantity ?? 0;

    if (currentQuantity >= widget.product.stock) {
      return;
    }

    await cartService.addItem(
      widget.product.id,
      widget.product.name,
      widget.product.price,
      widget.product.primaryImage,
    );
  }

  Future<void> _updateQuantity(CartService cartService, int newQuantity) async {
    if (newQuantity > widget.product.stock) {
      return;
    }

    await cartService.updateQuantity(widget.product.id, newQuantity);
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat("#,###", "vi_VN");
    final cartService = Provider.of<CartService>(context);
    final cartItem = cartService.items[widget.product.id];
    final quantity = cartItem?.quantity ?? 0;
    final hasInCart = quantity > 0;

    return GestureDetector(
      onTap: widget.onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailScreen(productId: widget.product.id),
              ),
            );
          },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.product.primaryImage,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image,
                            size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
                if (widget.product.featured)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatCurrency.format(widget.product.price)}đ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã bán: ${widget.product.sold}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasInCart) ...[
                              GestureDetector(
                                onTap: () async {
                                  if (quantity > 0) {
                                    await _updateQuantity(
                                        cartService, quantity - 1);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.remove, size: 18),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            GestureDetector(
                              onTap: _addToCart,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: quantity >= widget.product.stock
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
