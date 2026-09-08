import 'dart:math' as math;

Map<String, dynamic> generatePuzzleData(int removeCount) {
  final rng = math.Random(DateTime.now().millisecondsSinceEpoch);

  List<List<int>> makeEmptyBoard() =>
      List.generate(9, (_) => List.filled(9, 0));

  bool canPlace(List<List<int>> board, int row, int col, int value) {
    for (var i = 0; i < 9; i++) {
      if (board[row][i] == value || board[i][col] == value) return false;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var rowOffset = 0; rowOffset < 3; rowOffset++) {
      for (var colOffset = 0; colOffset < 3; colOffset++) {
        if (board[boxRow + rowOffset][boxCol + colOffset] == value) {
          return false;
        }
      }
    }
    return true;
  }

  bool fillBoard(List<List<int>> board, int index) {
    if (index >= 81) return true;
    final row = index ~/ 9;
    final col = index % 9;
    if (board[row][col] != 0) return fillBoard(board, index + 1);

    final numbers = List<int>.generate(9, (i) => i + 1)..shuffle(rng);
    for (final number in numbers) {
      if (canPlace(board, row, col, number)) {
        board[row][col] = number;
        if (fillBoard(board, index + 1)) return true;
        board[row][col] = 0;
      }
    }
    return false;
  }

  final solved = makeEmptyBoard();
  fillBoard(solved, 0);

  final puzzle = solved.map((row) => List<int>.from(row)).toList();
  final removed = <int>{};
  final maxRemove = math.min(math.max(removeCount, 0), 81);
  final indices = List<int>.generate(81, (i) => i)..shuffle(rng);

  for (var i = 0; i < maxRemove; i++) {
    final index = indices[i];
    final row = index ~/ 9;
    final col = index % 9;
    if (puzzle[row][col] != 0) {
      puzzle[row][col] = 0;
      removed.add(index);
    }
  }

  return {'solved': solved, 'puzzle': puzzle, 'missing': removed.toList()};
}
