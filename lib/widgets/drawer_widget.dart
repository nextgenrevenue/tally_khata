import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green, Colors.greenAccent]),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.green)),
                  const SizedBox(height: 10),
                  Text(user?.displayName ?? 'ব্যবহারকারী', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(leading: const Icon(Icons.home, color: Colors.green), title: const Text('হোম'), onTap: () => Navigator.pop(context)),
                ListTile(leading: const Icon(Icons.bar_chart, color: Colors.green), title: const Text('রিপোর্ট'), onTap: () => Navigator.pop(context)),
                ListTile(leading: const Icon(Icons.category, color: Colors.green), title: const Text('ক্যাটাগরি'), onTap: () => Navigator.pop(context)),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('লগআউট', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}