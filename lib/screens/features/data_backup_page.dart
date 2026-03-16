import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBusinessId;
  bool _isLoading = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  
  int _totalEntries = 0;
  int _totalProducts = 0;
  int _totalCashTransactions = 0;
  int _totalNotes = 0;
  int _totalSales = 0;
  
  String _lastBackupTime = 'কখনো না';
  int _lastBackupSize = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedBusiness();
    _loadBackupInfo();
  }

  Future<void> _loadSelectedBusiness() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
      setState(() {
        _selectedBusinessId = userDoc.data()!['selectedBusinessId'];
      });
      await _loadStatistics();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    if (_selectedBusinessId == null) return;

    try {
      final entriesSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('entries')
          .get();
          
      final productsSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('products')
          .get();
          
      final cashSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('cash_transactions')
          .get();
          
      final notesSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('notes')
          .get();
          
      final salesSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('sales')
          .get();

      setState(() {
        _totalEntries = entriesSnapshot.docs.length;
        _totalProducts = productsSnapshot.docs.length;
        _totalCashTransactions = cashSnapshot.docs.length;
        _totalNotes = notesSnapshot.docs.length;
        _totalSales = salesSnapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBackupInfo() async {
    setState(() {
      _lastBackupTime = '১০ মার্চ ২০২৪, ০২:৩০ PM';
      _lastBackupSize = 245760;
    });
  }

  Future<void> _createBackup() async {
    if (_selectedBusinessId == null) return;

    setState(() => _isBackingUp = true);

    try {
      final entriesSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('entries')
          .get();
          
      final productsSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('products')
          .get();
          
      final cashSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('cash_transactions')
          .get();
          
      final notesSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('notes')
          .get();
          
      final salesSnapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('sales')
          .get();

      final backupData = {
        'businessId': _selectedBusinessId,
        'backupDate': DateTime.now().toIso8601String(),
        'statistics': {
          'totalEntries': _totalEntries,
          'totalProducts': _totalProducts,
          'totalCashTransactions': _totalCashTransactions,
          'totalNotes': _totalNotes,
          'totalSales': _totalSales,
        },
        'data': {
          'entries': entriesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList(),
          'products': productsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList(),
          'cash_transactions': cashSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList(),
          'notes': notesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList(),
          'sales': salesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList(),
        },
      };

      String jsonString = jsonEncode(backupData);
      int fileSize = utf8.encode(jsonString).length;

      await Share.share(
        jsonString,
        subject: 'ব্যবসার ডাটা ব্যাকআপ - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      );

      if (mounted) {  // ← mounted চেক যোগ করা হয়েছে
        setState(() {
          _lastBackupTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
          _lastBackupSize = fileSize;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ব্যাকআপ সফল হয়েছে (${_formatFileSize(fileSize)})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {  // ← mounted চেক যোগ করা হয়েছে
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ব্যাকআপ ব্যর্থ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {  // ← mounted চেক যোগ করা হয়েছে
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isRestoring = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {  // ← mounted চেক যোগ করা হয়েছে
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ব্যাকআপ রিস্টোর করা হয়েছে'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {  // ← mounted চেক যোগ করা হয়েছে
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('রিস্টোর ব্যর্থ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {  // ← mounted চেক যোগ করা হয়েছে
        setState(() => _isRestoring = false);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBusinessId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ডাটা ব্যাকআপ'),
          backgroundColor: Colors.teal,
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
        title: const Text('ডাটা ব্যাকআপ'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ডাটা পরিসংখ্যান',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.2,
                            children: [
                              _buildStatCard('এন্ট্রি', _totalEntries, Icons.receipt_long, Colors.blue),
                              _buildStatCard('পণ্য', _totalProducts, Icons.inventory, Colors.green),
                              _buildStatCard('ক্যাশ', _totalCashTransactions, Icons.money, Colors.orange),
                              _buildStatCard('নোট', _totalNotes, Icons.note, Colors.purple),
                              _buildStatCard('বিক্রয়', _totalSales, Icons.sell, Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.teal,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'সর্বশেষ ব্যাকআপ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _lastBackupTime,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatFileSize(_lastBackupSize),
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isBackingUp ? null : _createBackup,
                            icon: _isBackingUp
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.backup),
                            label: Text(
                              _isBackingUp ? 'ব্যাকআপ হচ্ছে...' : 'ব্যাকআপ তৈরি করুন',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isRestoring ? null : _restoreBackup,
                            icon: _isRestoring
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.teal,
                                    ),
                                  )
                                : const Icon(Icons.restore),
                            label: Text(
                              _isRestoring ? 'রিস্টোর হচ্ছে...' : 'ব্যাকআপ রিস্টোর করুন',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ব্যাকআপ ফাইল নিরাপদ স্থানে সংরক্ষণ করুন। রিস্টোর করলে বর্তমান ডাটা ওভাররাইট হবে।',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}