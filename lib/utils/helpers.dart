// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class Helpers {
  // ========== التواريخ والأوقات ==========

  /// تنسيق التاريخ مع دعم اللغة
  static String formatDate(DateTime date, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (difference.inDays > 0) {
      return t.translateWithParams('timeAgoDays', params: {
        'count': difference.inDays.toString(),
        'text': _getDayText(difference.inDays, context)
      });
    } else if (difference.inHours > 0) {
      return t.translateWithParams('timeAgoHours', params: {
        'count': difference.inHours.toString()
      });
    } else if (difference.inMinutes > 0) {
      return t.translateWithParams('timeAgoMinutes', params: {
        'count': difference.inMinutes.toString()
      });
    } else {
      return t.translate('timeNow');
    }
  }

  /// الحصول على نص اليوم حسب اللغة
  static String _getDayText(int days, BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (days == 1) return t.translate('day');
    if (days == 2) return t.translate('twoDays');
    return t.translate('days');
  }

  /// تنسيق الوقت (HH:mm)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// تنسيق التاريخ الكامل
  static String formatFullDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // ========== عرض الرسائل ==========

  /// إظهار SnackBar مع رسالة مترجمة
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// إظهار SnackBar مع رسالة مترجمة باستخدام المفتاح
  static void showTranslatedSnackBar(BuildContext context, String key, {bool isError = false, Map<String, String>? params}) {
    final t = AppLocalizations.of(context)!;
    String message = params != null ? t.translateWithParams(key, params: params) : t.translate(key);

    showSnackBar(context, message, isError: isError);
  }

  /// إظهار AlertDialog مع رسالة مترجمة
  static Future<bool?> showConfirmDialog(
      BuildContext context, {
        required String titleKey,
        required String messageKey,
        String? confirmTextKey,
        String? cancelTextKey,
        Map<String, String>? params,
      }) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(params != null ? t.translateWithParams(titleKey, params: params) : t.translate(titleKey)),
        content: Text(params != null ? t.translateWithParams(messageKey, params: params) : t.translate(messageKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelTextKey != null ? t.translate(cancelTextKey) : t.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmTextKey != null ? t.translate(confirmTextKey) : t.translate('confirm')),
          ),
        ],
      ),
    );
  }

  // ========== التحقق من صحة البيانات ==========

  /// التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
  }

  /// التحقق من صحة رقم الهاتف المصري
  static bool isValidEgyptianPhone(String phone) {
    return RegExp(r'^01[0125][0-9]{8}$').hasMatch(phone);
  }

  /// التحقق من صحة رقم الهاتف السعودي
  static bool isValidSaudiPhone(String phone) {
    return RegExp(r'^05[0-9]{8}$').hasMatch(phone);
  }

  /// التحقق من صحة رقم الهاتف حسب الدولة
  static bool isValidPhone(String phone, String country) {
    if (country == 'egypt') {
      return isValidEgyptianPhone(phone);
    } else if (country == 'saudi') {
      return isValidSaudiPhone(phone);
    }
    return false;
  }

  // ========== معالجة النصوص ==========

  /// اختصار النص الطويل
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// تنظيف النص من المسافات الزائدة
  static String cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ========== الألوان والأنماط ==========

  /// الحصول على لون نوع المنشور
  static Color getPostTypeColor(String type) {
    switch (type) {
      case 'lost':
        return Colors.red;
      case 'found':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على نص نوع المنشور مترجم
  static String getPostTypeText(String type, BuildContext context) {
    final t = AppLocalizations.of(context)!;

    switch (type) {
      case 'lost':
        return t.translate('lost');
      case 'found':
        return t.translate('found');
      default:
        return type;
    }
  }

  /// الحصول على لون التصنيف
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'pet':
        return Colors.orange;
      case 'item':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على نص التصنيف مترجم
  static String getCategoryText(String category, BuildContext context) {
    final t = AppLocalizations.of(context)!;

    switch (category) {
      case 'pet':
        return t.translate('pet');
      case 'item':
        return t.translate('item');
      default:
        return category;
    }
  }

  /// الحصول على لون الحالة
  static Color getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'resolved':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// الحصول على نص الحالة مترجم
  static String getStatusText(String status, BuildContext context) {
    final t = AppLocalizations.of(context)!;

    switch (status) {
      case 'active':
        return t.translate('active');
      case 'resolved':
        return t.translate('resolved');
      default:
        return status;
    }
  }
}