import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isLoading = false;
  bool _checkDuplicates = true;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<bool> _isProductDuplicate(String productName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('name', isEqualTo: productName)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _addProducts() async {
    if (_jsonController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập dữ liệu JSON', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dynamic jsonData = json.decode(_jsonController.text);

      List<Map<String, dynamic>> products = [];

      if (jsonData is List) {
        products = jsonData.cast<Map<String, dynamic>>();
      } else if (jsonData is Map) {
        products = [jsonData.cast<String, dynamic>()];
      } else {
        throw const FormatException('Định dạng JSON không hợp lệ');
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      int successCount = 0;
      int duplicateCount = 0;
      List<String> duplicateNames = [];

      for (var product in products) {
        if (!product.containsKey('name') || !product.containsKey('price')) {
          throw const FormatException('Sản phẩm phải có trường "name" và "price"');
        }

        String productName = product['name'];

        if (_checkDuplicates) {
          bool isDuplicate = await _isProductDuplicate(productName);
          if (isDuplicate) {
            duplicateCount++;
            duplicateNames.add(productName);
            continue;
          }
        }
        List<String> imageUrls = [];
        if (product.containsKey('imageUrls') && product['imageUrls'] is List) {
          imageUrls = List<String>.from(product['imageUrls']);
        } else if (product.containsKey('imageUrl') &&
            product['imageUrl'] != null) {
          imageUrls = [product['imageUrl']];
        }

        final Map<String, dynamic> productData = {
          'name': productName,
          'price': product['price'],
          'category': product['category'] ?? '',
          'description': product['description'] ?? '',
          'imageUrl': imageUrls.isNotEmpty ? imageUrls[0] : '',
          'imageUrls': imageUrls,
          'stock': product['stock'] ?? 0,
          'sold': product['sold'] ?? 0,
          'featured': product['featured'] ?? false,
          'tags': product['tags'] ?? [],
          'createdAt': FieldValue.serverTimestamp(),
        };

        await firestore.collection('products').add(productData);
        successCount++;
      }

      setState(() {
        _isLoading = false;
      });

      if (successCount > 0 || duplicateCount > 0) {
        _showResultDialog(successCount, duplicateCount, duplicateNames);
        if (successCount > 0) {
          _jsonController.clear();
        }
      } else {
        _showMessage('Không có sản phẩm nào được thêm', isError: true);
      }
    } on FormatException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Lỗi định dạng JSON: ${e.message}', isError: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Lỗi: ${e.toString()}', isError: true);
    }
  }

  void _showResultDialog(
      int successCount, int duplicateCount, List<String> duplicateNames) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              successCount > 0 ? Icons.check_circle : Icons.warning,
              color: successCount > 0 ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Kết quả'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (successCount > 0) ...[
                Text(
                  '✓ Đã thêm thành công: $successCount sản phẩm',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (duplicateCount > 0) ...[
                Text(
                  '⚠ Bỏ qua (trùng lặp): $duplicateCount sản phẩm',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (duplicateNames.isNotEmpty) ...[
                  const Text(
                    'Các sản phẩm trùng lặp:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  ...duplicateNames.take(5).map((name) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '• $name',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                  if (duplicateNames.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '... và ${duplicateNames.length - 5} sản phẩm khác',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showExampleJson() {
    const exampleJson = '''
[
  {
    "name": "Chuối tiêu 500gr",
    "price": 19000,
    "category": "Trái cây",
    "description": "Chuối thơm ngon",
    "imageUrls": [
      "https://example.com/image1.jpg",
      "https://example.com/image2.jpg",
    ],
    "stock": 300,
    "sold": 127,
    "featured": true,
    "tags": ["Hoa quả", "Trái cây", "Chuối", "Chuối tiêu"]
  },
  {
    "name": "Táo Fuji",
    "price": 100000,
    "category": "Trái cây",
    "description": "Táo Fuji nhập khẩu",
    "imageUrl": "https://example.com/apple.jpg",
    "stock": 150,
    "sold": 45,
    "featured": false,
    "tags": ["Hoa quả", "Trái cây", "Táo"]
  }
]
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ví dụ JSON'),
        content: const SingleChildScrollView(
          child: SelectableText(
            exampleJson,
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _jsonController.text = exampleJson.split('\n\nLưu ý:')[0];
              Navigator.pop(context);
            },
            child: const Text('Sử dụng ví dụ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sản phẩm'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showExampleJson,
            tooltip: 'Xem ví dụ JSON',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nhập dữ liệu JSON',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Kiểm tra trùng',
                      style: TextStyle(fontSize: 14),
                    ),
                    Switch(
                      value: _checkDuplicates,
                      onChanged: (value) {
                        setState(() {
                          _checkDuplicates = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        '{\n  "name": "Tên sản phẩm",\n  "price": 10000,\n  "imageUrls": [...],\n  ...\n}',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _addProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Thêm sản phẩm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
