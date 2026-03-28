import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? shopData;
  final String? shopId;
  final String? businessId;

    const AddEntryScreen({
    super.key,
    this.shopData,
    this.shopId,
    this.businessId,  // ← যোগ করুন
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedShopType = 'রিটেইল দোকান';
  String _selectedArea = 'মাদারিপুর';
  String _selectedStatus = 'active';
  bool _isLoading = false;

  final List<String> _shopTypes = [
    'রিটেইল দোকান',
    'হোলসেল দোকান', 
    'সার্ভিস সেন্টার',
    'রেস্তোরাঁ',
    'গার্মেন্টস',
    'ইলেকট্রনিক্স',
    'ফার্মেসি',
    'অন্যান্য'
  ];

final List<String> _areaList = [
  // ঢাকা বিভাগ (13)
  'ঢাকা',
  'গাজীপুর',
  'নারায়ণগঞ্জ',
  'মানিকগঞ্জ',
  'মুন্সিগঞ্জ',
  'কিশোরগঞ্জ',
  'টাঙ্গাইল',
  'ফরিদপুর',
  'গোপালগঞ্জ',
  'মাদারিপুর',
  'শরীয়তপুর',
  'রাজবাড়ী',
  'নরসিংদী',

  // চট্টগ্রাম বিভাগ (11)
  'চট্টগ্রাম',
  'কক্সবাজার',
  'রাঙ্গামাটি',
  'খাগড়াছড়ি',
  'বান্দরবান',
  'ফেনী',
  'ব্রাহ্মণবাড়িয়া',
  'কুমিল্লা',
  'চাঁদপুর',
  'লক্ষ্মীপুর',
  'নোয়াখালী',

  // রাজশাহী বিভাগ (8)
  'রাজশাহী',
  'চাঁপাইনবাবগঞ্জ',
  'নওগাঁ',
  'নাটোর',
  'পাবনা',
  'সিরাজগঞ্জ',
  'বগুড়া',
  'জয়পুরহাট',

  // খুলনা বিভাগ (10)
  'খুলনা',
  'বাগেরহাট',
  'চুয়াডাঙ্গা',
  'ঝিনাইদহ',
  'যশোর',
  'কুষ্টিয়া',
  'মাগুরা',
  'মেহেরপুর',
  'নড়াইল',
  'সাতক্ষীরা',

  // বরিশাল বিভাগ (6)
  'বরিশাল',
  'ভোলা',
  'ঝালকাঠি',
  'পটুয়াখালী',
  'পিরোজপুর',
  'বরগুনা',

  // সিলেট বিভাগ (4)
  'সিলেট',
  'মৌলভীবাজার',
  'হবিগঞ্জ',
  'সুনামগঞ্জ',

  // রংপুর বিভাগ (8)
  'রংপুর',
  'দিনাজপুর',
  'গাইবান্ধা',
  'কুড়িগ্রাম',
  'লালমনিরহাট',
  'নীলফামারী',
  'পঞ্চগড়',
  'ঠাকুরগাঁও',

  // ময়মনসিংহ বিভাগ (4)
  'ময়মনসিংহ',
  'জামালপুর',
  'শেরপুর',
  'নেত্রকোণা',
];


  final List<String> _statusList = ['সক্রিয়', 'নিষ্ক্রিয়'];

  @override
  void initState() {
    super.initState();
    if (widget.shopData != null) {
      _shopNameController.text = widget.shopData!['shopName'] ?? '';
      _ownerNameController.text = widget.shopData!['ownerName'] ?? '';
      _mobileController.text = widget.shopData!['mobile'] ?? '';
      _addressController.text = widget.shopData!['address'] ?? '';
      _selectedShopType = widget.shopData!['shopType'] ?? 'রিটেইল দোকান';
      _selectedArea = widget.shopData!['area'] ?? 'মাদারিপুর';
      _selectedStatus = widget.shopData!['status'] ?? 'active';
      _noteController.text = widget.shopData!['note'] ?? '';
    }
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      if (widget.shopId != null) {
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(widget.shopId)
            .update({
          'shopName': _shopNameController.text.trim(),
          'ownerName': _ownerNameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          'shopType': _selectedShopType,
          'area': _selectedArea,
          'status': _selectedStatus,
          'note': _noteController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('দোকান আপডেট করা হয়েছে'), 
              backgroundColor: Colors.green
            )
          );
        }
      } else {
        String? businessId;
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
            businessId = userDoc.data()!['selectedBusinessId'];
          }
        } catch (e) {
          debugPrint('Error getting businessId: $e');
        }

        await FirebaseFirestore.instance.collection('shops').add({
          'userId': user.uid,
          'businessId': businessId,
          'shopName': _shopNameController.text.trim(),
          'ownerName': _ownerNameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          'shopType': _selectedShopType,
          'area': _selectedArea,
          'status': _selectedStatus,
          'note': _noteController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'totalDue': 0.0,
          'totalPaid': 0.0,
          'totalOrders': 0,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('দোকান যোগ করা হয়েছে'), 
              backgroundColor: Colors.green
            )
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সংরক্ষণ করতে ব্যর্থ: $e'), 
            backgroundColor: Colors.red
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.shopId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'দোকান এডিট করুন' : 'নতুন দোকান যোগ করুন'), 
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: 'দোকানের নাম *', 
                  prefixIcon: Icon(Icons.store), 
                  border: OutlineInputBorder()
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'দোকানের নাম দিন' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'মালিকের নাম', 
                  prefixIcon: Icon(Icons.person), 
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'মোবাইল নম্বর *', 
                  prefixIcon: Icon(Icons.phone), 
                  border: OutlineInputBorder()
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'মোবাইল নম্বর দিন';
                  if (value.length < 11) return 'সঠিক মোবাইল নম্বর দিন';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'ঠিকানা', 
                  prefixIcon: Icon(Icons.location_on), 
                  border: OutlineInputBorder()
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // এলাকা নির্বাচন - ফিক্সড (initialValue ব্যবহার)
              DropdownButtonFormField<String>(
                initialValue: _selectedArea,  // ← value এর বদলে initialValue
                decoration: const InputDecoration(
                  labelText: 'এলাকা', 
                  prefixIcon: Icon(Icons.location_city), 
                  border: OutlineInputBorder()
                ),
                items: _areaList.map((area) {
                  return DropdownMenuItem<String>(
                    value: area,
                    child: Text(area),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedArea = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // দোকানের ধরন - ফিক্সড (initialValue ব্যবহার)
              DropdownButtonFormField<String>(
                initialValue: _selectedShopType,  // ← value এর বদলে initialValue
                decoration: const InputDecoration(
                  labelText: 'দোকানের ধরন', 
                  prefixIcon: Icon(Icons.category), 
                  border: OutlineInputBorder()
                ),
                items: _shopTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedShopType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // স্ট্যাটাস - ফিক্সড (initialValue ব্যবহার)
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,  // ← value এর বদলে initialValue
                decoration: const InputDecoration(
                  labelText: 'স্ট্যাটাস', 
                  prefixIcon: Icon(Icons.flag), 
                  border: OutlineInputBorder()
                ),
                items: _statusList.map((status) {
                  return DropdownMenuItem<String>(
                    value: status == 'সক্রিয়' ? 'active' : 'inactive',
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status == 'সক্রিয়' ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController, 
                decoration: const InputDecoration(
                  labelText: 'অতিরিক্ত তথ্য (ঐচ্ছিক)', 
                  prefixIcon: Icon(Icons.note), 
                  border: OutlineInputBorder()
                ), 
                maxLines: 2
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(isEditMode ? 'আপডেট করুন' : 'দোকান সংরক্ষণ করুন', 
                        style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}