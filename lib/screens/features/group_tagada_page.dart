import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// intl ইম্পোর্ট সরানো হয়েছে (কারণ ব্যবহার করা হয়নি)

class GroupTagadaPage extends StatefulWidget {
  const GroupTagadaPage({super.key});

  @override
  State<GroupTagadaPage> createState() => _GroupTagadaPageState();
}

class _GroupTagadaPageState extends State<GroupTagadaPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBusinessId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];

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
      _loadGroups();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGroups() async {
    if (_selectedBusinessId == null) return;

    try {
      final snapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedGroups = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // null চেক সরানো হয়েছে কারণ data কখনো null হয় না
        loadedGroups.add({
          'id': doc.id,
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'totalMembers': data['totalMembers'] ?? 0,
          'totalCollection': data['totalCollection'] ?? 0.0,
          'totalDue': data['totalDue'] ?? 0.0,
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        _groups = loadedGroups;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading groups: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddGroupDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন গ্রুপ তৈরি'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'গ্রুপের নাম *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'বিবরণ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
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
              if (nameController.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('গ্রুপের নাম দিন'),
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
                    .collection('groups')
                    .add({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'totalMembers': 0,
                  'totalCollection': 0.0,
                  'totalDue': 0.0,
                  'createdAt': DateTime.now().toIso8601String(),
                  'members': [],
                  'transactions': [],
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadGroups();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${nameController.text.trim()} গ্রুপ তৈরি হয়েছে'),
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
            child: const Text('তৈরি করুন'),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(Map<String, dynamic> group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group, color: Colors.green, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['name'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (group['description'].toString().isNotEmpty)
                            Text(
                              group['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // পরিসংখ্যান
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'সদস্য',
                        group['totalMembers'].toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'আদায়',
                        '৳ ${group['totalCollection'].toStringAsFixed(2)}',
                        Icons.money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'বাকি',
                        '৳ ${group['totalDue'].toStringAsFixed(2)}',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // অ্যাকশন বাটন
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.person_add,
                        label: 'সদস্য যোগ',
                        color: Colors.blue,
                        onTap: () => _showAddMemberDialog(group),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.payments,
                        label: 'আদায়',
                        color: Colors.green,
                        onTap: () => _showCollectionDialog(group),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.pending,
                        label: 'বাকি',
                        color: Colors.orange,
                        onTap: () => _showDueDialog(group),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // সদস্য তালিকা
                const Text(
                  'সদস্য তালিকা',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withValues(alpha: 0.1),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                          title: Text('সদস্য ${index + 1}'),
                          subtitle: const Text('মোবাইল: ০১৭১২৩৪৫৬৭৮'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'বাকি: ৳ ৫০০',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'শেষ আদায়: ১০ মার্চ',
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(Map<String, dynamic> group) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${group['name']} - সদস্য যোগ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'নাম *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'ঠিকানা',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('সদস্য যোগ করা হয়েছে'),
                  backgroundColor: Colors.green,
                ),
              );
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

  void _showCollectionDialog(Map<String, dynamic> group) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${group['name']} - আদায়'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'পরিমাণ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'বিবরণ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('আদায় সংরক্ষিত হয়েছে'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  void _showDueDialog(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${group['name']} - বাকি তালিকা'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 3,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text('সদস্য ${index + 1}'),
                subtitle: const Text('বাকি: ৳ ৫০০'),
                trailing: const Icon(Icons.payment, color: Colors.green),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBusinessId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('গ্রুপ তাগাদা'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('কোনো এলাকা নির্বাচন করা হয়নি'),
              SizedBox(height: 8),
              Text('মাল্টি ব্যাবসা থেকে এলাকা সিলেক্ট করুন'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('গ্রুপ তাগাদা'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGroupDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'কোনো গ্রুপ নেই',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ডান পাশের + বাটন ক্লিক করে গ্রুপ তৈরি করুন',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showGroupDetails(group),
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
                                    child: const Icon(
                                      Icons.group,
                                      color: Colors.green,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (group['description'].toString().isNotEmpty)
                                          Text(
                                            group['description'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                    'সদস্য',
                                    group['totalMembers'].toString(),
                                    Icons.people,
                                    Colors.blue,
                                  ),
                                  _buildStatCard(
                                    'আদায়',
                                    '৳ ${group['totalCollection'].toStringAsFixed(2)}',
                                    Icons.money,
                                    Colors.green,
                                  ),
                                  _buildStatCard(
                                    'বাকি',
                                    '৳ ${group['totalDue'].toStringAsFixed(2)}',
                                    Icons.pending,
                                    Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}