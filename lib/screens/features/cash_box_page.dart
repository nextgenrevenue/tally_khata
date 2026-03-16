// ignore_for_file: prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashBoxPage extends StatefulWidget {
  const CashBoxPage({super.key});

  @override
  State<CashBoxPage> createState() => _CashBoxPageState();
}

class _CashBoxPageState extends State<CashBoxPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _currentLocationId;
  late CollectionReference _cashCollection;
  
  double _totalCashBara = 0;
  double _totalCashKena = 0;
  double _totalKhoroch = 0;
  double _totalMalikDil = 0;
  double _totalMalikNil = 0;
  double _ajkerPela = 0;
  double _ajkerDilam = 0;
  double _bakiAdai = 0;        // ← এই ফিল্ড পরে বদলাবে, তাই final করা যাবে না
  double _paymentDeowa = 0;     // ← এই ফিল্ড পরে বদলাবে, তাই final করা যাবে না
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
      final locationId = userDoc.data()!['selectedBusinessId'];
      
      setState(() {
        _currentLocationId = locationId;
        _isLoading = false;
      });
      
      if (locationId != null) {
        _cashCollection = _firestore
            .collection('businesses')
            .doc(locationId)
            .collection('cash_transactions');
        _loadCashData();
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCashData() async {
    if (_currentLocationId == null) return;

    try {
      final snapshot = await _cashCollection.get();

      double cashBara = 0;
      double cashKena = 0;
      double khoroch = 0;
      double malikDil = 0;
      double malikNil = 0;
      double ajkerPela = 0;
      double ajkerDilam = 0;

      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] as String;
        final amount = (data['amount'] ?? 0).toDouble();
        final date = data['date'] as String;

        switch (type) {
          case 'cash_bara':
            cashBara += amount;
            break;
          case 'cash_kena':
            cashKena += amount;
            break;
          case 'khoroch':
            khoroch += amount;
            break;
          case 'malik_dil':
            malikDil += amount;
            break;
          case 'malik_nil':
            malikNil += amount;
            break;
        }

        if (date.startsWith(todayStr)) {
          if (type == 'ajker_pela') ajkerPela += amount;
          if (type == 'ajker_dilam') ajkerDilam += amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalCashBara = cashBara;
          _totalCashKena = cashKena;
          _totalKhoroch = khoroch;
          _totalMalikDil = malikDil;
          _totalMalikNil = malikNil;
          _ajkerPela = ajkerPela;
          _ajkerDilam = ajkerDilam;
        });
      }
    } catch (e) {
      debugPrint('Error loading cash data: $e');
    }
  }

  Future<void> _addTransaction(String type, String title) async {
    if (_currentLocationId == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'পরিমাণ (টাকা)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'নোট (ঐচ্ছিক)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
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
              if (amountController.text.isEmpty) return;

              try {
                await _cashCollection.add({
                  'type': type,
                  'amount': double.parse(amountController.text),
                  'note': noteController.text,
                  'date': DateTime.now().toIso8601String(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadCashData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('লেনদেন যোগ করা হয়েছে'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ব্যর্থ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  void _showMilaiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ক্যাশ বক্স মিলান'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMilaiRow('ক্যাশ বেচা', _totalCashBara),
            _buildMilaiRow('ক্যাশ কেনা', _totalCashKena),
            _buildMilaiRow('খরচ', _totalKhoroch),
            _buildMilaiRow('মালিক দিল', _totalMalikDil),
            _buildMilaiRow('মালিক নিল', _totalMalikNil),
            const Divider(),
            _buildMilaiRow(
              'ব্যালেন্স',
              _totalCashBara - _totalCashKena - _totalKhoroch + _totalMalikDil - _totalMalikNil,
              isTotal: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  Widget _buildMilaiRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '৳ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal 
                  ? (amount >= 0 ? Colors.green : Colors.red)
                  : Colors.black,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(String title, double amount, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '৳ ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '৳ $value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashOptionCard(String title, double amount, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '৳ ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    if (_currentLocationId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: _cashCollection
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final transactions = snapshot.data!.docs;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'সাম্প্রতিক লেনদেন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...transactions.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = DateTime.parse(data['date']);
                final type = data['type'] as String;
                final amount = data['amount'] as num;
                final note = data['note'] ?? '';

                String typeName = '';
                Color typeColor = Colors.grey;
                switch (type) {
                  case 'cash_bara':
                    typeName = 'ক্যাশ বড়া';
                    typeColor = Colors.green;
                    break;
                  case 'cash_kena':
                    typeName = 'ক্যাশ কেনা';
                    typeColor = Colors.blue;
                    break;
                  case 'khoroch':
                    typeName = 'খরচ';
                    typeColor = Colors.red;
                    break;
                  case 'malik_dil':
                    typeName = 'মালিক দিল';
                    typeColor = Colors.orange;
                    break;
                  case 'malik_nil':
                    typeName = 'মালিক নিল';
                    typeColor = Colors.purple;
                    break;
                  case 'ajker_pela':
                    typeName = 'আজ পেলাম';
                    typeColor = Colors.green;
                    break;
                  case 'ajker_dilam':
                    typeName = 'আজ দিলাম';
                    typeColor = Colors.red;
                    break;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            typeName[0],
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              typeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (note.isNotEmpty)
                              Text(
                                note,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '৳ ${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM, hh:mm a').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'ক্যাশ বক্স',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCashData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocationId == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('কোনো এলাকা নির্বাচন করা হয়নি'),
                      SizedBox(height: 8),
                      Text('মাল্টি ব্যাবসা থেকে এলাকা সিলেক্ট করুন'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCashData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.amberAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'আজকের হিসাব',  
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'বর্তমান ক্যাশ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTodayCard(
                                  'আজ পেলাম',
                                  _ajkerPela,
                                  Icons.arrow_downward,
                                  Colors.green,
                                  () => _addTransaction('ajker_pela', 'আজ পেলাম'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTodayCard(
                                  'আজ দিলাম',
                                  _ajkerDilam,
                                  Icons.arrow_upward,
                                  Colors.red,
                                  () => _addTransaction('ajker_dilam', 'আজ দিলাম'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'রিপোর্ট',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _showMilaiDialog,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.compare_arrows,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'ক্যাশ বক্স মিলান',
                                            style: TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildReportItem(
                                      'বাকি আদায়',
                                      _bakiAdai.toStringAsFixed(2),
                                      Icons.receipt,
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildReportItem(
                                      'পেমেন্ট দেওয়া',
                                      _paymentDeowa.toStringAsFixed(2),
                                      Icons.payment,
                                      Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.5,
                            children: [
                              _buildCashOptionCard(
                                'ক্যাশ বড়া',
                                _totalCashBara,
                                Icons.money,
                                Colors.green,
                                () => _addTransaction('cash_bara', 'ক্যাশ বড়া'),
                              ),
                              _buildCashOptionCard(
                                'ক্যাশ কেনা',
                                _totalCashKena,
                                Icons.shopping_cart,
                                Colors.blue,
                                () => _addTransaction('cash_kena', 'ক্যাশ কেনা'),
                              ),
                              _buildCashOptionCard(
                                'খরচ',
                                _totalKhoroch,
                                Icons.receipt_long,
                                Colors.red,
                                () => _addTransaction('khoroch', 'খরচ'),
                              ),
                              _buildCashOptionCard(
                                'মালিক দিল',
                                _totalMalikDil,
                                Icons.arrow_downward,
                                Colors.orange,
                                () => _addTransaction('malik_dil', 'মালিক দিল'),
                              ),
                              _buildCashOptionCard(
                                'মালিক নিল',
                                _totalMalikNil,
                                Icons.arrow_upward,
                                Colors.purple,
                                () => _addTransaction('malik_nil', 'মালিক নিল'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildTransactionHistory(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}