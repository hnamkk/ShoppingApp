import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  String detail;
  String ward;
  String district;
  String province;
  String phone;

  Address({
    required this.detail,
    required this.ward,
    required this.district,
    required this.province,
    required this.phone,
  });

  factory Address.defaultAddress() {
    return Address(
      detail: '',
      ward: '',
      district: '',
      province: '',
      phone: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail': detail,
      'ward': ward,
      'district': district,
      'province': province,
      'phone': phone,
      // Thêm timestamp để theo dõi thời điểm lưu/cập nhật
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory Address.fromJson(Map<String, dynamic> json, [String? documentId]) {
    return Address(
      detail: json['detail'] ?? '',
      ward: json['ward'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  // Format địa chỉ ngắn gọn để hiển thị (ví dụ: trong mục đơn hàng)
  String getShortAddress() {
    return '$detail ($phone)';
  }

  // Format địa chỉ đầy đủ (Phường/Xã, Quận/Huyện, Tỉnh/Thành phố)
  String getFullAddress() {
    // Lọc bỏ các trường rỗng để tránh hiển thị dấu phẩy thừa
    List<String> parts = [ward, district, province].where((p) => p.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  String toString() {
    return "$detail ($phone)\n${getFullAddress()}";
  }
}