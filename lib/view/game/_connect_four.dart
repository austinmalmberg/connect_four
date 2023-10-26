import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '_direction.dart';

@immutable
class BoardState {
  final List<bool?> board;
  final int? lastPlayed;
  final bool? lastPlayer;

  const BoardState({
    required this.board,
    this.lastPlayed,
    this.lastPlayer,
  });
}

/// The number of rows in the list.
const int rows = 6;

/// The number of columsn in the list.
const int columns = 7;

/// The total list length.
int get boardSize => rows * columns;

int indexAt(int row, int column) => row * columns + column;

List<int> columnIndices(int column) =>
    List.generate(rows, (row) => indexAt(row, column), growable: false);

List<int> rowIndices(int row) =>
    List.generate(columns, (col) => indexAt(row, col), growable: false);

int columnOf(int index) => index % columns;

int rowOf(int index) => (index / columns).floor();

class GameBoardNotifier extends Notifier<BoardState> {
  int? lastPlayed;

  @override
  BoardState build() => BoardState(
        board: List.generate(boardSize, (index) => null, growable: false),
        lastPlayed: null,
        lastPlayer: null,
      );

  bool hasMove(int index) => state.board[columnOf(index)] == null;

  /// Place the [player] at the largest available (currently null) index within the [column].
  ///
  /// Throws an [ArgumentError] if no moves are available within the [column].
  void playInColumn(int column, bool player) {
    int? availableIndex;
    for (int i = 0; i < rows; i++) {
      int index = indexAt(rows - 1 - i, column);
      if (state.board[index] == null) {
        availableIndex = index;
        break;
      }
    }

    if (availableIndex == null) {
      throw ArgumentError('No available moves in column $column');
    }

    state = BoardState(
      board: [
        for (int i = 0; i < boardSize; i++)
          if (i == availableIndex) player else state.board[i]
      ],
      lastPlayed: availableIndex,
      lastPlayer: player,
    );
  }

  void reset() => state = build();
}

class TurnNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;

  void set(bool? turn) => state = turn ?? build();

  void reset() => state = build();
}

@immutable
class WinState {
  final bool player;
  final List<int> winners;

  const WinState({required this.player, required this.winners});
}

class WinNotifier extends Notifier<WinState?> {
  final WinTester tester = const WinTester();

  @override
  WinState? build() => null;

  void testWinners(BoardState boardState) {
    List<int>? winners = tester.testWinners(boardState);

    if (winners == null) {
      state = null;
    } else {
      state = WinState(player: boardState.lastPlayer!, winners: winners);
    }
  }

  void reset() => build();
}

class WinTester {
  const WinTester({this.consecutiveTilesToWin = 4});

  final int consecutiveTilesToWin;

  List<int>? testWinners(BoardState boardState) {
    if (boardState.lastPlayed == null) return null;

    return _getVerticalWinners(boardState.board, boardState.lastPlayed!) ??
        _getHorizontalWinners(boardState.board, boardState.lastPlayed!) ??
        _getDiag1Winners(boardState.board, boardState.lastPlayed!) ??
        _getDiag2Winners(boardState.board, boardState.lastPlayed!);
  }

  List<int>? _getVerticalWinners(List<bool?> board, int lastPlayed) {
    List<int> winners = <int>[lastPlayed];

    _addLikeNeighbors(winners, board, lastPlayed, Direction.up);
    _addLikeNeighbors(winners, board, lastPlayed, Direction.down);

    if (winners.length < consecutiveTilesToWin) return null;

    return winners;
  }

  List<int>? _getHorizontalWinners(List<bool?> board, int lastPlayed) {
    List<int> winners = <int>[lastPlayed];

    _addLikeNeighbors(winners, board, lastPlayed, Direction.left);
    _addLikeNeighbors(winners, board, lastPlayed, Direction.right);

    if (winners.length < consecutiveTilesToWin) return null;

    return winners;
  }

  List<int>? _getDiag1Winners(List<bool?> board, int lastPlayed) {
    List<int> winners = <int>[lastPlayed];

    _addLikeNeighbors(winners, board, lastPlayed, Direction.upLeft);
    _addLikeNeighbors(winners, board, lastPlayed, Direction.downRight);

    if (winners.length < consecutiveTilesToWin) return null;

    return winners;
  }

  List<int>? _getDiag2Winners(List<bool?> board, int lastPlayed) {
    List<int> winners = <int>[lastPlayed];

    _addLikeNeighbors(winners, board, lastPlayed, Direction.upRight);
    _addLikeNeighbors(winners, board, lastPlayed, Direction.downLeft);

    if (winners.length < consecutiveTilesToWin) return null;

    return winners;
  }

  void _addLikeNeighbors(
      List<int> list, List<bool?> board, int origin, Direction direction) {
    int? neighbor = _getNeighbor(origin, direction);
    while (neighbor != null && board[neighbor] == board[origin]) {
      list.add(neighbor);
      neighbor = _getNeighbor(neighbor, direction);
    }
  }

  int? _getNeighbor(int index, Direction direction) {
    int dr = rowOf(index) + direction.dx;
    int dc = columnOf(index) + direction.dy;

    if (dc < 0) return null;
    if (dc >= columns) return null;
    if (dr < 0) return null;
    if (dr >= rows) return null;

    return indexAt(dr, dc);
  }
}

class ScoreNotifier extends Notifier<(int, int)> {
  @override
  (int, int) build() => (0, 0);

  void update(bool winner) {
    if (winner == true) {
      state = (state.$1 + 1, state.$2);
    } else {
      state = (state.$1, state.$2 + 1);
    }
  }

  void reset() => state = build();
}
