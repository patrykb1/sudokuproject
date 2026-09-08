import 'package:flutter/foundation.dart';

class SudokuBoard {
  final List<List<int>> board; //rows then columns
  final Set<int> missingCells = {}; // row*9 + col

  final Map<int, Set<int>> cellNotes = {}; // maps int key -> notes set
  SudokuBoard(this.board);
  bool isBoardValid() {
    for (var row in board) { // row check
      Set<int> seen = {};
      for (var n in row) {
        if (n != 0){
          if (seen.contains(n)) return false;
          seen.add(n);
        }
      }
    }
    for (int row = 0; row < 9; row++) { // column check
      Set<int> seen = {};
      for (int col = 0; col < 9; col++) {
        int num = board[row][col];
        if (num != 0) {
          if (seen.contains(num)) {
            return false;
          }
          seen.add(num);
        }
      }
    }
    for (int rowInBox = 0; rowInBox < 3; rowInBox++) {
      for (int colInBox = 0; colInBox < 3; colInBox++) {
        Set<int> seen = {};
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            int current = board[rowInBox * 3 + row][colInBox * 3 + col];
            if (current != 0) {
              if (seen.contains(current)) {
                return false; // duplicate in box
              }
              seen.add(current);
            }
          }
        }
      }
    }
    return true;
  }
  bool isEntryValid(int entry, int row, int column){
    if (board[row].contains(entry)) return false; //row check
    for (int testRow = 0; testRow < 9; testRow++){ // column check
      if (board[testRow][column] == entry && testRow != row) return false;
    }
    int leftMostColumn = (column ~/ 3) * 3;
    int topMostRow = (row ~/ 3) * 3;
    for (int r = topMostRow; r < topMostRow + 3; r++){
      for (int c = leftMostColumn; c < leftMostColumn + 3; c++){
        if (board[r][c] == entry && (r != row || c != column)) return false;
      }
    }
    return true;
  }

  void insertEntry(int entry, int row, int column, {bool override = false}){
    if (!isEditableCell(row,column) && !override) return;
    if (!isEntryValid(entry, row, column) && !override) return;
    board[row][column] = entry;
    removeNumberFromNotes(entry, row, column);
  }

  bool isUserInsertEntryValid(int entry, int row, int column){
    bool valid;
    if (!isEntryValid(entry, row, column)){
      valid = false;
    }
    else{
      valid = true;
    }
    board[row][column] = entry;
    return valid;
  }

  bool solve() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isEntryValid(num, row, col)) {
              board[row][col] = num;

              if (solve()) {
                return true; // solved!
              }

              board[row][col] = 0; // backtrack
            }
          }
          return false; // no valid number found, trigger backtrack
        }
      }
    }
    return true; // no empty cells left → solved
  }
  void printBoard(){

    for (var row in board){
      if (kDebugMode) {
        print(row);
      }
    }
  }
  bool fillRandomly(){
    for (int row = 0; row < 9; row++){
      for (int col = 0; col < 9; col++){
        if (board[row][col] == 0){
          List<int> nums = List.generate(9, (i) => i+1); //generates list of numbers 1-9
          nums.shuffle();

          for (int num in nums){
            if (isEntryValid(num,row,col)){
              board[row][col] = num;

              if (fillRandomly()) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }
  static SudokuBoard generateSolved(){
    List<List<int>> grid = List.generate(9,(_) => List.filled(9,0));
    SudokuBoard board = SudokuBoard(grid);
    board.fillRandomly();
    return board;
  }
  void removeNumbers(int holes) {
    List<int> positions = List.generate(81, (i) => i);
    positions.shuffle();

    int removed = 0;

    for (int pos in positions) {
      if (removed >= holes) break;

      int row = pos ~/ 9;
      int col = pos % 9;

      if (board[row][col] == 0) continue;

      int backup = board[row][col];
      board[row][col] = 0;

      if (!_hasUniqueSolution()) {
        board[row][col] = backup; // restore
      } else {
        missingCells.add(row * 9 + col);
        removed++;
      }
    }
  }
  bool _hasUniqueSolution() {
  int count = 0;

  bool solveCount() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isEntryValid(num, row, col)) {
              board[row][col] = num;

              if (solveCount()) {
                count++;
                if (count > 1) return true;
              }

              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    count++;
    return false;
  }

  solveCount();
  return count == 1;
}  bool isEditableCell(int row, int col) => missingCells.contains(row * 9 + col);
  SudokuBoard.clone(SudokuBoard other)
    : board = List.generate(
        9,
        (r) => List<int>.from(other.board[r]),
      ) {
  missingCells.addAll(other.missingCells);
}

void toggleNote(int note, int row, int col){
  int key = row * 9 + col;
  if (!cellNotes.containsKey(key)){
    cellNotes[key] = {note};
  }
  else{
    if (cellNotes[key]!.contains(note)){
      cellNotes[key]!.remove(note);
      if (cellNotes[key]!.isEmpty){
        cellNotes.remove(key);
      }
    }
    else{
      cellNotes[key]!.add(note);
    }
  }
}   
void clearNotes(int row, int col){
  int key = row * 9 + col;
  cellNotes.remove(key);
}
void clearAllNotes(){
  cellNotes.clear();
}
// Top-level helper used with `compute` to generate a solved board and a
// puzzle (with holes) in a background isolate. Returns plain serializable
// structures (lists) so they can be sent across isolates.
List<int> surroundingCells(int row, int col) {
  List<int> cells = [];
  for (int r = 0; r < 9; r++) {
    cells.add(r * 9 + col); // same column
  }
  for (int c = 0; c < 9; c++) {
    cells.add(row * 9 + c); // same row
  }
  int boxRowStart = (row ~/ 3) * 3;
  int boxColStart = (col ~/ 3) * 3;
  for (int r = boxRowStart; r < boxRowStart + 3; r++) {
    for (int c = boxColStart; c < boxColStart + 3; c++) {
      cells.add(r * 9 + c); // same box
    }
  }
  return cells.toSet().toList(); // remove duplicates and return
}
void removeNumberFromNotes(int number, int row, int col) {
  // Get all surrounding cells (row, column, box)
  List<int> affectedCells = surroundingCells(row, col);

  for (int key in affectedCells) {
    if (cellNotes.containsKey(key)) {
      cellNotes[key]!.remove(number); // remove the number from notes
      if (cellNotes[key]!.isEmpty) {
        cellNotes.remove(key); // clean up empty sets
      }
    }
  }
}

Map<String, dynamic> generatePuzzleData(int removeCount) {
  final solved = SudokuBoard.generateSolved();
  final puzzle = SudokuBoard.clone(solved);
  puzzle.removeNumbers(removeCount);

  return {
    'solved': solved.board,
    'puzzle': puzzle.board,
    'missing': puzzle.missingCells.toList(),
  };
}

void replaceWithSolvedBoard(SudokuBoard board, List<List<int>> solvedData, Set<int> completeCells) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board.board[r][c] != solvedData[r][c]) {
        final key = r * 9 + c;
        board.missingCells.remove(key);
        completeCells.add(key);
        board.board[r][c] = solvedData[r][c];
      }
    }
  }
}

bool isNumberSolved(int number) {
  int count = 0;

  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] == number) {
        count++;
      }
    }
  }

  return count == 9;
}
}
