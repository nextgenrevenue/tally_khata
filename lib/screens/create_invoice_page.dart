import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateInvoicePage extends StatefulWidget {
  final Map<String, dynamic> shopData;
  final String shopId;
  final String? businessId; 

  const CreateInvoicePage({
    super.key,
    required this.shopData,
    required this.shopId,
    this.businessId,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final List<Map<String, dynamic>> _items = [];
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  double _totalAmount = 0;
  double _paidAmount = 0;
  double _dueAmount = 0;
  bool _isLoading = false;

  void _addItem() {
    if (_productController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সব তথ্য দিন'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _items.add({
        'product': _productController.text,
        'quantity': int.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
        'total': int.parse(_quantityController.text) * double.parse(_priceController.text),
      });
      
      _calculateTotal();
      
      _productController.clear();
      _quantityController.clear();
      _priceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalAmount = 0;
    for (var item in _items) {
      _totalAmount += item['total'];
    }
    _dueAmount = _totalAmount - _paidAmount;
  }

  Future<void> _saveInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কমপক্ষে একটি পণ্য যোগ করুন'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance
          .collection('invoices')
          .add({
        'userId': user!.uid,
        'shopId': widget.shopId,
        'shopName': widget.shopData['shopName'],
        'shopMobile': widget.shopData['mobile'],
        'items': _items,
        'totalAmount': _totalAmount,
        'paidAmount': _paidAmount,
        'dueAmount': _dueAmount,
        'date': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .update({
        'totalDue': FieldValue.increment(_dueAmount),
        'totalPaid': FieldValue.increment(_paidAmount),
        'totalOrders': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ইনভয়েস তৈরি হয়েছে'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইনভয়েস তৈরি ব্যর্থ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ইনভয়েস - ${widget.shopData['shopName']}'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shopData['shopName'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('মালিক: ${widget.shopData['ownerName']}'),
                          Text('মোবাইল: ${widget.shopData['mobile']}'),
                          Text('ঠিকানা: ${widget.shopData['address']}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'পণ্য যোগ করুন',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _productController,
                            decoration: const InputDecoration(
                              labelText: 'পণ্যের নাম',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'পরিমাণ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'দাম',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add),
                              label: const Text('পণ্য যোগ করুন'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'পণ্যের তালিকা',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['product']),
                            subtitle: Text('পরিমাণ: ${item['quantity']} × ৳${item['price']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '৳${item['total']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('মোট:', style: TextStyle(fontSize: 16)),
                              Text(
                                '৳${_totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'পরিশোধিত টাকা',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _paidAmount = double.tryParse(value) ?? 0;
                                _dueAmount = _totalAmount - _paidAmount;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'বাকি:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '৳${_dueAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _dueAmount > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveInvoice,
                      icon: const Icon(Icons.save),
                      label: const Text('ইনভয়েস সংরক্ষণ করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}