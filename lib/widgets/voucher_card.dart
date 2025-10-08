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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.local_offer, color: Colors.grey, size: 26),
        title: Text(
          selectedVoucher != null ? selectedVoucher!.title : 'Chọn ưu đãi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: selectedVoucher != null ? Colors.green : Colors.black,
          ),
        ),
        subtitle: selectedVoucher != null
            ? Text(
                selectedVoucher!.description,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              )
            : null,
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vouchers = await _voucherService.getActiveVouchers();
      if (mounted) {
        setState(() {
          _vouchers = vouchers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi load vouchers: $e');
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
      _showMessage('Vui lòng nhập mã voucher', isError: true);
      return;
    }

    try {
      final voucher = await _voucherService.applyVoucherByCode(
        code,
        widget.orderAmount,
      );

      if (voucher != null && mounted) {
        Navigator.pop(context, voucher);
      }
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
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
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn ưu đãi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Nhập mã giảm giá',
              prefixIcon: const Icon(Icons.confirmation_number),
              suffixIcon: TextButton(
                onPressed: _applyVoucherByCode,
                child: const Text('Áp dụng'),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mã khuyến mãi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Expanded(
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
            Expanded(
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
            Expanded(
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _vouchers.length,
                itemBuilder: (context, index) {
                  final voucher = _vouchers[index];
                  return _buildVoucherItem(voucher);
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVoucherItem(Voucher voucher) {
    final isValid = voucher.isValid(widget.orderAmount);
    final discount = voucher.calculateDiscount(widget.orderAmount, 0);
    final formatCurrency = NumberFormat("#,###", "vi_VN");
    final isSelected = widget.currentVoucher?.id == voucher.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.green.withOpacity(0.1) : null,
      child: InkWell(
        onTap: isValid ? () => Navigator.pop(context, voucher) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isValid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer,
                  size: 22,
                  color: isValid ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isValid ? Colors.black : Colors.grey,
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
                        color: isValid ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isValid)
                      Text(
                        'Giảm: ${formatCurrency.format(discount)}đ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        voucher.getInvalidReason(widget.orderAmount) ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isValid)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    Navigator.pop(context, voucher);
                  },
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: const CircleBorder(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
