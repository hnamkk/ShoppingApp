import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';

class CartService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, CartItem> _items = {};
  Set<String> _selectedItems = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  CartService() {
    _auth.authStateChanges().listen((user) {
      if (user != null && !_isInitialized) {
        initialize();
      } else if (user == null) {
        reset();
      }
    });
  }

  Map<String, CartItem> get items => _items;

  Set<String> get selectedItems => _selectedItems;

  bool get isLoading => _isLoading;

  bool get isInitialized => _isInitialized;

  int get itemCount => _items.length;

  bool get allSelected =>
      _items.isNotEmpty && _selectedItems.length == _items.length;

  double get totalAmount {
    double total = 0;
    for (var productId in _selectedItems) {
      final item = _items[productId];
      if (item != null) {
        total += item.price * item.quantity;
      }
    }
    return total;
  }

  String? get _userId => _auth.currentUser?.uid;

  Future<int> getProductStock(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return doc.data()?['stock'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting product stock: $e');
      return 0;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized || _userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .snapshots()
          .listen((snapshot) {
        _items.clear();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          _items[doc.id] = CartItem(
            productId: doc.id,
            name: data['name'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            imageUrl: data['imageUrl'] ?? '',
            quantity: data['quantity'] ?? 1,
          );
        }

        _selectedItems.removeWhere((id) => !_items.containsKey(id));

        notifyListeners();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(
    String productId,
    String name,
    double price,
    String imageUrl,
  ) async {
    if (_userId == null) return false;

    try {
      final currentStock = await getProductStock(productId);

      if (currentStock <= 0) {
        debugPrint('Sản phẩm đã hết hàng');
        return false;
      }

      final currentQty = _items[productId]?.quantity ?? 0;

      if (currentQty >= currentStock) {
        debugPrint('Đã đạt giới hạn tồn kho: $currentStock');
        return false;
      }

      final newQty = currentQty + 1;

      _items[productId] = CartItem(
        productId: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: newQty,
      );
      notifyListeners();

      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .doc(productId);

      if (currentQty > 0) {
        await docRef.update({
          'quantity': newQty,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'name': name,
          'price': price,
          'imageUrl': imageUrl,
          'quantity': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error adding item to cart: $e');

      return false;
    }
  }

  Future<bool> updateQuantity(String productId, int quantity) async {
    if (_userId == null) return false;

    try {
      if (quantity <= 0) {
        await removeItem(productId);
        return true;
      }

      final currentStock = await getProductStock(productId);

      if (quantity > currentStock) {
        debugPrint('Số lượng vượt quá tồn kho: $currentStock');
        return false;
      }

      final item = _items[productId];
      if (item != null) {
        _items[productId] = CartItem(
          productId: item.productId,
          name: item.name,
          price: item.price,
          imageUrl: item.imageUrl,
          quantity: quantity,
        );
        notifyListeners();
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .doc(productId)
          .update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      return false;
    }
  }

  Future<void> removeItem(String productId) async {
    if (_userId == null) return;

    try {
      _items.remove(productId);
      _selectedItems.remove(productId);
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .doc(productId)
          .delete();
    } catch (e) {
      debugPrint('Error removing item: $e');
      rethrow;
    }
  }

  Future<void> removeItems(List<String> productIds) async {
    if (_userId == null || productIds.isEmpty) return;

    try {
      for (var id in productIds) {
        _items.remove(id);
        _selectedItems.remove(id);
      }
      notifyListeners();

      final batch = _firestore.batch();

      for (var productId in productIds) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('cart')
            .doc(productId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error removing items: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    if (_userId == null) return;

    try {
      _items.clear();
      _selectedItems.clear();
      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> validateCart() async {
    final Map<String, String> errors = {};

    for (var entry in _items.entries) {
      final productId = entry.key;
      final cartItem = entry.value;

      try {
        final currentStock = await getProductStock(productId);

        if (currentStock <= 0) {
          errors[productId] = 'Sản phẩm "${cartItem.name}" đã hết hàng';
          _selectedItems.remove(productId);
        } else if (cartItem.quantity > currentStock) {
          errors[productId] =
              'Sản phẩm "${cartItem.name}" chỉ còn $currentStock';
          await updateQuantity(productId, currentStock);
        }
      } catch (e) {
        errors[productId] = 'Không thể kiểm tra sản phẩm "${cartItem.name}"';
      }
    }

    if (errors.isNotEmpty) {
      notifyListeners();
    }

    return errors;
  }

  Future<bool> hasEnoughStock(String productId, int quantity) async {
    try {
      final currentStock = await getProductStock(productId);
      return quantity <= currentStock;
    } catch (e) {
      debugPrint('Error checking stock: $e');
      return false;
    }
  }

  Future<Map<String, int>> getMultipleProductsStock(
      List<String> productIds) async {
    final Map<String, int> stockMap = {};

    try {
      for (var productId in productIds) {
        final stock = await getProductStock(productId);
        stockMap[productId] = stock;
      }
    } catch (e) {
      debugPrint('Error getting multiple stocks: $e');
    }

    return stockMap;
  }

  void toggleSelection(String productId) {
    if (_selectedItems.contains(productId)) {
      _selectedItems.remove(productId);
    } else {
      _selectedItems.add(productId);
    }
    notifyListeners();
  }

  void toggleSelectAll() {
    if (allSelected) {
      _selectedItems.clear();
    } else {
      _selectedItems = Set.from(_items.keys);
    }
    notifyListeners();
  }

  List<CartItem> getSelectedItems() {
    return _selectedItems
        .map((id) => _items[id])
        .whereType<CartItem>()
        .toList();
  }

  void reset() {
    _items.clear();
    _selectedItems.clear();
    _isInitialized = false;
    _isLoading = false;
    notifyListeners();
  }
}
