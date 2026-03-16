import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StockHisabPage extends StatefulWidget {
  const StockHisabPage({super.key});

  @override
  State<StockHisabPage> createState() => _StockHisabPageState();
}

class _StockHisabPageState extends State<StockHisabPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBusinessId;
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSelectedBusiness();
  }

  Future<void> _loadSelectedBusiness() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
      setState(() {
        _selectedBusinessId = userDoc.data()!['selectedBusinessId'];
      });
    }
  }

  Future<void> _showAddProductDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final noteController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন পণ্য যোগ করুন'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'পণ্যের নাম *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'পরিমাণ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'মূল্য (প্রতি পিস) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'বিবরণ (ঐচ্ছিক)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  quantityController.text.isEmpty ||
                  priceController.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('সব তথ্য দিন'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              if (_selectedBusinessId == null) return;

              try {
                await _firestore
                    .collection('businesses')
                    .doc(_selectedBusinessId)
                    .collection('products')
                    .add({
                  'name': nameController.text.trim(),
                  'quantity': int.parse(quantityController.text),
                  'price': double.parse(priceController.text),
                  'note': noteController.text.trim(),
                  'totalValue': int.parse(quantityController.text) * double.parse(priceController.text),
                  'status': 'available',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('পণ্য যোগ করা হয়েছে'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ত্রুটি: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSellProductDialog(Map<String, dynamic> product, String docId) async {
    final quantityController = TextEditingController();
    final customerController = TextEditingController();
    final priceController = TextEditingController(text: product['price'].toString());

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product['name']} বিক্রি'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerController,
              decoration: const InputDecoration(
                labelText: 'ক্রেতার নাম *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'পরিমাণ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'বিক্রয় মূল্য',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (customerController.text.isEmpty ||
                  quantityController.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ক্রেতার নাম ও পরিমাণ দিন'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              int sellQuantity = int.parse(quantityController.text);
              if (sellQuantity > product['quantity']) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('স্টকে পর্যাপ্ত পণ্য নেই'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              if (_selectedBusinessId == null) return;

              try {
                final remainingQuantity = product['quantity'] - sellQuantity;
                
                if (remainingQuantity == 0) {
                  await _firestore
                      .collection('businesses')
                      .doc(_selectedBusinessId)
                      .collection('products')
                      .doc(docId)
                      .delete();
                } else {
                  await _firestore
                      .collection('businesses')
                      .doc(_selectedBusinessId)
                      .collection('products')
                      .doc(docId)
                      .update({
                    'quantity': remainingQuantity,
                    'totalValue': remainingQuantity * (product['price'] as num).toDouble(),
                  });
                }

                await _firestore
                    .collection('businesses')
                    .doc(_selectedBusinessId)
                    .collection('sales')
                    .add({
                  'productName': product['name'],
                  'quantity': sellQuantity,
                  'price': double.parse(priceController.text),
                  'total': sellQuantity * double.parse(priceController.text),
                  'customer': customerController.text.trim(),
                  'date': DateTime.now().toIso8601String(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('বিক্রয় সম্পন্ন হয়েছে'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ত্রুটি: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('বিক্রি করুন'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProductDialog(Map<String, dynamic> product, String docId) async {
    final nameController = TextEditingController(text: product['name']);
    final quantityController = TextEditingController(text: product['quantity'].toString());
    final priceController = TextEditingController(text: product['price'].toString());
    final noteController = TextEditingController(text: product['note'] ?? '');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('পণ্য এডিট করুন'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'পণ্যের নাম',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'পরিমাণ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'মূল্য',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'বিবরণ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedBusinessId == null) return;

              try {
                await _firestore
                    .collection('businesses')
                    .doc(_selectedBusinessId)
                    .collection('products')
                    .doc(docId)
                    .update({
                  'name': nameController.text.trim(),
                  'quantity': int.parse(quantityController.text),
                  'price': double.parse(priceController.text),
                  'note': noteController.text.trim(),
                  'totalValue': int.parse(quantityController.text) * double.parse(priceController.text),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('পণ্য আপডেট করা হয়েছে'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ত্রুটি: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('আপডেট'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProductStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBusinessId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('স্টক হিসাব'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('কোনো ব্যবসা নির্বাচন করা হয়নি'),
              SizedBox(height: 8),
              Text('মাল্টি ব্যাবসা থেকে এলাকা সিলেক্ট করুন'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('স্টক হিসাব'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('businesses')
                .doc(_selectedBusinessId)
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              int totalItems = 0;
              double totalValue = 0;
              int totalQuantity = 0;

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalItems++;
                
                if (data['quantity'] != null) {
                  totalQuantity += data['quantity'] as int;
                }
                
                if (data['totalValue'] != null) {
                  if (data['totalValue'] is int) {
                    totalValue += (data['totalValue'] as int).toDouble();
                  } else if (data['totalValue'] is double) {
                    totalValue += data['totalValue'] as double;
                  }
                }
              }

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryCard('মোট আইটেম', totalItems.toString(), Icons.inventory),
                        _buildSummaryCard('মোট পরিমাণ', totalQuantity.toString(), Icons.numbers),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'মোট মূল্য',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '৳ ${totalValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('সব'),
                    selected: _filterType == 'all',
                    onSelected: (selected) => setState(() => _filterType = 'all'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('স্টকে আছে'),
                    selected: _filterType == 'available',
                    onSelected: (selected) => setState(() => _filterType = 'available'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('বিক্রি হয়েছে'),
                    selected: _filterType == 'sold',
                    onSelected: (selected) => setState(() => _filterType = 'sold'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'পণ্য খুঁজুন...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('businesses')
                  .doc(_selectedBusinessId)
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('কোনো পণ্য নেই'),
                        SizedBox(height: 8),
                        Text('+ বাটন ক্লিক করে পণ্য যোগ করুন'),
                      ],
                    ),
                  );
                }

                var products = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  
                  if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                    return false;
                  }
                  
                  return true;
                }).toList();

                if (products.isEmpty) {
                  return const Center(child: Text('কোনো পণ্য পাওয়া যায়নি'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.inventory, color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (data['note'] != null && data['note'].isNotEmpty)
                                        Text(
                                          data['note'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.sell, color: Colors.green),
                                      onPressed: () => _showSellProductDialog(data, doc.id),
                                      tooltip: 'বিক্রি',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditProductDialog(data, doc.id),
                                      tooltip: 'এডিট',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildProductStat(
                                  'পরিমাণ',
                                  data['quantity'].toString(),
                                  Icons.numbers,
                                  Colors.blue,
                                ),
                                _buildProductStat(
                                  'দাম',
                                  '৳ ${data['price']}',
                                  Icons.attach_money,
                                  Colors.green,
                                ),
                                _buildProductStat(
                                  'মোট',
                                  '৳ ${data['totalValue']}',
                                  Icons.calculate,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}