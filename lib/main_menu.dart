import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_page.dart';
import 'leaderboard_page.dart';
import 'sudoku_page.dart';
import 'global_variables.dart';
import 'account_page.dart';
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  String? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _currentUser = user.email;
      });
    }
    else{
      setState(() {
        _currentUser = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Main Menu')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentUser != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Signed in as: $_currentUser'),
              )
            else 
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Not signed in'),
              ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final choice = await showDialog<int>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Choose difficulty'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 35),
                        child: const Text('Easy'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 45),
                        child: const Text('Medium'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 55),
                        child: const Text('Hard'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 64),
                        child: const Text('Impossible'),
                      ),
                    ],
                  ),
                );

                if (choice != null) {
                  final difficultyLabel = switch (choice) {
                    35 => 'easy',
                    45 => 'medium',
                    55 => 'hard',
                    64 => 'impossible',
                    _ => 'normal',
                  };

                  await navigator.push(
                    MaterialPageRoute(
                      builder: (_) => SudokuPage(
                        title: 'Sudoku Solver',
                        removeCount: choice,
                        difficulty: difficultyLabel,
                      ),
                    ),
                  );
                  _loadCurrentUser();
                }
              },
              child: const Text('Play Sudoku'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final didPop = await Navigator.of(context).maybePop();
                if (!didPop) {
                  SystemNavigator.pop();
                }
              },
              child: const Text('Close'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (_currentUser != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SudokuPage(
                      title: 'Infinite Mode',
                      removeCount: 45,
                      infiniteMode: true,
                    ),
                  ),
                );
                _loadCurrentUser();}
                else {
                  //display message to sign in first
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to access Infinite Mode.'),
                    ),
                  );
                }
              },
              child: const Text('Infinite Mode'),
            ),
            ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => user == null
                      ? const SignInPage()
                      : const AccountPage(),
                ),
              );
              _loadCurrentUser();
            },
            child: const Text('Account'),
          ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                );
                _loadCurrentUser();
              },
              child: const Text('Leaderboard'),
            ),
          ],
        ),
      ),
    );
  }
}
