import 'package:intl/intl.dart';

/// 日期格式化工具类
class DateFormatter {
  /// 格式化为完整日期时间 (yyyy-MM-dd HH:mm:ss)
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// 格式化为短日期 (MM-dd HH:mm)
  static String formatShortDate(DateTime dateTime) {
    return DateFormat('MM-dd HH:mm').format(dateTime);
  }

  /// 格式化为时间 (HH:mm:ss)
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  /// 格式化为相对时间 (刚刚、5分钟前、2小时前等)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatShortDate(dateTime);
    }
  }

  /// 格式化持续时间
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes.remainder(60)}分';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${duration.inSeconds.remainder(60)}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  /// 格式化字节大小
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
