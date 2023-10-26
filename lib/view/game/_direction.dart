enum Direction {
  up,
  down,
  left,
  right,
  upLeft,
  upRight,
  downLeft,
  downRight;

  int get dx {
    switch (this) {
      case Direction.left:
      case Direction.upLeft:
      case Direction.downLeft:
        return -1;
      case Direction.right:
      case Direction.upRight:
      case Direction.downRight:
        return 1;
      default:
        return 0;
    }
  }

  int get dy {
    switch (this) {
      case Direction.up:
      case Direction.upLeft:
      case Direction.upRight:
        return -1;
      case Direction.down:
      case Direction.downLeft:
      case Direction.downRight:
        return 1;
      default:
        return 0;
    }
  }
}
