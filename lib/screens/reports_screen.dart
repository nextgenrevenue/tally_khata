import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট'), backgroundColor: Colors.green),
      body: const Center(child: Text('রিপোর্ট পেজ তৈরি হচ্ছে...')),
    );
  }
}