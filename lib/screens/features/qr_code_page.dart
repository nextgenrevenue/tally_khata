import 'package:flutter/material.dart';

class QRCodePage extends StatelessWidget {
  const QRCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR কোড'),
        backgroundColor: Colors.indigo,
      ),
      body: const Center(
        child: Text('QR কোড পেজ তৈরি হচ্ছে...'),
      ),
    );
  }
}