import 'package:cloud_firestore/cloud_firestore.dart';

enum VoucherType {
  percentage,
  fixed,
}

class Voucher {
  final String? id;
  final String code;
  final String title;
  final String description;
  final VoucherType type;
  final double value;
  final double? maxDiscount;
  final double minOrderAmount;
  final DateTime expiryDate;
  final bool isActive;
  final int usageLimit;
  final int usedCount;

  Voucher({
    this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.maxDiscount,
    this.minOrderAmount = 0,
    required this.expiryDate,
    this.isActive = true,
    this.usageLimit = -1,
    this.usedCount = 0,
  });

  double calculateDiscount(double orderAmount, double shippingFee) {
    if (orderAmount < minOrderAmount) {
      return 0;
    }

    switch (type) {
      case VoucherType.percentage:
        double discount = orderAmount * (value / 100);
        if (maxDiscount != null && discount > maxDiscount!) {
          discount = maxDiscount!;
        }
        return discount;

      case VoucherType.fixed:
        return value > orderAmount ? orderAmount : value;
    }
  }

  bool isValid(double orderAmount) {
    if (!isActive || DateTime.now().isAfter(expiryDate)) {
      return false;
    }
    if (usageLimit != -1 && usedCount >= usageLimit) {
      return false;
    }

    if (orderAmount < minOrderAmount) {
      return false;
    }

    return true;
  }

  String? getInvalidReason(double orderAmount) {
    if (!isActive) {
      return 'Voucher không còn hiệu lực';
    }

    if (DateTime.now().isAfter(expiryDate)) {
      return 'Voucher đã hết hạn';
    }

    if (usageLimit != -1 && usedCount >= usageLimit) {
      return 'Voucher đã hết lượt sử dụng';
    }

    if (orderAmount < minOrderAmount) {
      return 'Đơn hàng tối thiểu ${_formatCurrency(minOrderAmount)}đ';
    }

    return null;
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'type': type.name,
      'value': value,
      'maxDiscount': maxDiscount,
      'minOrderAmount': minOrderAmount,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
    };
  }

  factory Voucher.fromMap(String id, Map<String, dynamic> map) {
    return Voucher(
      id: id,
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: VoucherType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VoucherType.percentage,
      ),
      value: (map['value'] ?? 0).toDouble(),
      maxDiscount: map['maxDiscount']?.toDouble(),
      minOrderAmount: (map['minOrderAmount'] ?? 0).toDouble(),
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      usageLimit: map['usageLimit'] ?? -1,
      usedCount: map['usedCount'] ?? 0,
    );
  }

  Voucher copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    VoucherType? type,
    double? value,
    double? maxDiscount,
    double? minOrderAmount,
    DateTime? expiryDate,
    bool? isActive,
    int? usageLimit,
    int? usedCount,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
    );
  }
}
