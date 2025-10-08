import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shoppingapp/models/address_model.dart';

class AddressScreen extends StatefulWidget {
  final Address address;

  const AddressScreen({required this.address});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  late TextEditingController detailController;
  late TextEditingController phoneController;

  Map<String, dynamic> locations = {};

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedWard;

  List<String> provinces = [];
  List<String> districts = [];
  List<String> wards = [];

  @override
  void initState() {
    super.initState();
    detailController = TextEditingController(text: widget.address.detail);
    phoneController = TextEditingController(text: widget.address.phone);

    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/locations.json');
      final data = json.decode(jsonString);

      setState(() {
        locations = data;
        provinces = locations.keys.toList();
        if (provinces.isNotEmpty) {
          provinces.sort((a, b) => a.compareTo(b));
        }

        if (provinces.contains(widget.address.province)) {
          selectedProvince = widget.address.province;
          updateDistricts();

          if (districts.isNotEmpty) {
            districts.sort((a, b) => a.compareTo(b));
          }

          if (districts.contains(widget.address.district)) {
            selectedDistrict = widget.address.district;
            updateWards();

            if (wards.isNotEmpty) {
              wards.sort((a, b) => a.compareTo(b));
            }

            if (wards.contains(widget.address.ward)) {
              selectedWard = widget.address.ward;
            }
          }
        }
      });
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  void updateDistricts() {
    if (selectedProvince != null && locations.containsKey(selectedProvince)) {
      setState(() {
        districts =
            (locations[selectedProvince] as Map<String, dynamic>).keys.toList();
        selectedDistrict = null;
        selectedWard = null;
        wards = [];
      });
    }
  }

  void updateWards() {
    if (selectedProvince != null &&
        selectedDistrict != null &&
        locations[selectedProvince] != null &&
        locations[selectedProvince][selectedDistrict] != null) {
      setState(() {
        wards =
            List<String>.from(locations[selectedProvince][selectedDistrict]);
        selectedWard = null;
      });
    }
  }

  @override
  void dispose() {
    detailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        hint: Text(hint ?? 'Chọn $label'),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: items.isEmpty ? null : onChanged,
        isExpanded: true,
      ),
    );
  }

  void _saveAddress() {
    if (detailController.text.trim().isEmpty ||
        selectedProvince == null ||
        selectedDistrict == null ||
        selectedWard == null ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Color(0xFFE57373),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      Address(
        detail: detailController.text.trim(),
        ward: selectedWard!,
        district: selectedDistrict!,
        province: selectedProvince!,
        phone: phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Sửa địa chỉ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin liên hệ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              const Text(
                'Địa chỉ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Tỉnh/Thành phố',
                icon: Icons.location_city,
                value: selectedProvince,
                items: provinces,
                onChanged: (value) {
                  setState(() {
                    selectedProvince = value;
                    updateDistricts();
                  });
                },
              ),
              _buildDropdown(
                label: 'Quận/Huyện',
                icon: Icons.map,
                value: selectedDistrict,
                items: districts,
                onChanged: (value) {
                  setState(() {
                    selectedDistrict = value;
                    updateWards();
                  });
                },
                hint: selectedProvince == null
                    ? 'Vui lòng chọn Tỉnh/Thành phố trước'
                    : 'Chọn Quận/Huyện',
              ),
              _buildDropdown(
                label: 'Phường/Xã',
                icon: Icons.place,
                value: selectedWard,
                items: wards,
                onChanged: (value) {
                  setState(() {
                    selectedWard = value;
                  });
                },
                hint: selectedDistrict == null
                    ? 'Vui lòng chọn Quận/Huyện trước'
                    : 'Chọn Phường/Xã',
              ),
              _buildTextField(
                controller: detailController,
                label: 'Địa chỉ chi tiết (Số nhà, tên đường...)',
                icon: Icons.home,
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Lưu địa chỉ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
