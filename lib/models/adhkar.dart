class Adhkar {
  final String text;
  final int targetCount;
  int currentCount;

  Adhkar({
    required this.text,
    required this.targetCount,
    this.currentCount = 0,
  });
}
