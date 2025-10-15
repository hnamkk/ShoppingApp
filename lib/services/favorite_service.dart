import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavoriteService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;

  FavoriteService() {
    _loadFavorites();
  }

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadFavorites() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc('list')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _favoriteIds = Set<String>.from(data['productIds'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    if (_userId == null) return;

    try {
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc('list')
          .set({
        'productIds': _favoriteIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
      notifyListeners();
    }
  }

  Stream<List<String>> getFavoritesStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc('list')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        return List<String>.from(data['productIds'] ?? []);
      }
      return [];
    });
  }

  int get favoriteCount => _favoriteIds.length;
}
