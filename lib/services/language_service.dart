// lib/services/language_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('ar'); // العربية افتراضياً (تم التعديل من 'en' إلى 'ar')

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  // دالة للحصول على اسم اللغة بالعربية
  String get currentLanguageName => isArabic ? 'العربية' : 'English';

  // دالة للحصول على رمز العلم
  String get currentLanguageFlag => isArabic ? '🇸🇦' : '🇬🇧';

  // دالة للحصول على اتجاه النص (RTL للعربية، LTR للإنجليزية)
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  LanguageService() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);
      if (languageCode != null && (languageCode == 'ar' || languageCode == 'en')) {
        _locale = Locale(languageCode);
      } else {
        // إذا لم يكن هناك لغة محفوظة، نستخدم العربية كافتراضية
        _locale = const Locale('ar');
      }
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل اللغة المحفوظة: $e');
      // في حالة الخطأ، نستخدم العربية
      _locale = const Locale('ar');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    // التأكد من أن اللغة المدخلة صحيحة
    if (languageCode != 'ar' && languageCode != 'en') {
      print('❌ لغة غير مدعومة: $languageCode');
      return;
    }

    _locale = Locale(languageCode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      print('✅ تم تغيير اللغة إلى: $languageCode');
    } catch (e) {
      print('❌ خطأ في حفظ اللغة: $e');
    }

    notifyListeners();
  }

  // دالة لتبديل اللغة بين العربية والإنجليزية
  Future<void> toggleLanguage() async {
    if (isArabic) {
      await changeLanguage('en');
    } else {
      await changeLanguage('ar');
    }
  }

  // دالة للحصول على النص حسب اللغة (مفيدة للقوائم الثابتة)
  String getLocalizedString(String arText, String enText) {
    return isArabic ? arText : enText;
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}