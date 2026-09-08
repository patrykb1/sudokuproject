import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: Column(
        children: [
          Text('Signed in as: ${FirebaseAuth.instance.currentUser?.email ?? 'unknown'}'),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await FirebaseAuth.instance.signOut();
              await prefs.setString('sudoku_current_user', '');
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Sign Out'),
          ),],
      ),
    );
  }
}