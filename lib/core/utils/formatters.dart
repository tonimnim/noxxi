import 'package:intl/intl.dart';

class Formatters {
  // Currency formatters for different African currencies
  static final Map<String, NumberFormat> _currencyFormatters = {
    'KES': NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0), // Kenyan Shilling
    'NGN': NumberFormat.currency(symbol: '₦', decimalDigits: 2), // Nigerian Naira
    'ZAR': NumberFormat.currency(symbol: 'R ', decimalDigits: 2), // South African Rand
    'GHS': NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2), // Ghanaian Cedi
    'UGX': NumberFormat.currency(symbol: 'USh ', decimalDigits: 0), // Ugandan Shilling
    'TZS': NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0), // Tanzanian Shilling
    'EGP': NumberFormat.currency(symbol: 'E£ ', decimalDigits: 2), // Egyptian Pound
    'USD': NumberFormat.currency(symbol: '\$ ', decimalDigits: 2), // US Dollar
  };
  
  // Format currency based on currency code
  static String formatCurrency(double amount, String currencyCode) {
    final formatter = _currencyFormatters[currencyCode] ?? 
                     NumberFormat.currency(symbol: '$currencyCode ', decimalDigits: 2);
    return formatter.format(amount);
  }
  
  // Format Kenyan Shilling
  static String formatKES(double amount) {
    return formatCurrency(amount, 'KES');
  }
  
  // Format phone number
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    
    // Format Kenyan numbers
    if (cleaned.startsWith('254')) {
      // +254 XXX XXX XXX
      if (cleaned.length == 12) {
        return '+${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
      }
    } else if (cleaned.startsWith('0') && cleaned.length == 10) {
      // 0XXX XXX XXX
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    } else if (cleaned.length == 9) {
      // XXX XXX XXX (assume Kenyan without prefix)
      return '+254 ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    
    return phone;
  }
  
  // Convert phone to international format
  static String toInternationalPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    
    // Handle Kenyan numbers
    if (cleaned.startsWith('254')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '+254${cleaned.substring(1)}';
    } else if (cleaned.length == 9) {
      return '+254$cleaned';
    }
    
    return phone;
  }
  
  // Date formatters
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
  
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
  
  static String formatTime12Hour(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  static String formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${formatTime12Hour(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${formatTime12Hour(date)}';
    } else if (difference.inDays < 7 && difference.inDays > 0) {
      return '${DateFormat('EEEE').format(date)} at ${formatTime12Hour(date)}';
    } else {
      return DateFormat('EEE, dd MMM yyyy • h:mm a').format(date);
    }
  }
  
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
  
  // Number formatters
  static String formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
  
  static String formatCompactNumber(num number) {
    return NumberFormat.compact().format(number);
  }
  
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }
  
  // Text formatters
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalizeFirst(word)).join(' ');
  }
  
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }
  
  // File size formatter
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  // Duration formatter
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  // Ticket number formatter
  static String formatTicketNumber(String ticketId) {
    // Format: TKT-XXXX-XXXX-XXXX
    if (ticketId.length <= 12) {
      return 'TKT-${ticketId.toUpperCase()}';
    }
    return ticketId;
  }
  
  // Order number formatter
  static String formatOrderNumber(String orderId) {
    // Format: ORD-YYYYMMDD-XXXX
    return 'ORD-${orderId.toUpperCase()}';
  }
}