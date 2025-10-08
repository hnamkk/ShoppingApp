import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePagination<T> {
  final Query query;
  final T Function(Map<String, dynamic> data, String id) fromFirestore;
  final int pageSize;
  final bool Function(T)? filterCondition;

  List<T> _items = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  FirestorePagination({
    required this.query,
    required this.fromFirestore,
    this.pageSize = 10,
    this.filterCondition,
  });

  List<T> get items => _items;

  bool get hasMore => _hasMore;

  bool get isLoading => _isLoading;

  bool get isEmpty => _items.isEmpty && !_hasMore;

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;

    try {
      int fetchSize = filterCondition != null ? pageSize * 2 : pageSize;
      Query paginatedQuery = query.limit(fetchSize);

      if (_lastDocument != null) {
        paginatedQuery = paginatedQuery.startAfterDocument(_lastDocument!);
      }

      final snapshot = await paginatedQuery.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = snapshot.docs.last;

        var newItems = snapshot.docs
            .map((doc) =>
                fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        if (filterCondition != null) {
          newItems = newItems.where(filterCondition!).toList();
        }

        _items.addAll(newItems);

        if (snapshot.docs.length < fetchSize) {
          _hasMore = false;
        }
      }
    } catch (e) {
      print('Error loading more: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    _items.clear();
    _lastDocument = null;
    _hasMore = true;
    await loadMore();
  }

  void clear() {
    _items.clear();
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
  }
}
