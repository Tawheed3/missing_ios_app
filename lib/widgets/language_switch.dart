// lib/widgets/language_switch.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return PopupMenuButton<String>(
          icon: Icon(
            Icons.language,
            color: Colors.white, // لون الأيقونة ليتناسب مع الـ AppBar
          ),
          tooltip: t.translate('language'), // تلميح عند الضغط المطول
          onSelected: (languageCode) {
            languageService.changeLanguage(languageCode);
          },
          itemBuilder: (context) => [
            // عنصر اللغة العربية
            PopupMenuItem(
              value: 'ar',
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 4, right: 8),
                    child: Text('🇸🇦', style: const TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: Text(
                      t.translate('arabic'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (languageService.isArabic)
                    const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
            ),

            // عنصر اللغة الإنجليزية
            PopupMenuItem(
              value: 'en',
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 4, right: 8),
                    child: Text('🇬🇧', style: const TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: Text(
                      t.translate('english'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (languageService.isEnglish)
                    const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],

          // تخصيص شكل القائمة المنبثقة
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          // محاذاة القائمة
          offset: const Offset(0, 50),
        );
      },
    );
  }
}

// ========== نسخة مبسطة (اختيارية) ==========
// يمكنك استخدام هذا الزر البسيط إذا أردت تبديل اللغة مباشرة
class SimpleLanguageSwitch extends StatelessWidget {
  const SimpleLanguageSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return IconButton(
          icon: Text(
            languageService.isArabic ? '🇸🇦' : '🇬🇧',
            style: const TextStyle(fontSize: 24),
          ),
          onPressed: () => languageService.toggleLanguage(),
          tooltip: languageService.isArabic ? 'English' : 'العربية',
        );
      },
    );
  }
}