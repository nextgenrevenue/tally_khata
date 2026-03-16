import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BusinessNotePage extends StatefulWidget {
  const BusinessNotePage({super.key});

  @override
  State<BusinessNotePage> createState() => _BusinessNotePageState();
}

class _BusinessNotePageState extends State<BusinessNotePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBusinessId;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedBusiness();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedBusiness() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('selectedBusinessId')) {
        setState(() {
          _selectedBusinessId = userDoc.data()!['selectedBusinessId'];
        });
        _loadNotes();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading selected business: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotes() async {
    if (_selectedBusinessId == null) return;

    try {
      final snapshot = await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedNotes = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        loadedNotes.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'date': data['date'] ?? DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        setState(() {
          _notes = loadedNotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    if (_selectedBusinessId == null || _noteController.text.isEmpty) return;

    try {
      await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('notes')
          .add({
        'content': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
      });

      _noteController.clear();
      _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('নোট সংরক্ষিত হয়েছে'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    if (_selectedBusinessId == null) return;

    try {
      await _firestore
          .collection('businesses')
          .doc(_selectedBusinessId)
          .collection('notes')
          .doc(noteId)
          .delete();

      _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('নোট ডিলিট করা হয়েছে'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নিশ্চিত করুন'),
        content: const Text('এই নোটটি ডিলিট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(noteId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('ডিলিট'),
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
          title: const Text('ব্যবসার নোট'),
          backgroundColor: Colors.purple, // ← পার্পল
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
        title: const Text('ব্যবসার নোট'),
        backgroundColor: Colors.purple, // ← পার্পল
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // নোট লেখার অংশ
                Container(
                  margin: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _noteController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'আপনার নোট লিখুন...',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Colors.purple, width: 2), // ← পার্পল
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _saveNote,
                        icon: const Icon(Icons.save),
                        label: const Text('নোট সংরক্ষণ করুন'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple, // ← পার্পল
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // সংরক্ষিত নোটের তালিকা
                Expanded(
                  child: _notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'কোনো নোট নেই',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'উপরে নোট লিখুন',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            final date = note['date'] != null
                                ? DateTime.parse(note['date'])
                                : DateTime.now();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withValues(alpha: 0.1), // ← পার্পল
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.note,
                                            color: Colors.purple, // ← পার্পল
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            note['content'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () => _showDeleteConfirmation(note['id']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
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
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}