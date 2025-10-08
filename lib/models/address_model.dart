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

  String getShortAddress() {
    return '$detail ($phone)';
  }

  String getFullAddress() {
    List<String> parts =
        [detail, ward, district, province].where((p) => p.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  String toString() {
    return "$detail ($phone)\n${getFullAddress()}";
  }
}
