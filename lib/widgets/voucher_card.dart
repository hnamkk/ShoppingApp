import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';

class VoucherCard extends StatelessWidget {
  final VoidCallback onTap;
  final Voucher? selectedVoucher;

  const VoucherCard({
    super.key,
    required this.onTap,
    this.selectedVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat("#,###", "vi_VN");
    final bool hasVoucher = selectedVoucher != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasVoucher ? Colors.green[50] : Colors.white,
          border: Border.all(
            color: hasVoucher ? Colors.green : Colors.grey[300]!,
            width: hasVoucher ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer,
              color: hasVoucher ? Colors.green : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasVoucher ? selectedVoucher!.title : 'Chọn ưu đãi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasVoucher ? FontWeight.w600 : FontWeight.w500,
                      color: hasVoucher ? Colors.green[900] : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasVoucher) ...[
                    const SizedBox(height: 2),
                    Text(
                      selectedVoucher!.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasVoucher)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

class VoucherBottomSheet extends StatefulWidget {
  final double orderAmount;
  final Voucher? currentVoucher;

  const VoucherBottomSheet({
    super.key,
    required this.orderAmount,
    this.currentVoucher,
  });

  @override
  State<VoucherBottomSheet> createState() => _VoucherBottomSheetState();
}

class _VoucherBottomSheetState extends State<VoucherBottomSheet> {
  final TextEditingController _codeController = TextEditingController();
  final VoucherService _voucherService = VoucherService();
  List<Voucher> _vouchers = [];
  Voucher? _selectedVoucher;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedVoucher = widget.currentVoucher;
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vouchers = await _voucherService.getActiveVouchers();

      vouchers.sort((a, b) {
        final discountA = a.calculateDiscount(widget.orderAmount, 0);
        final discountB = b.calculateDiscount(widget.orderAmount, 0);

        final validA = a.isValid(widget.orderAmount);
        final validB = b.isValid(widget.orderAmount);

        if (validA && !validB) return -1;
        if (!validA && validB) return 1;

        return discountB.compareTo(discountA);
      });

      if (mounted) {
        setState(() {
          _vouchers = vouchers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi load vouchers: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải voucher. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyVoucherByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorDialog('Vui lòng nhập mã voucher');
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      final voucher = await _voucherService.applyVoucherByCode(
        code,
        widget.orderAmount,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (voucher != null) {
        setState(() {
          _selectedVoucher = voucher;
          _codeController.clear();
        });
        _showSuccessDialog(voucher);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSuccessDialog(Voucher voucher) {
    final discount = voucher.calculateDiscount(widget.orderAmount, 0);
    final formatCurrency = NumberFormat("#,###", "vi_VN");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Áp dụng thành công!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              voucher.title,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Giảm ${formatCurrency.format(discount)}đ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red[600],
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể áp dụng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applySelectedVoucher() {
    Navigator.pop(context, _selectedVoucher);
  }

  void _removeVoucher() {
    Navigator.pop(context, 'REMOVE_VOUCHER');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn ưu đãi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.confirmation_number),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(4),
                      child: TextButton(
                        onPressed: _applyVoucherByCode,
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.green),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mã khuyến mãi',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (_vouchers.isNotEmpty && !_isLoading)
                      Text(
                        '${_vouchers.where((v) => v.isValid(widget.orderAmount)).length} khả dụng',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang tải voucher...'),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadVouchers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_vouchers.isEmpty)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Không có voucher khả dụng',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy quay lại sau nhé!',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...(_vouchers.map((voucher) => _buildVoucherItem(voucher))),
              ],
            ),
          ),
          if (_selectedVoucher != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _removeVoucher,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Bỏ chọn',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applySelectedVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoucherItem(Voucher voucher) {
    final isValid = voucher.isValid(widget.orderAmount);
    final discount = voucher.calculateDiscount(widget.orderAmount, 0);
    final formatCurrency = NumberFormat("#,###", "vi_VN");
    final isSelected = _selectedVoucher?.id == voucher.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? Colors.green[50]
          : (isValid ? Colors.white : Colors.grey[50]),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.green
              : (isValid ? Colors.grey[200]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isValid
            ? () {
                setState(() {
                  _selectedVoucher = isSelected ? null : voucher;
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isValid
                      ? (isSelected
                          ? Colors.green
                          : Colors.green.withOpacity(0.1))
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_offer,
                  size: 24,
                  color: isValid
                      ? (isSelected ? Colors.white : Colors.green)
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isValid ? Colors.black : Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isValid ? Colors.grey[700] : Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (isValid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Giảm: ${formatCurrency.format(discount)}đ',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Text(
                        voucher.getInvalidReason(widget.orderAmount) ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isValid)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected ? Colors.green : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
