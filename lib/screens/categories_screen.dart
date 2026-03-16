import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ক্যাটাগরি'), backgroundColor: Colors.green),
      body: const Center(child: Text('ক্যাটাগরি পেজ তৈরি হচ্ছে...')),
    );
  }
}