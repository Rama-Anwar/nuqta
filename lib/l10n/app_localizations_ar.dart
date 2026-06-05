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

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get languageArabicShort => 'عر';

  @override
  String get invoiceAppTitle => 'فواتير AI';

  @override
  String get deleteInvoiceTitle => 'حذف الفاتورة';

  @override
  String deleteInvoiceMessage(Object name) {
    return 'حذف \"$name\"؟\nلا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get invoiceLedger => 'سجل الفواتير';

  @override
  String get year => 'السنة';

  @override
  String get month => 'الشهر';

  @override
  String get select => 'اختر';

  @override
  String get all => 'الكل';

  @override
  String get outstanding => 'غير مدفوع';

  @override
  String get collected => 'تم التحصيل';

  @override
  String get totalProfit => 'إجمالي الربح';

  @override
  String get cost => 'التكلفة';

  @override
  String get total => 'المجموع';

  @override
  String get totalProfitLabel => 'إجمالي الربح';

  @override
  String get lineItems => 'عناصر الفاتورة';

  @override
  String get editLineItems => 'تعديل العناصر';

  @override
  String get qty => 'الكمية';

  @override
  String get price => 'السعر';

  @override
  String get costLabel => 'التكلفة';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get receipts => 'الإيصالات';

  @override
  String get invoices => 'الفواتير';

  @override
  String get somethingWrong => 'حدث عطل';

  @override
  String get pickDate => 'اختر تاريخاً';

  @override
  String get paid => 'تم الدفع';

  @override
  String get save => 'حفظ';

  @override
  String get jan => 'يناير';

  @override
  String get feb => 'فبراير';

  @override
  String get mar => 'مارس';

  @override
  String get apr => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get jun => 'يونيو';

  @override
  String get jul => 'يوليو';

  @override
  String get aug => 'أغسطس';

  @override
  String get sep => 'سبتمبر';

  @override
  String get oct => 'أكتوبر';

  @override
  String get nov => 'نوفمبر';

  @override
  String get dec => 'ديسمبر';
}
