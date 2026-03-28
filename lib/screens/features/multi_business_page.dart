// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_declarations
// ignore_for_file: prefer_final_fields

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
  
  // Business data maps
  final Map<String, double> _businessIncome = {};
  final Map<String, double> _businessExpense = {};
  final Map<String, double> _businessCashBara = {};
  final Map<String, double> _businessCashKena = {};
  
  // Loading states
  final Map<String, bool> _loadingData = {};
  bool _isLoadingSelected = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadSelectedBusiness();
    await _loadAllBusinessData();
  }

  Stream<QuerySnapshot> _getUserBusinesses() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    
    return _firestore
        .collection('businesses')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _loadSelectedBusiness() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoadingSelected = false);
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
        setState(() {
          _selectedBusinessId = userDoc.data()!['selectedBusinessId'];
          _isLoadingSelected = false;
        });
      } else {
        setState(() => _isLoadingSelected = false);
      }
    } catch (e) {
      debugPrint('Error loading selected business: $e');
      setState(() => _isLoadingSelected = false);
      if (mounted) {
        _showErrorSnackBar('সিলেক্টেড ব্যবসা লোড করতে সমস্যা হয়েছে');
      }
    }
  }

  Future<void> _loadAllBusinessData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final businesses = await _firestore
          .collection('businesses')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var business in businesses.docs) {
        final businessId = business.id;
        _loadingData[businessId] = true;
        
        if (mounted) setState(() {});
        
        await Future.wait([
          _loadBusinessEntries(businessId),
          _loadBusinessCashTransactions(businessId),
        ]);
        
        _loadingData[businessId] = false;
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading all business data: $e');
      if (mounted) {
        _showErrorSnackBar('ব্যবসার ডাটা লোড করতে সমস্যা হয়েছে');
      }
    }
  }

  Future<void> _loadBusinessEntries(String businessId) async {
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
        } else if (data['type'] == 'expense') {
          expense += (data['amount'] ?? 0).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _businessIncome[businessId] = income;
          _businessExpense[businessId] = expense;
        });
      }
    } catch (e) {
      debugPrint('Error loading entries for $businessId: $e');
    }
  }

  Future<void> _loadBusinessCashTransactions(String businessId) async {
    try {
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

      if (mounted) {
        setState(() {
          _businessCashBara[businessId] = cashBara;
          _businessCashKena[businessId] = cashKena;
        });
      }
    } catch (e) {
      debugPrint('Error loading cash transactions for $businessId: $e');
    }
  }

  Future<void> _refreshBusinessData(String businessId) async {
    setState(() {
      _loadingData[businessId] = true;
    });
    
    await Future.wait([
      _loadBusinessEntries(businessId),
      _loadBusinessCashTransactions(businessId),
    ]);
    
    if (mounted) {
      setState(() {
        _loadingData[businessId] = false;
      });
    }
  }

  Future<void> _saveSelectedBusiness(String businessId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'selectedBusinessId': businessId,
      }, SetOptions(merge: true));

      setState(() {
        _selectedBusinessId = businessId;
      });
      
      await _refreshBusinessData(businessId);
      
      if (mounted) {
        _showSuccessSnackBar('ব্যবসা সিলেক্ট করা হয়েছে');
      }
    } catch (e) {
      debugPrint('Error saving selected business: $e');
      if (mounted) {
        _showErrorSnackBar('সিলেক্ট করতে সমস্যা হয়েছে');
      }
    }
  }

  Future<void> _createBusiness(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = await _firestore.collection('businesses').add({
        'userId': user.uid,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _businessIncome[docRef.id] = 0;
          _businessExpense[docRef.id] = 0;
          _businessCashBara[docRef.id] = 0;
          _businessCashKena[docRef.id] = 0;
          _loadingData[docRef.id] = false;
        });
        
        _showSuccessSnackBar('$name যোগ করা হয়েছে');
      }
    } catch (e) {
      debugPrint('Error creating business: $e');
      if (mounted) {
        _showErrorSnackBar('ব্যবসা যোগ করতে সমস্যা হয়েছে');
      }
    }
  }

  Future<void> _deleteBusiness(String businessId, String businessName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ব্যবসা মুছুন'),
        content: Text('আপনি কি "$businessName" মুছতে চান?\n\nসতর্কতা: এই ব্যবসার সমস্ত ডাটা মুছে যাবে!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      // Delete all entries
      final entries = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('entries')
          .get();
          
      for (var doc in entries.docs) {
        await doc.reference.delete();
      }
      
      // Delete all cash transactions
      final cashTransactions = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('cash_transactions')
          .get();
          
      for (var doc in cashTransactions.docs) {
        await doc.reference.delete();
      }
      
      // Delete the business
      await _firestore.collection('businesses').doc(businessId).delete();
      
      // Remove from maps
      if (mounted) {
        setState(() {
          _businessIncome.remove(businessId);
          _businessExpense.remove(businessId);
          _businessCashBara.remove(businessId);
          _businessCashKena.remove(businessId);
          _loadingData.remove(businessId);
          
          if (_selectedBusinessId == businessId) {
            _selectedBusinessId = null;
          }
        });
        
        _showSuccessSnackBar('$businessName মুছে ফেলা হয়েছে');
      }
    } catch (e) {
      debugPrint('Error deleting business: $e');
      if (mounted) {
        _showErrorSnackBar('ব্যবসা মুছতে সমস্যা হয়েছে');
      }
    }
  }

  Future<void> _showAddBusinessDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন এলাকা যোগ করুন'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'এলাকার নাম দিন (যেমন: মাদারিপুর, খুলনা, ঢাকা)',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'এলাকার নাম',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'এলাকার নাম দিন';
                  }
                  if (value.length < 2) {
                    return 'নাম কমপক্ষে ২ অক্ষরের হতে হবে';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                await _createBusiness(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
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

  void _showBusinessOptions(BuildContext context, String businessId, String businessName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('নাম পরিবর্তন করুন'),
              onTap: () {
                Navigator.pop(context);
                _showEditBusinessDialog(businessId, businessName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.green),
              title: const Text('ডাটা রিফ্রেশ করুন'),
              onTap: () {
                Navigator.pop(context);
                _refreshBusinessData(businessId);
                _showSuccessSnackBar('ডাটা রিফ্রেশ করা হচ্ছে');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('মুছে ফেলুন', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteBusiness(businessId, businessName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditBusinessDialog(String businessId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('এলাকার নাম পরিবর্তন করুন'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'নতুন নাম',
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'এলাকার নাম দিন';
              }
              if (value.length < 2) {
                return 'নাম কমপক্ষে ২ অক্ষরের হতে হবে';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _firestore.collection('businesses').doc(businessId).update({
                    'name': controller.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSuccessSnackBar('নাম পরিবর্তন করা হয়েছে');
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showErrorSnackBar('নাম পরিবর্তন করতে সমস্যা হয়েছে');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '৳ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'আমার এলাকাসমূহ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBusinessDialog,
            tooltip: 'নতুন এলাকা যোগ করুন',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserBusinesses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeData,
                    child: const Text('পুনরায় চেষ্টা করুন'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting && _isLoadingSelected) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('লোড হচ্ছে...'),
                ],
              ),
            );
          }

          final businesses = snapshot.data?.docs ?? [];

          if (businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'কোনো এলাকা যোগ করা হয়নি',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'আপনার ব্যবসার এলাকা যোগ করুন',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddBusinessDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('নতুন এলাকা যোগ করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadAllBusinessData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final doc = businesses[index];
                final data = doc.data() as Map<String, dynamic>;
                final businessName = data['name'] ?? 'নামহীন';
                final businessId = doc.id;
                final isSelected = businessId == _selectedBusinessId;
                final isLoading = _loadingData[businessId] ?? false;

                final income = _businessIncome[businessId] ?? 0;
                final expense = _businessExpense[businessId] ?? 0;
                final cashBara = _businessCashBara[businessId] ?? 0;
                final cashKena = _businessCashKena[businessId] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: isSelected ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isSelected
                        ? const BorderSide(color: Colors.green, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () async {
                      await _saveSelectedBusiness(businessId);
                    },
                    onLongPress: () {
                      _showBusinessOptions(context, businessId, businessName);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: isSelected ? Colors.green : Colors.grey[600],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            businessName,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected ? Colors.green : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isLoading)
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'যোগ করা হয়েছে: ${_formatDate(data['createdAt'])}',
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    _showBusinessOptions(context, businessId, businessName);
                                  },
                                ),
                            ],
                          ),
                          
                          if (isSelected) ...[
                            const Divider(height: 24),
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      'মোট আয়',
                                      income,
                                      Icons.trending_up,
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoCard(
                                      'মোট ব্যয়',
                                      expense,
                                      Icons.trending_down,
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      'ক্যাশ বেচা',
                                      cashBara,
                                      Icons.money_off,
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoCard(
                                      'ক্যাশ কেনা',
                                      cashKena,
                                      Icons.shopping_cart,
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'হাতে নগদ',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '৳ ${(cashBara - cashKena).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'তারিখ নেই';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'আজ';
      } else if (difference.inDays == 1) {
        return 'গতকাল';
      } else if (difference.inDays < 7) {
        return '${{difference.inDays}} দিন আগে';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'তারিখ নেই';
    }
  }
}