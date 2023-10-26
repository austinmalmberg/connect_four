import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '_connect_four.dart';

final boardStateProvider =
    NotifierProvider<GameBoardNotifier, BoardState>(GameBoardNotifier.new);

final turnProvider = NotifierProvider<TurnNotifier, bool>(TurnNotifier.new);

final scoreProvider =
    NotifierProvider<ScoreNotifier, (int, int)>(ScoreNotifier.new);

final winnerProvider =
    NotifierProvider<WinNotifier, WinState?>(WinNotifier.new);

final hoverProvider =
    NotifierProvider<HoverNotifier, List<int>?>(HoverNotifier.new);

final board =
    Provider<List<bool?>>((ref) => ref.watch(boardStateProvider).board);

final winningTiles = Provider<List<int>?>((ref) {
  final WinState? win = ref.watch(winnerProvider);

  return win?.winners;
});

final gameRunning = Provider<bool>((ref) {
  final List<bool?> tiles = ref.watch(board);
  final WinState? win = ref.watch(winnerProvider);

  return rowIndices(0).any((i) => tiles[i] == null) && win == null;
});

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  /// Displays an [AlertDialog] when the game ends.
  void _addGameOverListener(BuildContext context, WidgetRef ref) {
    ref.listen(gameRunning, (previous, current) {
      // ignore when state doesn't change
      if (current == previous) return;

      // show dialog when the game stops running
      if (!current) {
        bool? winner =
            ref.read(winnerProvider.select((value) => value?.player));

        // update the score
        if (winner != null) {
          ref.read(scoreProvider.notifier).update(winner);
        }

        String dialogText;
        if (winner == null) {
          dialogText = 'Draw';
        } else {
          String color = winner ? 'Red' : 'Black';
          dialogText = '$color wins!';
        }

        showDialog<void>(
          context: context,
          useRootNavigator: false,
          builder: (context) => AlertDialog(
            title: Text(dialogText),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  _resetGame(ref);
                },
                child: const Text('Play Again'),
              ),
            ],
          ),
        );
      }
    });
  }

  /// Tests for winners then updates the turn when the [BoardState] changes.
  void _addTurnListener(WidgetRef ref) {
    ref.listen(boardStateProvider, (previous, current) {
      final WinNotifier winNotifier = ref.read(winnerProvider.notifier);
      final TurnNotifier turnNotifier = ref.read(turnProvider.notifier);

      if (current.lastPlayer != null) {
        winNotifier.testWinners(current);
        turnNotifier.set(!current.lastPlayer!);
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _addGameOverListener(context, ref);
    _addTurnListener(ref);

    return WillPopScope(
      onWillPop: () async {
        _resetGame(ref, resetScore: true);

        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 6,
                child: _ConnectFour(),
              ),
              Expanded(
                flex: 1,
                child: _ScoreRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectFour extends StatelessWidget {
  const _ConnectFour();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: columns / rows,
      child: GridView.builder(
        itemCount: boardSize,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns),
        itemBuilder: (context, index) {
          return _GameTile(
            index: index,
          );
        },
      ),
    );
  }
}

class _GameTile extends ConsumerWidget {
  const _GameTile({required this.index});

  final int index;

  int get column => columnOf(index);

  int get row => rowOf(index);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool? activePlayer;
    if (row == 0) {
      activePlayer = ref.watch(turnProvider);
    }

    final bool isActiveColumn =
        ref.watch(hoverProvider.select((value) => value?.contains(index))) ??
            false;

    return InkWell(
      splashFactory: NoSplash.splashFactory,
      onTap: () {
        if (!ref.read(gameRunning)) {
          _resetGame(ref);
        } else {
          GameBoardNotifier boardNotifier =
              ref.read(boardStateProvider.notifier);

          if (boardNotifier.hasMove(column)) {
            boardNotifier.playInColumn(column, ref.read(turnProvider));
          }
        }
      },
      onHover: (active) {
        if (!active) return;

        ref.read(hoverProvider.notifier).setActive(column);
      },
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          // to play indicator
          if (activePlayer != null && isActiveColumn)
            _GameChip(player: activePlayer),

          // clips out a circle to expose the background or parent
          ClipPath(
            clipper: const _PortholeClipper(
              padding: EdgeInsets.all(4.0),
            ),

            // the inner circle that exposes the background or contains the game piece
            child: ColoredBox(
              color: Theme.of(context).primaryColor,
            ),
          ),

          Consumer(builder: (context, ref, child) {
            final bool? player =
                ref.watch(board.select((value) => value[index]));

            final bool tileInWinners = ref.watch(winningTiles
                    .select((winners) => winners?.contains(index))) ??
                false;

            if (player == null) return const SizedBox.shrink();

            return _GameChip(
              player: player,
              highlight: tileInWinners,
            );
          }),

          //
          if (isActiveColumn)
            ColoredBox(
              color: Colors.yellow.withOpacity(0.2),
            ),
        ],
      ),
    );
  }
}

class _PortholeClipper extends CustomClipper<Path> {
  const _PortholeClipper({this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Path getClip(Size size) {
    Rect area = Rect.fromLTWH(0, 0, size.width, size.height);

    Rect porthole = Rect.fromLTRB(
        area.left + padding.left,
        area.top + padding.top,
        area.right - padding.right,
        area.bottom - padding.bottom);

    return Path()
      ..addRect(area)
      ..addOval(porthole)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant _PortholeClipper oldClipper) =>
      oldClipper.padding != padding || true;
}

class _GameChip extends ConsumerWidget {
  const _GameChip({
    required this.player,
    this.highlight = false,
  });

  final bool player;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: player ? Colors.red : Colors.black,
          shape: BoxShape.circle,
        ),
        child: FittedBox(
          child: Icon(
            Icons.stars,
            color: highlight
                ? Colors.yellow.shade700
                : Colors.white.withOpacity(0.15),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Flexible(
          child: _ScoreItem(player: true),
        ),
        VerticalDivider(
          color: Colors.black.withOpacity(0.2),
          thickness: 2.0,
          indent: 4.0,
          endIndent: 4.0,
        ),
        const Flexible(
          child: _ScoreItem(player: false),
        ),
      ],
    );
  }
}

class _ScoreItem extends ConsumerWidget {
  const _ScoreItem({required this.player});

  final bool player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int score = ref
        .watch(scoreProvider.select((value) => player ? value.$1 : value.$2));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _GameChip(player: player),
        ),

        // allows score to scale
        FittedBox(
          fit: BoxFit.fitHeight,
          // more accurately centers the text
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '$score',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
        ),
      ],
    );
  }
}

void _resetGame(WidgetRef ref, {bool resetScore = false}) {
  ref.invalidate(boardStateProvider);
  ref.invalidate(turnProvider);
  ref.invalidate(winnerProvider);

  if (resetScore) ref.invalidate(scoreProvider);
}

class HoverNotifier extends Notifier<List<int>?> {
  @override
  List<int>? build() => null;

  void setActive(int column) => state = columnIndices(column);
}
