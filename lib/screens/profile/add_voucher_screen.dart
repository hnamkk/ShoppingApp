import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';

class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({Key? key}) : super(key: key);

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final VoucherService _voucherService = VoucherService();
  bool _isLoading = false;
  bool _checkDuplicates = true;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<bool> _isVoucherDuplicate(String code) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addVouchers() async {
    if (_jsonController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập dữ liệu JSON', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dynamic jsonData = json.decode(_jsonController.text);

      List<Map<String, dynamic>> vouchers = [];

      if (jsonData is List) {
        vouchers = jsonData.cast<Map<String, dynamic>>();
      } else if (jsonData is Map) {
        if (jsonData.containsKey('vouchers') && jsonData['vouchers'] is List) {
          vouchers = List<Map<String, dynamic>>.from(jsonData['vouchers']);
        } else {
          vouchers = [jsonData.cast<String, dynamic>()];
        }
      } else {
        throw FormatException('Định dạng JSON không hợp lệ');
      }

      int successCount = 0;
      int duplicateCount = 0;
      List<String> duplicateCodes = [];

      for (var voucherData in vouchers) {
        if (!voucherData.containsKey('code') ||
            !voucherData.containsKey('title') ||
            !voucherData.containsKey('value')) {
          throw FormatException(
              'Voucher phải có trường "code", "title" và "value"');
        }

        String code = voucherData['code'].toString().toUpperCase();

        if (_checkDuplicates) {
          bool isDuplicate = await _isVoucherDuplicate(code);
          if (isDuplicate) {
            duplicateCount++;
            duplicateCodes.add(code);
            continue;
          }
        }

        final voucher = Voucher(
          code: code,
          title: voucherData['title']?.toString() ?? '',
          description: voucherData['description']?.toString() ?? '',
          type: voucherData['type'] == 'fixed'
              ? VoucherType.fixed
              : VoucherType.percentage,
          value: (voucherData['value'] ?? 0).toDouble(),
          maxDiscount: voucherData['maxDiscount'] != null
              ? (voucherData['maxDiscount']).toDouble()
              : null,
          minOrderAmount: (voucherData['minOrderAmount'] ?? 0).toDouble(),
          expiryDate: voucherData['expiryDate'] != null
              ? DateTime.parse(voucherData['expiryDate'])
              : DateTime.now().add(const Duration(days: 30)),
          isActive: voucherData['isActive'] ?? true,
          usageLimit: voucherData['usageLimit'] ?? -1,
          usedCount: 0,
        );

        await _voucherService.createVoucher(voucher);
        successCount++;
      }

      setState(() {
        _isLoading = false;
      });

      if (successCount > 0 || duplicateCount > 0) {
        _showResultDialog(successCount, duplicateCount, duplicateCodes);
        if (successCount > 0) {
          _jsonController.clear();
        }
      } else {
        _showMessage('Không có voucher nào được thêm', isError: true);
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
      int successCount, int duplicateCount, List<String> duplicateCodes) {
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
                  '✓ Đã thêm thành công: $successCount voucher',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (duplicateCount > 0) ...[
                Text(
                  '⚠ Bỏ qua (trùng lặp): $duplicateCount voucher',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (duplicateCodes.isNotEmpty) ...[
                  const Text(
                    'Các mã voucher trùng lặp:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  ...duplicateCodes.take(5).map((code) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '• $code',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                  if (duplicateCodes.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '... và ${duplicateCodes.length - 5} voucher khác',
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
    final exampleJson = '''
[
  {
    "code": "GIAM10",
    "title": "Giảm 10%",
    "description": "Giảm 10% tối đã 50.000đ cho đơn hàng từ 200.000đ",
    "type": "percentage",
    "value": 10,
    "maxDiscount": 50000,
    "minOrderAmount": 200000,
    "expiryDate": "2025-12-31T23:59:59.000Z",
    "isActive": true,
    "usageLimit": 100
  },
]

Lưu ý:
- type: "percentage" (giảm %) hoặc "fixed" (giảm cố định)
- maxDiscount: chỉ áp dụng cho type "percentage"
- usageLimit: -1 = không giới hạn
- expiryDate: định dạng ISO 8601
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ví dụ JSON'),
        content: SingleChildScrollView(
          child: SelectableText(
            exampleJson,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
        title: const Text('Thêm Voucher'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                        '{\n  "code": "GIAM10",\n  "title": "Giảm 10%",\n  "value": 10,\n  "type": "percentage",\n  ...\n}',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _addVouchers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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
                      'Thêm Voucher',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
