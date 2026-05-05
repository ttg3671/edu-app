class Convert{
  static String formatSeconds(int seconds){
    int m= seconds~/60;
    int s=seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}