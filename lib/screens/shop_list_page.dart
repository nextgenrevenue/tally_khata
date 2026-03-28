import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_entry_screen.dart';
import 'create_invoice_page.dart';

class ShopListPage extends StatefulWidget {
  final String businessId;
  final String businessName;
  
  const ShopListPage({
    super.key, 
    required this.businessId,
    required this.businessName,
  });

  @override
  State<ShopListPage> createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage> {
  late final CollectionReference _shopsCollection;
  late final String _businessId;

  @override
  void initState() {
    super.initState();
    _businessId = widget.businessId;
    _shopsCollection = FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .collection('shops');
  }

  Future<void> _deleteShop(String shopId) async {
    try {
      final entries = await _shopsCollection
          .doc(shopId)
          .collection('entries')
          .get();
          
      for (var entry in entries.docs) {
        await entry.reference.delete();
      }
      
      final cashTransactions = await _shopsCollection
          .doc(shopId)
          .collection('cash_transactions')
          .get();
          
      for (var cash in cashTransactions.docs) {
        await cash.reference.delete();
      }
      
      await _shopsCollection.doc(shopId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('দোকান ডিলিট করা হয়েছে'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ডিলিট করতে ব্যর্থ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String shopId, String shopName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নিশ্চিত করুন'),
        content: Text('$shopName ডিলিট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShop(shopId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ডিলিট'),
          ),
        ],
      ),
    );
  }

  void _editShop(Map<String, dynamic> shopData, String shopId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(
          shopData: shopData,
          shopId: shopId,
          businessId: _businessId,
        ),
      ),
    );
  }

  void _createInvoice(Map<String, dynamic> shop, String shopId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoicePage(
          shopData: shop,
          shopId: shopId,
          businessId: _businessId,
        ),
      ),
    );
  }

  Future<void> _addShop() async {
    final shopNameController = TextEditingController();
    final ownerNameController = TextEditingController();
    final mobileController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.businessName} - নতুন দোকান যোগ করুন'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: shopNameController,
                decoration: const InputDecoration(
                  labelText: 'দোকানের নাম',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'দোকানের নাম দিন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'মালিকের নাম',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'মোবাইল নম্বর',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
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
                try {
                  await _shopsCollection.add({
                    'shopName': shopNameController.text.trim(),
                    'ownerName': ownerNameController.text.trim(),
                    'mobile': mobileController.text.trim(),
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'businessId': _businessId,
                    'status': 'active',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${shopNameController.text.trim()} যোগ করা হয়েছে'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('দোকান যোগ করতে ব্যর্থ: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('লগইন করুন')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.businessName} - দোকান তালিকা'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addShop,
            tooltip: 'নতুন দোকান যোগ করুন',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _shopsCollection
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'কোনো দোকান নেই',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ডান পাশের + বাটন ক্লিক করে দোকান যোগ করুন',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
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
                          if (data['ownerName'] != null && data['ownerName'].toString().isNotEmpty)
                            Text('মালিক: ${data['ownerName']}'),
                          if (data['mobile'] != null && data['mobile'].toString().isNotEmpty)
                            Text('মোবাইল: ${data['mobile']}'),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editShop(data, doc.id),
                          tooltip: 'সম্পাদনা করুন',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(doc.id, data['shopName'] ?? ''),
                          tooltip: 'ডিলিট করুন',
                        ),
                        IconButton(
                          icon: const Icon(Icons.receipt, color: Colors.green),
                          onPressed: () => _createInvoice(data, doc.id),
                          tooltip: 'ইনভয়েস তৈরি করুন',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}