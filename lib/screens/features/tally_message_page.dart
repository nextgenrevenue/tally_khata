import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TallyMessagePage extends StatefulWidget {
  const TallyMessagePage({super.key});

  @override
  State<TallyMessagePage> createState() => _TallyMessagePageState();
}

class _TallyMessagePageState extends State<TallyMessagePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBusinessId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'all'; // all, inbox, sent

  @override
  void initState() {
    super.initState();
    _loadSelectedBusiness();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedBusiness() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
      setState(() {
        _selectedBusinessId = userDoc.data()!['selectedBusinessId'];
      });
      _loadMessages();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_selectedBusinessId == null) return;

    try {
      final snapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedMessages = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // অপ্রয়োজনীয় null চেক সরানো হয়েছে
        loadedMessages.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'sender': data['sender'] ?? 'আমি',
          'receiver': data['receiver'] ?? '',
          'type': data['type'] ?? 'inbox',
          'isRead': data['isRead'] ?? false,
          'priority': data['priority'] ?? 'normal',
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        _messages = loadedMessages;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedBusinessId == null || _messageController.text.isEmpty) return;

    setState(() {}); // UI আপডেট

    try {
      await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('messages')
          .add({
        'title': 'নতুন বার্তা',
        'content': _messageController.text.trim(),
        'sender': 'আমি',
        'receiver': 'সকল',
        'type': 'sent',
        'isRead': false,
        'priority': 'normal',
        'createdAt': DateTime.now().toIso8601String(),
      });

      _messageController.clear();
      _loadMessages();

      if (mounted) { // mounted চেক
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('বার্তা পাঠানো হয়েছে'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) { // mounted চেক
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNewMessageDialog() {
    _messageController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন বার্তা'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'বার্তা লিখুন',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
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
            onPressed: () {
              Navigator.pop(context);
              _sendMessage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
            ),
            child: const Text('পাঠান'),
          ),
        ],
      ),
    );
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['content'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'প্রেরক: ${message['sender']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(
                          DateTime.parse(message['createdAt']),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

  List<Map<String, dynamic>> _getFilteredMessages() {
    var filtered = _messages;
    
    // ট্যাব অনুযায়ী ফিল্টার
    if (_selectedTab == 'inbox') {
      filtered = filtered.where((m) => m['type'] == 'inbox').toList();
    } else if (_selectedTab == 'sent') {
      filtered = filtered.where((m) => m['type'] == 'sent').toList();
    }
    
    // সার্চ টেক্সট অনুযায়ী ফিল্টার
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((m) {
        final content = m['content'].toString().toLowerCase();
        return content.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
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
          title: const Text('ট্যালি মেসেজ'),
          backgroundColor: Colors.pink,
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

    // ফিল্টার করা মেসেজ
    final filteredMessages = _getFilteredMessages();
    
    // পরিসংখ্যান গণনা
    int totalMessages = _messages.length;
    int unreadMessages = _messages.where((m) => !m['isRead']).length;
    int sentMessages = _messages.where((m) => m['type'] == 'sent').length;
    int inboxMessages = _messages.where((m) => m['type'] == 'inbox').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ট্যালি মেসেজ'),
        backgroundColor: Colors.pink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // পরিসংখ্যান কার্ড
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.pink.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard('মোট', totalMessages, Icons.message, Colors.pink)),
                      Expanded(child: _buildStatCard('অপঠিত', unreadMessages, Icons.mark_chat_unread, Colors.orange)),
                      Expanded(child: _buildStatCard('পাঠানো', sentMessages, Icons.send, Colors.green)),
                      Expanded(child: _buildStatCard('প্রাপ্ত', inboxMessages, Icons.inbox, Colors.blue)),
                    ],
                  ),
                ),

                // সার্চ বার
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'বার্তা খুঁজুন...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),

                // ট্যাব বার
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton('সব', 'all'),
                      ),
                      Expanded(
                        child: _buildTabButton('ইনবক্স', 'inbox'),
                      ),
                      Expanded(
                        child: _buildTabButton('পাঠানো', 'sent'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // বার্তা তালিকা
                Expanded(
                  child: filteredMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mark_chat_unread,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'কোনো বার্তা নেই',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'নিচের বাটন ক্লিক করে বার্তা পাঠান',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMessages.length,
                          itemBuilder: (context, index) {
                            final message = filteredMessages[index];
                            final date = DateTime.parse(message['createdAt']);
                            final isUnread = !message['isRead'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _showMessageDetails(message),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: isUnread
                                        ? Border.all(color: Colors.pink, width: 1)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // আইকন
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: message['type'] == 'sent'
                                              ? Colors.green.withValues(alpha: 0.1)
                                              : Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          message['type'] == 'sent'
                                              ? Icons.send
                                              : Icons.inbox,
                                          color: message['type'] == 'sent'
                                              ? Colors.green
                                              : Colors.blue,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // বার্তার বিবরণ
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message['content'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('dd MMM, hh:mm a').format(date),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (message['priority'] == 'high')
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Text(
                                                      'জরুরি',
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // অপঠিত ব্যাজ
                                      if (isUnread)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.pink,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewMessageDialog,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabButton(String label, String type) {
    final isSelected = _selectedTab == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}