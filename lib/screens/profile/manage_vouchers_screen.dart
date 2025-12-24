import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';

class ManageVouchersScreen extends StatefulWidget {
  const ManageVouchersScreen({Key? key}) : super(key: key);

  @override
  State<ManageVouchersScreen> createState() => _ManageVouchersScreenState();
}

class _ManageVouchersScreenState extends State<ManageVouchersScreen> {
  final VoucherService _voucherService = VoucherService();
  String _searchQuery = '';
  String _filterStatus = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý Voucher',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showVoucherForm(),
            tooltip: 'Thêm voucher',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildVoucherList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm voucher...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Tất cả', 'Còn hạn', 'Hết hạn', 'Không hoạt động']
                  .map((status) {
                final isSelected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filterStatus = status;
                      });
                    },
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vouchers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Chưa có voucher nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        var vouchers = snapshot.data!.docs
            .map((doc) => Voucher.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          vouchers = vouchers
              .where((v) =>
                  v.code.toLowerCase().contains(_searchQuery) ||
                  v.title.toLowerCase().contains(_searchQuery))
              .toList();
        }

        // Filter by status
        if (_filterStatus != 'Tất cả') {
          final now = DateTime.now();
          vouchers = vouchers.where((v) {
            if (_filterStatus == 'Còn hạn') {
              return v.isActive && v.expiryDate.isAfter(now);
            } else if (_filterStatus == 'Hết hạn') {
              return v.expiryDate.isBefore(now);
            } else if (_filterStatus == 'Không hoạt động') {
              return !v.isActive;
            }
            return true;
          }).toList();
        }

        if (vouchers.isEmpty) {
          return const Center(
            child: Text(
              'Không tìm thấy voucher',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            return _buildVoucherCard(voucher);
          },
        );
      },
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final now = DateTime.now();
    final isExpired = voucher.expiryDate.isBefore(now);
    final isActive = voucher.isActive && !isExpired;

    Color statusColor = isActive ? Colors.green : (isExpired ? Colors.red : Colors.grey);
    String statusText = isActive
        ? 'Hoạt động'
        : (isExpired ? 'Hết hạn' : 'Tạm ngưng');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Text(
                          voucher.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        voucher.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            voucher.isActive ? Icons.pause : Icons.play_arrow,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(voucher.isActive ? 'Tạm ngưng' : 'Kích hoạt'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showVoucherForm(voucher: voucher);
                    } else if (value == 'toggle') {
                      _toggleVoucherStatus(voucher);
                    } else if (value == 'delete') {
                      _confirmDelete(voucher);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              voucher.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.discount,
                  voucher.type == VoucherType.percentage
                      ? '${voucher.value.toInt()}%'
                      : '${_formatCurrency(voucher.value)}đ',
                  Colors.blue,
                ),
                if (voucher.maxDiscount != null)
                  _buildInfoChip(
                    Icons.money,
                    'Tối đa: ${_formatCurrency(voucher.maxDiscount!)}đ',
                    Colors.orange,
                  ),
                _buildInfoChip(
                  Icons.shopping_cart,
                  'Đơn tối thiểu: ${_formatCurrency(voucher.minOrderAmount)}đ',
                  Colors.purple,
                ),
                _buildInfoChip(
                  Icons.calendar_today,
                  'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}',
                  isExpired ? Colors.red : Colors.green,
                ),
                if (voucher.usageLimit != -1)
                  _buildInfoChip(
                    Icons.people,
                    'Lượt dùng: ${voucher.usedCount}/${voucher.usageLimit}',
                    Colors.teal,
                  ),
                _buildInfoChip(
                  Icons.circle,
                  statusText,
                  statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showVoucherForm({Voucher? voucher}) {
    final isEditing = voucher != null;
    final codeController = TextEditingController(text: voucher?.code ?? '');
    final titleController = TextEditingController(text: voucher?.title ?? '');
    final descriptionController =
        TextEditingController(text: voucher?.description ?? '');
    final valueController =
        TextEditingController(text: voucher?.value.toString() ?? '');
    final maxDiscountController =
        TextEditingController(text: voucher?.maxDiscount?.toString() ?? '');
    final minOrderController = TextEditingController(
        text: voucher?.minOrderAmount.toString() ?? '0');
    final usageLimitController =
        TextEditingController(text: voucher?.usageLimit.toString() ?? '-1');
    VoucherType selectedType = voucher?.type ?? VoucherType.percentage;
    DateTime selectedDate = voucher?.expiryDate ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = voucher?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Chỉnh sửa Voucher' : 'Thêm Voucher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã voucher *',
                    border: OutlineInputBorder(),
                    hintText: 'VD: GIAM10',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VoucherType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại giảm giá *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: VoucherType.percentage,
                      child: Text('Giảm theo %'),
                    ),
                    DropdownMenuItem(
                      value: VoucherType.fixed,
                      child: Text('Giảm cố định'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: 'Giá trị *',
                    border: const OutlineInputBorder(),
                    suffixText:
                        selectedType == VoucherType.percentage ? '%' : 'đ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedType == VoucherType.percentage)
                  TextField(
                    controller: maxDiscountController,
                    decoration: const InputDecoration(
                      labelText: 'Giảm tối đa',
                      border: OutlineInputBorder(),
                      suffixText: 'đ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                if (selectedType == VoucherType.percentage)
                  const SizedBox(height: 12),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Đơn hàng tối thiểu *',
                    border: OutlineInputBorder(),
                    suffixText: 'đ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usageLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Giới hạn lượt dùng',
                    border: OutlineInputBorder(),
                    hintText: '-1 = Không giới hạn',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d+'))
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày hết hạn *'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value ?? true;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    const Text('Kích hoạt ngay'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isEmpty ||
                    titleController.text.isEmpty ||
                    valueController.text.isEmpty ||
                    minOrderController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin bắt buộc'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newVoucher = Voucher(
                  id: voucher?.id,
                  code: codeController.text.toUpperCase(),
                  title: titleController.text,
                  description: descriptionController.text,
                  type: selectedType,
                  value: double.parse(valueController.text),
                  maxDiscount: maxDiscountController.text.isNotEmpty
                      ? double.parse(maxDiscountController.text)
                      : null,
                  minOrderAmount: double.parse(minOrderController.text),
                  expiryDate: selectedDate,
                  isActive: isActive,
                  usageLimit: int.parse(usageLimitController.text),
                  usedCount: voucher?.usedCount ?? 0,
                );

                try {
                  if (isEditing) {
                    await _voucherService.updateVoucher(newVoucher);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật voucher thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await _voucherService.createVoucher(newVoucher);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thêm voucher thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVoucherStatus(Voucher voucher) async {
    try {
      final updatedVoucher = voucher.copyWith(isActive: !voucher.isActive);
      await _voucherService.updateVoucher(updatedVoucher);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Đã ${updatedVoucher.isActive ? 'kích hoạt' : 'tạm ngưng'} voucher'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa voucher "${voucher.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _voucherService.deleteVoucher(voucher.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xóa voucher thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
