class Convert{
  static String formatSeconds(int seconds){
    int m= seconds~/60;
    int s=seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String toTitleCase(String? text) {
    if (text == null || text.isEmpty) return '';
    
    // Split by underscores, dashes, or spaces
    final words = text.replaceAll(RegExp(r'(_|-)'), ' ').split(' ');
    
    return words
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length <= 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}