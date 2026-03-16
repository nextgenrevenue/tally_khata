import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MultiBusinessPage extends StatefulWidget {
  const MultiBusinessPage({super.key});

  @override
  State<MultiBusinessPage> createState() => _MultiBusinessPageState();
}

class _MultiBusinessPageState extends State<MultiBusinessPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBusinessId;
  
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalCashBara = 0;
  double _totalCashKena = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedBusiness();
  }

  Stream<QuerySnapshot> _getUserBusinesses() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    
    return _firestore
        .collection('businesses')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> _loadSelectedBusiness() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
      final businessId = userDoc.data()!['selectedBusinessId'];
      
      setState(() {
        _selectedBusinessId = businessId;
      });
      _loadBusinessData(businessId);
    }
  }

  Future<void> _saveSelectedBusiness(String businessId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'selectedBusinessId': businessId,
    });

    setState(() {
      _selectedBusinessId = businessId;
    });
    
    _loadBusinessData(businessId);
  }

  Future<void> _loadBusinessData(String businessId) async {
    try {
      final entriesSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('entries')
          .get();
          
      double income = 0;
      double expense = 0;

      for (var doc in entriesSnapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'income') {
          income += (data['amount'] ?? 0).toDouble();
        } else {
          expense += (data['amount'] ?? 0).toDouble();
        }
      }

      final cashSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('cash_transactions')
          .get();
          
      double cashBara = 0;
      double cashKena = 0;

      for (var doc in cashSnapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'cash_bara') {
          cashBara += (data['amount'] ?? 0).toDouble();
        }
        if (data['type'] == 'cash_kena') {
          cashKena += (data['amount'] ?? 0).toDouble();
        }
      }

      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _totalCashBara = cashBara;
        _totalCashKena = cashKena;
      });
    } catch (e) {
      debugPrint('Error loading business data: $e');
    }
  }

  Future<void> _createBusiness(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('businesses').add({
      'userId': user.uid,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showAddBusinessDialog() async {
    final controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন এলাকা যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('এলাকার নাম দিন (যেমন: মাদারিপুর, খুলনা, ঢাকা)'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'এলাকার নাম',
              ),
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
              if (controller.text.isNotEmpty) {
                await _createBusiness(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${controller.text.trim()} যোগ করা হয়েছে'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '৳ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('মাল্টি ব্যাবসা'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBusinessDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserBusinesses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final businesses = snapshot.data?.docs ?? [];

          if (businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.business,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'কোনো এলাকা যোগ করা হয়নি',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'নিচের বাটন ক্লিক করে এলাকা যোগ করুন',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddBusinessDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('নতুন এলাকা যোগ করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final doc = businesses[index];
              final data = doc.data() as Map<String, dynamic>;
              final businessName = data['name'] ?? 'নামহীন';
              final isSelected = doc.id == _selectedBusinessId;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? const BorderSide(color: Colors.green, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () async {
                    await _saveSelectedBusiness(doc.id);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$businessName সিলেক্ট করা হয়েছে'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: isSelected ? Colors.green : Colors.grey,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    businessName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.green : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['createdAt'] != null ? 'যোগ করা হয়েছে' : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        
                        if (isSelected) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'মোট আয়',
                                  _totalIncome,
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  'মোট ব্যয়',
                                  _totalExpense,
                                  Icons.trending_down,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'ক্যাশ বেচা',
                                  _totalCashBara,
                                  Icons.money,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  'ক্যাশ কেনা',
                                  _totalCashKena,
                                  Icons.shopping_cart,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}