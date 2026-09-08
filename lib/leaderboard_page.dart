import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Future<Map<String, dynamic>> _loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sudoku_leaderboard');
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadLeaderboard(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final scores =
              (data['top_scores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final puzzles =
              (data['top_puzzles'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Top Scores',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, i) {
                      final entry = scores[i];
                      return ListTile(
                        title: Text(entry['user'] ?? 'unknown'),
                        trailing: Text('${entry['score'] ?? 0}'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Most Puzzles (Infinite)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: puzzles.length,
                    itemBuilder: (context, i) {
                      final entry = puzzles[i];
                      return ListTile(
                        title: Text(entry['user'] ?? 'unknown'),
                        trailing: Text('${entry['puzzles'] ?? 0}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
