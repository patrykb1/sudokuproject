import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import "sudoku_board.dart";
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku solver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainMenu(),
    );
  }
}

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUser = prefs.getString('sudoku_current_user');
    });
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
                  String difficultyLabel;
                  switch (choice) {
                    case 35:
                      difficultyLabel = 'easy';
                      break;
                    case 45:
                      difficultyLabel = 'medium';
                      break;
                    case 55:
                      difficultyLabel = 'hard';
                      break;
                    case 64:
                      difficultyLabel = 'impossible';
                      break;
                    default:
                      difficultyLabel = 'normal';
                  }

                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => SudokuPage(
                        title: 'Sudoku Solver',
                        removeCount: choice,
                        difficulty: difficultyLabel,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Play Sudoku'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Try to pop a route first; if there's nothing to pop, exit the app.
                final didPop = await Navigator.of(context).maybePop();
                if (!didPop) {
                  SystemNavigator.pop();
                }
              },
              child: const Text('Close'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SudokuPage(
                      title: 'Infinite Mode',
                      // initial removeCount; each puzzle may randomize server-side
                      removeCount: 45,
                      infiniteMode: true,
                    ),
                  ),
                );
              },
              child: const Text("Infinite Mode"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignInPage(),
                  ),
                );
                _loadCurrentUser();
              },
              child: const Text('Account'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LeaderboardPage(),
                  ),
                );
              },
              child: const Text('Leaderboard'),
            ),
          ],
        ),
      ),
    );
  }
}

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
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!;
          final scores = (data['top_scores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final puzzles = (data['top_puzzles'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Top Scores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, i) {
                      final e = scores[i];
                      return ListTile(
                        title: Text(e['user'] ?? 'unknown'),
                        trailing: Text('${e['score'] ?? 0}'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Most Puzzles (Infinite)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: puzzles.length,
                    itemBuilder: (context, i) {
                      final e = puzzles[i];
                      return ListTile(
                        title: Text(e['user'] ?? 'unknown'),
                        trailing: Text('${e['puzzles'] ?? 0}'),
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

class SudokuPage extends StatefulWidget {
  const SudokuPage({
    super.key,
    required this.title,
    this.removeCount = 45,
    this.infiniteMode = false,
    this.difficulty = 'normal',
  });
  final String title;
  final int removeCount;
  final bool infiniteMode;
  final String difficulty;

  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _users = [];
  String? _current;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // Initialize GoogleSignIn and listen for authentication events so
    // interactive sign-in results are handled centrally by the listener.
    final signIn = GoogleSignIn.instance;
    signIn.initialize().then((_) {
      signIn.authenticationEvents.listen((event) async {
        GoogleSignInAccount? user;
        if (event is GoogleSignInAuthenticationEventSignIn) {
          user = event.user;
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          user = null;
        }

        if (user != null) {
          final name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : (user.email ?? 'GoogleUser');

          if (!_users.contains(name)) {
            setState(() {
              _users.add(name);
            });
            await _saveUsersList();
          }

          await _saveCurrentUser(name);

          if (mounted) Navigator.of(context).pop();
        }
      }).onError((e) {
        if (kDebugMode) print('Authentication event error: $e');
      });

      signIn.attemptLightweightAuthentication();
    });
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sudoku_users');
    final current = prefs.getString('sudoku_current_user');
    List<String> users = [];
    if (raw != null) {
      try {
        users = List<String>.from(jsonDecode(raw) as List);
      } catch (_) {}
    }
    setState(() {
      _users = users;
      _current = current;
    });
  }

  Future<void> _saveCurrentUser(String user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sudoku_current_user', user);
  }

  Future<void> _saveUsersList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sudoku_users', jsonEncode(_users));
  }

  void _selectUser(String user) async {
    await _saveCurrentUser(user);
    setState(() {
      _current = user;
    });
    if (mounted) Navigator.of(context).pop();
  }

  void _createOrSignIn() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a username')));
      return;
    }
    if (!_users.contains(name)) {
      setState(() {
        _users.add(name);
      });
      await _saveUsersList();
    }
    await _saveCurrentUser(name);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final signIn = GoogleSignIn.instance;

      if (signIn.supportsAuthenticate()) {
        try {
          await signIn.authenticate();
        } catch (e) {
          if (kDebugMode) print('authenticate() failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google sign-in failed')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interactive Google sign-in not available on this platform')),
          );
        }
      }

      // The authenticationEvents listener handles saving the signed-in
      // user and closing the sign-in screen; nothing further to do here.
    } catch (e) {
      if (kDebugMode) print('Google sign-in failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _createOrSignIn,
              child: const Text('Create / Sign in'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: _signInWithGoogle,
            ),
            const SizedBox(height: 16),
            const Text('Existing accounts:'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, i) {
                  final u = _users[i];
                  return ListTile(
                    title: Text(u),
                    trailing: _current == u ? const Text('Signed in') : null,
                    onTap: () => _selectUser(u),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SudokuPageState extends State<SudokuPage> {
  // Example partially filled board (start with empty grids so UI can render
  // immediately while puzzle generation finishes in background)
  SudokuBoard board = SudokuBoard(List.generate(9, (_) => List.filled(9, 0)));
  SudokuBoard solvedBoard = SudokuBoard(
    List.generate(9, (_) => List.filled(9, 0)),
  );
  Timer? timer;
  int puzzlesCompleted = 0;
  int score = 0;
  int scoreAtPuzzleStart = 0;
  int infiniteRemoveCount = 30;
  int? selectedRow;
  int? selectedCol;
  int? invalidRow;
  int? invalidCol;
  Set<int> invalidCells = {};
  Set<int> completeCells = {};
  int mistakes = 0;
  int secondsElapsed = 0;
  bool noteMode = false;
  // no loading flag; UI shows immediately

  // Build a single cell widget
  Widget buildCell(int value, int row, int col, double size) {
    final key = row * 9 + col;
    final cellNotes = board.cellNotes[key] ?? <int>{};
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedRow = row;
          selectedCol = col;
        });
      },

      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        margin: EdgeInsets.all(size * 0.02),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              width: row % 3 == 0 ? size * 0.06 : size * 0.02,
              color: Colors.black,
            ),
            left: BorderSide(
              width: col % 3 == 0 ? size * 0.06 : size * 0.02,
              color: Colors.black,
            ),
            right: BorderSide(
              width: (col + 1) % 3 == 0 ? size * 0.06 : size * 0.02,
              color: Colors.black,
            ),
            bottom: BorderSide(
              width: (row + 1) % 3 == 0 ? size * 0.06 : size * 0.02,
              color: Colors.black,
            ),
          ),
          color: (row == selectedRow && col == selectedCol)
              ? const Color.fromARGB(255, 54, 237, 192)
              : isCellHighlighted(row, col)
              ? const Color.fromARGB(255, 180, 233, 223)
              : Colors.white,
        ),
        child: value == 0
            ? buildNotesGrid(cellNotes, size)
            : Text(
                value.toString(),
                style: TextStyle(
                  fontSize: size * 0.45,
                  color: invalidCells.contains(key)
                      ? const Color.fromARGB(255, 244, 54, 54)
                      : completeCells.contains(key)
                      ? Colors.green
                      : selectedRow != null && selectedCol != null && board.board[selectedRow!][selectedCol!] == value ? Colors.blue : Colors.black,
                ),
              ),
      ),
    );
  }

  Widget buildNotesGrid(Set<int> notes, double size) {
    final small = size / 3.5; // adjust to fit nicely
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (r) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (c) {
              final num = r * 3 + c + 1;
              return SizedBox(
                width: small,
                height: small,
                child: Center(
                  child: Text(
                    notes.contains(num) ? num.toString() : '',
                    style: TextStyle(
                      fontSize: small * 0.8,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // Build the full 9x9 board. If `forcedSize` is provided, use it to
  // precisely size the board so overall UI can be constrained to fit.
  Widget buildBoard({double? forcedSize}) {
    if (forcedSize != null) {
      final boardSize = forcedSize;
      const marginRatio = 0.02; // same ratio used in buildCell margin
      final cellSize = boardSize / (9 + 18 * marginRatio);
      return SizedBox(
        width: boardSize,
        height: boardSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(9, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(9, (col) {
                return buildCell(board.board[row][col], row, col, cellSize);
              }),
            );
          }),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth * 0.9;
        const marginRatio = 0.02;
        final cellSize = boardSize / (9 + 18 * marginRatio);

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(9, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(9, (col) {
                  return buildCell(board.board[row][col], row, col, cellSize);
                }),
              );
            }),
          ),
        );
      },
    );
  }

  Widget buildNumberBar(double boardSize, double cellSize) {
    const marginRatio = 0.02;
    final slotWidth = cellSize * (1 + 2 * marginRatio);

    return SizedBox(
      width: boardSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(9, (i) {
          final num = i + 1;
          return SizedBox(
            width: slotWidth,
            height: slotWidth,
            child: Center(
              child: SizedBox(
                width: cellSize,
                height: cellSize,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    if (selectedCol == null || selectedRow == null) return;
                    final key = selectedRow! * 9 + selectedCol!;
                    setState(() {
                      if (!board.isEditableCell(selectedRow!, selectedCol!)) {
                        return;
                      }
                      if (noteMode) {
                        board.toggleNote(num, selectedRow!, selectedCol!);
                        return;
                      }
                      if (solvedBoard.board[selectedRow!][selectedCol!] ==
                          num) {
                        board.insertEntry(num, selectedRow!, selectedCol!);
                        invalidCells.remove(key);
                        board.missingCells.remove(key);
                        completeCells.add(key);
                        // reward for correct entry
                        score += 10;
                        _checkCompletion();
                        _saveState();
                      } else {
                        board.insertEntry(
                          num,
                          selectedRow!,
                          selectedCol!,
                          override: true,
                        );
                        _handleMistake(key);
                        // save state already handled by _handleMistake
                      }
                    });
                  },
                  child: Text(
                    num.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: cellSize * 0.45),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return _buildMobileLayout(constraints);
          } else {
            return _buildDesktopLayout(constraints);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    final availableHeight = constraints.maxHeight;
    const infoRowHeight = 48.0;
    const spacing = 16.0; // space between board and number bar
    const verticalPadding = 16.0;

    // Compute a boardSize that fits vertically with the number bar.
    final maxBoardByWidth = constraints.maxWidth * 0.9;
    final boardSizeByHeight =
        math.max(
          0.0,
          (availableHeight - infoRowHeight - spacing - verticalPadding),
        ) *
        9 /
        10;
    final boardSize = math.min(maxBoardByWidth, boardSizeByHeight);
    const marginRatio = 0.02;
    final cellSize = boardSize / (9 + 18 * marginRatio);

    return SizedBox(
      height: availableHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: infoRowHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                      Text("Mistakes: $mistakes"),
                const SizedBox(width: 20),
                Text("Score: $score"),
                const SizedBox(width: 20),
                Text("Time elapsed: ${formatTime(secondsElapsed)}"),
              ],
            ),
          ),
          buildBoard(forcedSize: boardSize),
          SizedBox(height: spacing),
          buildNumberBar(boardSize, cellSize),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                //Clear Button
                children: [
                  IconButton(
                    icon: Icon(Icons.backspace),
                    tooltip: "Clear cell",
                    onPressed: () {
                      if (selectedRow == null || selectedCol == null) return;
                      final key = selectedRow! * 9 + selectedCol!;
                      if (!board.missingCells.contains(key)) return;
                      setState(() {
                        board.insertEntry(
                          0,
                          selectedRow ?? 0,
                          selectedCol ?? 0,
                          override: true,
                        );
                        // keep visual state consistent
                        invalidCells.remove(key);
                      });
                      _saveState();
                    },
                  ),
                  Text("Clear", style: TextStyle(fontSize: 12)),
                ],
              ),
              Column(
                //Note Mode Toggle
                children: [
              IconButton(
                icon: Icon(noteMode ? Icons.edit_note : Icons.edit),
                tooltip: noteMode ? 'Note mode on' : 'Note mode off',
                onPressed: () => setState(() => noteMode = !noteMode),
              ),
              Text("Note Mode: ${noteMode ? "On" : "Off"}", style: TextStyle(fontSize: 12)),
                ],
              ),
              Column(
                //Give Up Button
                children: [
              IconButton(
                icon: Icon(Icons.flag),
                tooltip: "Give up",
                onPressed: () {
                  // revert score to the value at the start of this puzzle,
                  // reveal solution, mark as 3 mistakes and trigger game over
                  setState(() {
                    score = scoreAtPuzzleStart;
                    mistakes = 3;
                    board.replaceWithSolvedBoard(
                      board,
                      solvedBoard.board,
                      completeCells,
                    );
                    invalidCells.clear();
                  });
                  _saveState();
                  _gameOver();
                },
              ),
              Text("Give up?", style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final availableHeight = constraints.maxHeight;
    final maxBoardByWidth = math.min(500.0, constraints.maxWidth * 0.9);
    const spacing = 24.0;
    const verticalPadding = 32.0;

    final boardSizeByHeight =
        math.max(0.0, (availableHeight - spacing - verticalPadding)) * 9 / 10;
    final boardSize = math.min(maxBoardByWidth, boardSizeByHeight);
    const marginRatio = 0.02;
    final cellSize = boardSize / (9 + 18 * marginRatio);

    return SizedBox(
      height: availableHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: boardSize,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Score: $score"),
                    Text("Mistakes: $mistakes"),
                    Text("Time: ${formatTime(secondsElapsed)}"),
                  ],
                ),
                const SizedBox(height: 8),
                buildBoard(forcedSize: boardSize),
              ],
            ),
          ),
          SizedBox(height: spacing),
          buildNumberBar(boardSize, cellSize),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // initialize infinite mode progression
    if (widget.infiniteMode) {
      infiniteRemoveCount = 30; // start easy
    }
    // Try to load a saved state; if none, prepare a fresh puzzle
    _loadState().then((loaded) async {
      if (!loaded) {
        await _preparePuzzle();
      } else {
        if (mistakes >= 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _gameOver();
          });
          return;
        }

        // start timer to continue tracking time
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() {
            secondsElapsed++;
          });
          _saveState();
        });
      }
    });
  }

  Future<void> _preparePuzzle() async {
    // Let the UI render before heavy work starts
    await Future<void>.delayed(Duration.zero);

    // cancel any existing timer before starting a fresh puzzle
    timer?.cancel();

    // Generate puzzle off the UI thread using an isolate.
    // For infinite mode, use the progressing `infiniteRemoveCount` value.
    final removeCount = widget.infiniteMode
      ? math.min(64, math.max(0, infiniteRemoveCount))
      : widget.removeCount;

    final result = await compute(generatePuzzleData, removeCount);

    // Reconstruct SudokuBoard objects from plain lists returned by the
    // background isolate.
    final solvedList = (result['solved'] as List)
        .map<List<int>>((r) => List<int>.from(r as List))
        .toList();
    final puzzleList = (result['puzzle'] as List)
        .map<List<int>>((r) => List<int>.from(r as List))
        .toList();
    final missing = (result['missing'] as List).cast<int>();

    solvedBoard = SudokuBoard(solvedList);
    board = SudokuBoard(puzzleList);
    board.missingCells.addAll(missing);

    // record the score at the start of this puzzle so "Give Up" can revert
    scoreAtPuzzleStart = score;

    if (!mounted) return;

    setState(() {
      secondsElapsed = 0;
    });

    // save the freshly prepared puzzle state
    _saveState();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        secondsElapsed++;
      });
      // save every second as requested
      _saveState();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    // try to submit leaderboard on exit (non-blocking)
    _submitLeaderboardEntry();
    super.dispose();
  }

  Future<void> _submitLeaderboardEntry() async {
    // Only record leaderboard entries for infinite mode and when a user is signed in
    if (!widget.infiniteMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('sudoku_current_user');
      if (user == null || user.isEmpty) return;

      final raw = prefs.getString('sudoku_leaderboard');
      Map<String, dynamic> data = {};
      if (raw != null) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {
          data = {};
        }
      }

      List<Map<String, dynamic>> topScores = (data['top_scores'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];
      List<Map<String, dynamic>> topPuzzles = (data['top_puzzles'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];

      // Update top scores (keep highest score per user)
      final existingScore = topScores.indexWhere((e) => e['user'] == user);
      if (existingScore >= 0) {
        final prev = (topScores[existingScore]['score'] as int?) ?? 0;
        if (score > prev) topScores[existingScore]['score'] = score;
      } else {
        topScores.add({'user': user, 'score': score});
      }
      topScores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      if (topScores.length > 10) topScores = topScores.sublist(0, 10);

      // Update top puzzles (keep highest puzzles count per user)
      final existingP = topPuzzles.indexWhere((e) => e['user'] == user);
      if (existingP >= 0) {
        final prev = (topPuzzles[existingP]['puzzles'] as int?) ?? 0;
        if (puzzlesCompleted > prev) topPuzzles[existingP]['puzzles'] = puzzlesCompleted;
      } else {
        topPuzzles.add({'user': user, 'puzzles': puzzlesCompleted});
      }
      topPuzzles.sort((a, b) => (b['puzzles'] as int).compareTo(a['puzzles'] as int));
      if (topPuzzles.length > 10) topPuzzles = topPuzzles.sublist(0, 10);

      data['top_scores'] = topScores;
      data['top_puzzles'] = topPuzzles;

      await prefs.setString('sudoku_leaderboard', jsonEncode(data));
    } catch (e) {
      if (kDebugMode) print('Failed to submit leaderboard: $e');
    }
  }

  bool isCellHighlighted(int row, int col) {
    if (selectedRow == null || selectedCol == null) return false;
    final key = row * 9 + col;
    if (board.surroundingCells(selectedRow!, selectedCol!).contains(key)) {
      return true; // same row, column, or box
    }
    return false;
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Called when the board is finished (no missing cells remain)
  void onComplete() {
      if (widget.infiniteMode) {
      // start the next puzzle immediately
      setState(() {
        puzzlesCompleted++;
        mistakes = 0;
        invalidCells.clear();
        completeCells.clear();
        selectedRow = null;
        selectedCol = null;
          secondsElapsed = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Puzzle complete — loading next puzzle...")),
        );
      }
        // increase difficulty for next puzzle (cap at 64)
        infiniteRemoveCount = math.min(64, infiniteRemoveCount + 1);

        // persist progression before loading next puzzle
        _saveState();

        _preparePuzzle();
      return;
    }

    timer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Congratulations — board complete!")),
      );
    }
  }

  void _handleMistake(int key) {
    setState(() {
      invalidCells.add(key);
      mistakes += 1;
      score = math.max(0, score - 2);
    });

    // persist mistake and score
    _saveState();

    if (mistakes >= 3) {
      _gameOver();
    }
  }

  Future<void> _gameOver() async {
    timer?.cancel();

    // submit leaderboard (if applicable) before showing dialog
    await _submitLeaderboardEntry();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('You made 3 mistakes. Final score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                mistakes = 0;
                score = 0;
                invalidCells.clear();
                completeCells.clear();
                selectedRow = null;
                selectedCol = null;
                secondsElapsed = 0;
              });
              _saveState();
              _preparePuzzle();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Main Menu'),
          ),
        ],
      ),
    );
  }

  // Internal helper to check completion and call onComplete
  void _checkCompletion() {
    if (board.missingCells.isEmpty) {
      onComplete();
    }
  }

  // Persistence helpers
  String get _storageKey {
    if (widget.infiniteMode) return 'sudoku_state_infinite';
    final diff = (widget.difficulty.isEmpty) ? 'normal' : widget.difficulty;
    return 'sudoku_state_$diff';
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {
        'board': board.board,
        'solved': solvedBoard.board,
        'missing': board.missingCells.toList(),
        'cellNotes': board.cellNotes.map((k, v) => MapEntry(k.toString(), v.toList())),
        'secondsElapsed': secondsElapsed,
        'mistakes': mistakes,
        'score': score,
        'scoreAtPuzzleStart': scoreAtPuzzleStart,
        'infiniteRemoveCount': infiniteRemoveCount,
        'puzzlesCompleted': puzzlesCompleted,
        'infiniteMode': widget.infiniteMode,
      };

      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) print('Failed to save state: $e');
    }
  }

  Future<bool> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? raw = prefs.getString(_storageKey);

      // Do not fall back to the other mode's save. Each mode must keep its
      // state separate so switching modes doesn't load the wrong progress.
      if (raw == null) return false;
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;

      final solvedList = (data['solved'] as List)
          .map<List<int>>((r) => List<int>.from(r as List))
          .toList();
      final puzzleList = (data['board'] as List)
          .map<List<int>>((r) => List<int>.from(r as List))
          .toList();

      final missing = (data['missing'] as List).cast<int>();

      final cellNotesRaw = (data['cellNotes'] as Map?) ?? {};

      setState(() {
        solvedBoard = SudokuBoard(solvedList);
        board = SudokuBoard(puzzleList);
        board.missingCells.clear();
        board.missingCells.addAll(missing);
        board.cellNotes.clear();
        cellNotesRaw.forEach((k, v) {
          board.cellNotes[int.parse(k)] = Set<int>.from((v as List).cast<int>());
        });

        secondsElapsed = (data['secondsElapsed'] as int?) ?? 0;
        mistakes = (data['mistakes'] as int?) ?? 0;
        score = (data['score'] as int?) ?? 0;
        scoreAtPuzzleStart = (data['scoreAtPuzzleStart'] as int?) ?? score;
        infiniteRemoveCount = (data['infiniteRemoveCount'] as int?) ?? infiniteRemoveCount;
        puzzlesCompleted = (data['puzzlesCompleted'] as int?) ?? 0;
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to load state: $e');
      return false;
    }
  }
}

