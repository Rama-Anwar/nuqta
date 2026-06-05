// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get business => 'المنشأة';

  @override
  String get registeredName => 'الاسم المسجل';

  @override
  String get unknownBusiness => 'منشأة غير معروفة';

  @override
  String get plan => 'الخطة';

  @override
  String get enterprise => 'المؤسسات';

  @override
  String get active => 'نشط';

  @override
  String get billing => 'تاريخ الفوترة';

  @override
  String get billingUnavailable => 'تاريخ الفوترة: -';

  @override
  String get tools => 'الأدوات';

  @override
  String get inventorySheet => 'جدول المخزون';

  @override
  String get manageStockAndProducts => 'إدارة المخزون والمنتجات';

  @override
  String get technicalSupport => 'الدعم الفني';

  @override
  String get contactHelpDesk => 'التواصل مع الدعم الفني';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get account => 'الحساب';

  @override
  String get noEmail => 'لا يوجد بريد إلكتروني';

  @override
  String get lastLogin => 'آخر تسجيل دخول';

  @override
  String get lastLoginUnavailable => 'آخر تسجيل دخول: -';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get inventorySheetUrlInvalid => 'رابط جدول المخزون غير موجود أو غير صالح.';

  @override
  String get unableToOpenInventorySheet => 'تعذر فتح جدول المخزون.';

  @override
  String billingDate(Object date) {
    return 'تاريخ الفوترة: $date';
  }

  @override
  String lastLoginDate(Object date) {
    return 'آخر تسجيل دخول: $date';
  }
}
