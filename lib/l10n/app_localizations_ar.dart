// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
  String get dashboardLoadError => 'تعذر تحميل بيانات لوحة التحكم. تحقق من صلاحية الوصول إلى المنشأة.';

  @override
  String get dashboardTotalProfit => 'إجمالي الربح';

  @override
  String get dashboardPaidSales => 'المبيعات المدفوعة';

  @override
  String get dashboardAverageInvoice => 'متوسط الفاتورة';

  @override
  String get dashboardCustomers => 'العملاء';

  @override
  String get dashboardRevenueVsExpenses => 'الإيرادات مقابل المصروفات';

  @override
  String get dashboardMonthlyPerformance => 'متابعة الأداء الشهري';

  @override
  String get dashboardRevenue => 'الإيرادات';

  @override
  String get dashboardExpenses => 'المصروفات';

  @override
  String get dashboardToday => 'اليوم';

  @override
  String get dashboardWeek => 'الأسبوع';

  @override
  String get dashboardMonth => 'الشهر';

  @override
  String get dashboardYear => 'السنة';

  @override
  String get dashboardBestSellingProducts => 'المنتجات الأكثر مبيعاً';

  @override
  String get dashboardLeastSellingProducts => 'المنتجات الأقل مبيعاً';

  @override
  String get dashboardBest => 'الأكثر';

  @override
  String get dashboardLeast => 'الأقل';

  @override
  String get dashboardNoProductSales => 'لا توجد مبيعات منتجات بعد.';

  @override
  String get dashboardInvoiceLineItem => 'عنصر فاتورة';

  @override
  String dashboardUnits(Object count) {
    return '$count وحدة';
  }

  @override
  String get dashboardTopCustomersByValue => 'أعلى العملاء حسب القيمة';

  @override
  String get dashboardNoCustomers => 'لا يوجد عملاء بعد.';

  @override
  String dashboardInvoicesCount(Object count) {
    return '$count فاتورة';
  }

  @override
  String get receipts => 'الإيصالات';

  @override
  String get invoices => 'الفواتير';

  @override
  String get profile => 'الملف الشخصي';

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

  @override
  String get newIntakeReceipt => 'إيصال جديد';

  @override
  String get draft => 'مسودة';

  @override
  String get orderInformation => 'معلومات الفاتورة';

  @override
  String get customerSupplierName => 'اسم العميل / المورد';

  @override
  String get enterName => 'أدخل الاسم';

  @override
  String get invoiceIdOptional => 'رقم الفاتورة (اختياري)';

  @override
  String get date => 'التاريخ';

  @override
  String get jod => 'JOD';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get itemName => 'اسم العنصر';

  @override
  String get scanOrTypeItem => 'امسح أو أدخل اسم العنصر';

  @override
  String get quantity => 'الكمية';

  @override
  String get addItemButton => 'إضافة عنصر';

  @override
  String itemsCount(Object count) {
    return '$count عنصر';
  }

  @override
  String get description => 'الوصف';

  @override
  String get profit => 'الربح';

  @override
  String get items => 'منتجات';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get tax => 'الضريبة';

  @override
  String get totalCost => 'إجمالي التكلفة';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get approveInvoice => 'اعتماد الفاتورة';

  @override
  String get noItemsAdded => 'لم تتم إضافة أي عناصر بعد.';

  @override
  String loadedFromWaitingList(Object customer) {
    return 'تم تحميل \"$customer\" من قائمة الانتظار.';
  }

  @override
  String get addValidItem => 'أدخل عنصراً وكمية وسعراً صالحين.';

  @override
  String get addAtLeastOneItem => 'أضف عنصراً واحداً على الأقل قبل الحفظ.';

  @override
  String get unnamedCustomer => 'عميل غير مسمى';

  @override
  String get invoiceApprovedProcessed => 'تم اعتماد الفاتورة ومعالجتها بنجاح!';

  @override
  String get receiptSavedDashboardUpdated => 'تم حفظ السند وتحديث لوحة التحكم.';

  @override
  String get invoiceApprovedNotificationFailed => 'تم اعتماد الفاتورة ولكن فشل إرسال إشعار الإنهاء.';

  @override
  String failedSaveApproveInvoice(Object error) {
    return 'تعذر حفظ أو اعتماد الفاتورة: $error';
  }

  @override
  String failedSaveReceipt(Object error) {
    return 'تعذر حفظ السند: $error';
  }

  @override
  String get needHelp => 'بحاجة إلى مساعدة؟';

  @override
  String get supportIntro => 'أرسل تفاصيل المشكلة وسيقوم فريق الدعم بالتواصل معك.';

  @override
  String get issueType => 'نوع المشكلة';

  @override
  String get issueInvoices => 'الفواتير';

  @override
  String get issueReceipts => 'الإيصالات';

  @override
  String get issueAccount => 'الحساب';

  @override
  String get issueOther => 'أخرى';

  @override
  String get message => 'الرسالة';

  @override
  String get describeIssue => 'اشرح ما الذي حدث...';

  @override
  String get sendRequest => 'إرسال الطلب';

  @override
  String get sending => 'جارٍ الإرسال...';

  @override
  String get writeMessageFirst => 'يرجى كتابة الرسالة أولاً.';

  @override
  String get requestSentSuccessfully => 'تم إرسال الطلب بنجاح';

  @override
  String get failedToSendRequest => 'تعذر إرسال الطلب. حاول مرة أخرى.';

  @override
  String get technicalSupportTitle => 'الدعم الفني';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get securePassword => 'كلمة المرور';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get loginToConsole => 'تسجيل الدخول';

  @override
  String get securedByInfrastructure => 'مؤمّن بواسطة البنية التحتية لنقطة';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get noUserFoundForEmail => 'لا يوجد مستخدم بهذا البريد الإلكتروني.';

  @override
  String get wrongPassword => 'كلمة المرور غير صحيحة.';

  @override
  String get invalidEmail => 'البريد الإلكتروني غير صالح.';

  @override
  String get addEmployees => 'إضافة موظفين';

  @override
  String get inviteTeamMembers => 'دعوة أعضاء الفريق إلى مؤسستك';

  @override
  String get taxPercentage => 'نسبة الضريبة';

  @override
  String get currentTax => 'الضريبة الحالية:';
}
