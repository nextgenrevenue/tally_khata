import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_entry_screen.dart';
import 'reports_screen.dart';
import 'categories_screen.dart';
import 'profile_page.dart';
import 'shop_list_page.dart'; // দোকান তালিকা পেজ ইম্পোর্ট
import 'create_invoice_page.dart';

// ফিচার পেজ ইম্পোর্ট
import 'features/multi_business_page.dart';
import 'features/stock_hisab_page.dart';
import 'features/business_note_page.dart';
import 'features/group_tagada_page.dart';
import 'features/qr_code_page.dart';
import 'features/data_backup_page.dart';
import 'features/tally_message_page.dart';
import 'features/cash_box_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference _entriesCollection = 
      FirebaseFirestore.instance.collection('entries');
  final CollectionReference _shopsCollection = 
      FirebaseFirestore.instance.collection('shops');
  
  bool _isLoading = true;
  String _userName = 'ব্যবহারকারী';
  String _currentLocation = '';
  List<DocumentSnapshot> _entries = [];
  List<DocumentSnapshot> _recentShops = []; // সাম্প্রতিক দোকান

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadUserData();
    _loadCurrentLocation();
    _loadRecentShops();
  }

  Future<void> _loadCurrentLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
        final businessId = userDoc.data()!['selectedBusinessId'];
        final businessDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .get();
            
        if (businessDoc.exists) {
          final data = businessDoc.data();
          if (data != null && mounted) {
            setState(() {
              _currentLocation = data['name'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading location: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && mounted) {
            setState(() {
              _userName = data['name'] ?? user.displayName ?? 'ব্যবহারকারী';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userName = user.displayName ?? 'ব্যবহারকারী';
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        if (mounted) {
          setState(() {
            _userName = user.displayName ?? 'ব্যবহারকারী';
          });
        }
      }
    }
  }

  Future<void> _loadEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _entriesCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(5) // সর্বোচ্চ ৫টি এন্ট্রি
          .get();

      if (mounted) {
        setState(() {
          _entries = snapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading entries: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentShops() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _shopsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5) // সর্বোচ্চ ৫টি দোকান
          .get();

      if (mounted) {
        setState(() {
          _recentShops = snapshot.docs;
        });
      }
    } catch (e) {
      debugPrint('Error loading shops: $e');
    }
  }

  Future<void> _refreshLocation() async {
    await _loadCurrentLocation();
  }

  void _navigateToShopDetail(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailPage(
          shopData: data,
          shopId: doc.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: _currentLocation.isEmpty
            ? const Text(
                'ট্যালি খাতা',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _currentLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userName.length > 8 
                          ? '${_userName.substring(0, 8)}...' 
                          : _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadEntries();
                await _loadRecentShops();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ব্যবসার ফিচারসমূহ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ফিচার গ্রিড
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildFeatureItemWithNav(Icons.business, 'মাল্টি ব্যাবসা', Colors.green, const MultiBusinessPage()),
                          _buildFeatureItemWithNav(Icons.calculate, 'স্টক হিসাব', Colors.blue, const StockHisabPage()),
                          _buildFeatureItemWithNav(Icons.note_alt, 'ব্যবসার নোট', Colors.purple, const BusinessNotePage()),
                          _buildFeatureItemWithNav(Icons.group, 'গ্রুপ তাগাদা', Colors.orange, const GroupTagadaPage()), 
                          _buildFeatureItemWithNav(Icons.qr_code_scanner, 'QR কোড', Colors.indigo, const QRCodePage()),
                          _buildFeatureItemWithNav(Icons.backup, 'ডাটা ব্যাকআপ', Colors.teal, const DataBackupPage()),
                          _buildFeatureItemWithNav(Icons.message, 'ট্যালি মেসেজ', Colors.pink, const TallyMessagePage()),
                          _buildFeatureItemWithNav(Icons.payments, 'ক্যাশ বক্স', Colors.amber, const CashBoxPage()),
                        ],
                      ),
                    ),

                    // কুইক অ্যাকশন বাটন
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.add_circle,
                              label: 'নতুন হিসাব',
                              color: Colors.green,
                              page: const AddEntryScreen(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.bar_chart,
                              label: 'রিপোর্ট',
                              color: Colors.orange,
                              page: const ReportsScreen(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.category,
                              label: 'ক্যাটাগরি',
                              color: Colors.purple,
                              page: const CategoriesScreen(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // দোকানের লেনদেন শিরোনাম
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'সাম্প্রতিক দোকান',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ShopListPage()),
                              );
                            },
                            child: const Text('সব দেখুন →'),
                          ),
                        ],
                      ),
                    ),

                    // দোকানের তালিকা
                    _recentShops.isEmpty
                        ? Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'কোনো দোকান নেই',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'দোকান যোগ করুন',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _recentShops.length,
                            itemBuilder: (context, index) {
                              final doc = _recentShops[index];
                              final data = doc.data() as Map<String, dynamic>?;
                              
                              if (data == null) return const SizedBox();
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  onTap: () => _navigateToShopDetail(doc),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                                    child: const Icon(Icons.store, color: Colors.green),
                                  ),
                                  title: Text(
                                    data['shopName'] ?? 'নাম নেই',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('মালিক: ${data['ownerName'] ?? 'নেই'}'),
                                      Text('মোবাইল: ${data['mobile'] ?? 'নেই'}'),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: data['status'] == 'active'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      data['status'] == 'active' ? 'সক্রিয়' : 'নিষ্ক্রিয়',
                                      style: TextStyle(
                                        color: data['status'] == 'active'
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                    // সাম্প্রতিক লেনদেন শিরোনাম
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'সাম্প্রতিক লেনদেন',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // এন্ট্রি লিস্ট
                    _entries.isEmpty
                        ? Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'কোনো লেনদেন নেই',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'নতুন হিসাব যোগ করুন',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final doc = _entries[index];
                              final data = doc.data() as Map<String, dynamic>?;
                              
                              if (data == null) return const SizedBox();
                              
                              final dateStr = data['date'] as String?;
                              final title = data['title'] as String? ?? '';
                              final amount = data['amount'] as num? ?? 0;
                              final category = data['category'] as String? ?? '';
                              final type = data['type'] as String? ?? 'expense';
                              
                              DateTime date;
                              try {
                                date = DateTime.parse(dateStr ?? DateTime.now().toIso8601String());
                              } catch (e) {
                                date = DateTime.now();
                              }
                              
                              final isIncome = type == 'income';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isIncome 
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    child: Icon(
                                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isIncome ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormat('dd MMM yyyy').format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '৳ $amount',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isIncome ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      if (category.isNotEmpty)
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // সব দেখুন বাটন
                    if (_entries.length > 5)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/reports');
                          },
                          child: const Text('সব লেনদেন দেখুন →'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureItemWithNav(IconData icon, String label, Color color, Widget page) {
    return GestureDetector(
      onTap: () async {
        if (page is MultiBusinessPage) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
          _refreshLocation();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
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
      ),
    );
  }
}

// দোকানের বিস্তারিত পেজ
class ShopDetailPage extends StatelessWidget {
  final Map<String, dynamic> shopData;
  final String shopId;

  const ShopDetailPage({
    super.key,
    required this.shopData,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shopData['shopName'] ?? 'দোকানের বিবরণ'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEntryScreen(
                    shopData: shopData,
                    shopId: shopId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    const Text(
                      'দোকানের তথ্য',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow('দোকানের নাম', shopData['shopName']),
                    _buildDetailRow('মালিকের নাম', shopData['ownerName']),
                    _buildDetailRow('মোবাইল', shopData['mobile']),
                    _buildDetailRow('ঠিকানা', shopData['address']),
                    _buildDetailRow('এলাকা', shopData['area']),
                    _buildDetailRow('ধরন', shopData['shopType']),
                    _buildDetailRow('স্ট্যাটাস', shopData['status'] == 'active' ? 'সক্রিয়' : 'নিষ্ক্রিয়'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'আর্থিক তথ্য',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow('মোট বাকি', '৳ ${shopData['totalDue']?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow('মোট পরিশোধ', '৳ ${shopData['totalPaid']?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow('মোট অর্ডার', shopData['totalOrders']?.toString() ?? '0'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateInvoicePage(
                            shopData: shopData,
                            shopId: shopId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt),
                    label: const Text('ইনভয়েস তৈরি'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'নেই',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}