// Generate a full solved Sudoku and produce a puzzle by removing cells.
// This runs inside an isolate when called via compute, so it must be a top-level function.
Map<String, dynamic> generatePuzzleData(int removeCount) {
  final rng = math.Random(DateTime.now().millisecondsSinceEpoch);

  List<List<int>> makeEmptyBoard() =>
      List.generate(9, (_) => List.filled(9, 0));

  bool canPlace(List<List<int>> board, int r, int c, int val) {
    for (int i = 0; i < 9; i++) {
      if (board[r][i] == val) return false;
      if (board[i][c] == val) return false;
    }
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[br + i][bc + j] == val) return false;
      }
    }
    return true;
  }

  bool fillBoard(List<List<int>> board, int idx) {
    if (idx >= 81) return true;
    final r = idx ~/ 9;
    final c = idx % 9;
    if (board[r][c] != 0) return fillBoard(board, idx + 1);

    final nums = List<int>.generate(9, (i) => i + 1)..shuffle(rng);
    for (final n in nums) {
      if (canPlace(board, r, c, n)) {
        board[r][c] = n;
        if (fillBoard(board, idx + 1)) return true;
        board[r][c] = 0;
      }
    }
    return false;
  }

  final solved = makeEmptyBoard();
  // generate a complete solved board
  fillBoard(solved, 0);

  // create puzzle by removing cells
  final puzzle = solved.map((r) => List<int>.from(r)).toList();
  final removed = <int>{};
  final maxRemove = math.min(math.max(removeCount, 0), 81);
  final indices = List<int>.generate(81, (i) => i)..shuffle(rng);

  for (int i = 0; i < maxRemove; i++) {
    final idx = indices[i];
    final rr = idx ~/ 9;
    final cc = idx % 9;
    if (puzzle[rr][cc] != 0) {
      puzzle[rr][cc] = 0;
      removed.add(rr * 9 + cc);
    }
  }

  return {'solved': solved, 'puzzle': puzzle, 'missing': removed.toList()};
}
