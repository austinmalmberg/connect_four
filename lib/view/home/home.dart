import 'package:flutter/material.dart';
import 'package:flutter_connect4/view/game/game.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              const TitleIcon(),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) => const GameScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TitleIcon extends StatelessWidget {
  const TitleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Connect',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        Text(
          'Four',
          style: TextStyle(
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}
