
class ConvertUtils{

  static String getTimeDiff(String date) {

    DateTime dateTime=DateTime.now();
    DateTime usaTime=dateTime.subtract(Duration(hours: 9,minutes: 30));

    // Define the specific date
    final targetDate = DateTime.parse(date);

    // Calculate the difference
    final difference = usaTime.difference(targetDate);

    // Extract different time units
    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;
    final weeks = (days / 7).floor();
    final months = (days / 30).floor(); // Approximate month length
    final years = (days / 365).floor(); // Approximate year length

    // Create result string
    String result;
    if (years > 0) {
      result = '${years} year${years > 1 ? 's' : ''} ago';
    } else if (months > 0) result = '$months month${months > 1 ? 's' : ''} ago';
    else if (weeks > 0) result = '${weeks} week${weeks > 1 ? 's' : ''} ago';
    else if (days > 0) result = '${days} day${days > 1 ? 's' : ''} ago';
    else if (hours > 0) result = '${hours} hour${hours > 1 ? 's' : ''} ago';
    else if (minutes > 0) result = '${minutes} minute${minutes > 1 ? 's' : ''} ago';
    else result = '${seconds} second${seconds > 1 ? 's' : ''} ago';

    return result;
  }

  static String formatNumber(int number) {
    if (number >= 1000000000000) {
      // Trillions
      return '${(number / 1000000000000).toStringAsFixed(1)}T';
    } else if (number >= 1000000000) {
      // Billions
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      // Millions
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      // Thousands
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      // Less than 1,000
      return number.toString();
    }
  }


  static String getRelativeTime(String timestamp1, int timestamp2) {
    DateTime later = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp1) * 1000, isUtc: true);
    DateTime earlier = DateTime.fromMillisecondsSinceEpoch(timestamp2 * 1000, isUtc: true);
    Duration difference = earlier.difference(later);

    // Extract different time units
    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;
    final weeks = (days / 7).floor();
    final months = (days / 30).floor(); // Approximate month length
    final years = (days / 365).floor(); // Approximate year length

    String result;

    if (years > 0) {
      result = '${years} year${years > 1 ? 's' : ''} ago';
    } else if (months > 0) {
      result = '${months} month${months > 1 ? 's' : ''} ago';
    } else if (weeks > 0) {
      result = '${weeks} week${weeks > 1 ? 's' : ''} ago';
    } else if (days > 0) {
      result = '${days} day${days > 1 ? 's' : ''} ago';
    } else if (hours > 0) {
      result = '${hours} hour${hours > 1 ? 's' : ''} ago';
    } else if (minutes > 0) {
      result = '${minutes} minute${minutes > 1 ? 's' : ''} ago';
    } else {
      result = '${seconds} second${seconds > 1 ? 's' : ''} ago';
    }

    return result;
  }

  static String formatDuration(int seconds) {
    final hours = (seconds ~/ 3600);
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$remainingSeconds';
    } else {
      return '$minutes:$remainingSeconds';
    }
  }


}