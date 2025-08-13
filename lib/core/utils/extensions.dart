import 'package:flutter/material.dart';

// String Extensions
extension StringExtensions on String {
  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  // Capitalize each word
  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  // Check if string is a valid email
  bool get isValidEmail {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }
  
  // Check if string is a valid phone number
  bool get isValidPhone {
    final RegExp phoneRegex = RegExp(
      r'^(\+?254|0)?[17]\d{8}$',
    );
    return phoneRegex.hasMatch(replaceAll(RegExp(r'\s+'), ''));
  }
  
  // Check if string is a valid URL
  bool get isValidUrl {
    final RegExp urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    return urlRegex.hasMatch(this);
  }
  
  // Remove all whitespace
  String get removeAllWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }
  
  // Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
  
  // Convert to snake_case
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }
  
  // Convert to camelCase
  String get toCamelCase {
    final words = split(RegExp(r'[_\s]+'));
    if (words.isEmpty) return this;
    return words.first.toLowerCase() +
        words.skip(1).map((w) => w.capitalize).join();
  }
  
  // Get initials from name
  String get initials {
    final words = split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

// DateTime Extensions
extension DateTimeExtensions on DateTime {
  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  // Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
  
  // Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && 
           month == tomorrow.month && 
           day == tomorrow.day;
  }
  
  // Check if date is in the past
  bool get isPast {
    return isBefore(DateTime.now());
  }
  
  // Check if date is in the future
  bool get isFuture {
    return isAfter(DateTime.now());
  }
  
  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
  
  // Get time until string
  String get timeUntil {
    final now = DateTime.now();
    final difference = this.difference(now);
    
    if (difference.inSeconds < 60) {
      return 'In a moment';
    } else if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return 'In ${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return 'In ${(difference.inDays / 30).floor()}mo';
    } else {
      return 'In ${(difference.inDays / 365).floor()}y';
    }
  }
  
  // Get start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }
  
  // Get end of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
  
  // Format as friendly date
  String get friendlyDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
}

// List Extensions
extension ListExtensions<T> on List<T> {
  // Get first or null
  T? get firstOrNull {
    return isEmpty ? null : first;
  }
  
  // Get last or null
  T? get lastOrNull {
    return isEmpty ? null : last;
  }
  
  // Get element at index or null
  T? getOrNull(int index) {
    return (index >= 0 && index < length) ? this[index] : null;
  }
  
  // Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
  
  // Remove duplicates
  List<T> get unique {
    return toSet().toList();
  }
}

// BuildContext Extensions
extension BuildContextExtensions on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  
  // MediaQuery shortcuts
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  
  // Navigation shortcuts
  NavigatorState get navigator => Navigator.of(this);
  
  void push(Widget page) {
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }
  
  void pushReplacement(Widget page) {
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => page));
  }
  
  void pushAndRemoveUntil(Widget page) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
  
  void pop([dynamic result]) {
    if (navigator.canPop()) {
      navigator.pop(result);
    }
  }
  
  // Snackbar shortcuts
  void showSnackBar(String message, {Duration? duration, SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }
  
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // Dialog shortcuts
  Future<T?> showAlertDialog<T>({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog<T>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(cancelText),
            ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(confirmText ?? 'OK'),
          ),
        ],
      ),
    );
  }
  
  // Loading dialog
  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }
  
  void hideLoadingDialog() {
    pop();
  }
}

// Number Extensions
extension NumberExtensions on num {
  // Convert to currency string
  String toCurrency([String symbol = 'KSh']) {
    return '$symbol ${toStringAsFixed(2)}';
  }
  
  // Convert to compact string
  String get compact {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
  
  // Convert to percentage
  String toPercentage([int decimals = 0]) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }
}