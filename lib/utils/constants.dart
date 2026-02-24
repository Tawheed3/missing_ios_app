// lib/utils/constants.dart
class AppConstants {
  // App Info
  static const String appName = 'فقد وعثور';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';

  // Post Types
  static const String postTypeLost = 'lost';
  static const String postTypeFound = 'found';

  // Post Categories
  static const String categoryPet = 'pet';
  static const String categoryItem = 'item';

  // Post Status
  static const String statusActive = 'active';
  static const String statusResolved = 'resolved';

  // Shared Preferences Keys
  static const String prefUserLoggedIn = 'user_logged_in';
  static const String prefUserId = 'user_id';

  // Error Messages
  static const String errorGeneral = 'حدث خطأ غير متوقع';
  static const String errorNetwork = 'خطأ في الاتصال بالإنترنت';
  static const String errorAuth = 'خطأ في المصادقة';
}

class AppStrings {
  // App Bar Titles
  static const String home = 'الرئيسية';
  static const String profile = 'الملف الشخصي';
  static const String addPost = 'إضافة منشور';
  static const String details = 'تفاصيل المنشور';

  // Buttons
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب';
  static const String logout = 'تسجيل الخروج';
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';

  // Post Types
  static const String lost = 'مفقود';
  static const String found = 'موجود';
  static const String pet = 'حيوان';
  static const String item = 'شيء';
  static const String resolved = 'تم الحل';

  // Messages
  static const String noPosts = 'لا توجد منشورات';
  static const String noComments = 'لا توجد تعليقات';
  static const String loading = 'جاري التحميل...';
}