import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartItemQuantityWidget extends StatelessWidget {
  final CartItem item;

  const CartItemQuantityWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final isSelected = cartService.selectedItems.contains(item.productId);
    final formatNumber = NumberFormat('#,###', 'vi_VN');

    return FutureBuilder<int>(
      future: cartService.getProductStock(item.productId),
      builder: (context, snapshot) {
        final productStock = snapshot.data ?? 0;
        final hasStockData = snapshot.connectionState == ConnectionState.done;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => cartService.toggleSelection(item.productId),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.image, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${formatNumber.format(item.price)}đ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await cartService.updateQuantity(
                                    item.productId,
                                    item.quantity - 1,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  child: const Icon(Icons.remove, size: 18),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final newQty = await showDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      final controller = TextEditingController(
                                        text: item.quantity.toString(),
                                      );
                                      return AlertDialog(
                                        title: const Text('Nhập số lượng'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: controller,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                hintText: 'Số lượng',
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Hủy'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              final qty = int.tryParse(
                                                    controller.text
                                                        .replaceAll(',', ''),
                                                  ) ??
                                                  item.quantity;
                                              Navigator.pop(context, qty);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (newQty != null &&
                                      newQty != item.quantity) {
                                    final validQty =
                                        hasStockData && newQty > productStock
                                            ? productStock
                                            : newQty;

                                    await cartService.updateQuantity(
                                      item.productId,
                                      validQty,
                                    );
                                  }
                                },
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 40),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  alignment: Alignment.center,
                                  child: Text(
                                    formatNumber.format(item.quantity),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  if (hasStockData &&
                                      item.quantity >= productStock) {
                                    return;
                                  }

                                  await cartService.addItem(
                                    item.productId,
                                    item.name,
                                    item.price,
                                    item.imageUrl,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: hasStockData &&
                                            item.quantity >= productStock
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
        );
      },
    );
  }
}
