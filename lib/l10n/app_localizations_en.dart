// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profile => 'Profile';

  @override
  String get business => 'BUSINESS';

  @override
  String get registeredName => 'Registered name';

  @override
  String get unknownBusiness => 'Unknown Business';

  @override
  String get plan => 'PLAN';

  @override
  String get enterprise => 'Enterprise';

  @override
  String get active => 'ACTIVE';

  @override
  String get billing => 'Billing';

  @override
  String get billingUnavailable => 'Billing: -';

  @override
  String get tools => 'TOOLS';

  @override
  String get inventorySheet => 'Inventory Sheet';

  @override
  String get manageStockAndProducts => 'Manage stock and products';

  @override
  String get technicalSupport => 'Technical Support';

  @override
  String get contactHelpDesk => 'Contact help desk';

  @override
  String get settings => 'SETTINGS';

  @override
  String get language => 'Language';

  @override
  String get account => 'ACCOUNT';

  @override
  String get noEmail => 'No email';

  @override
  String get lastLogin => 'Last login';

  @override
  String get lastLoginUnavailable => 'Last login: -';

  @override
  String get logout => 'LOGOUT';

  @override
  String get inventorySheetUrlInvalid => 'Inventory sheet URL is missing or invalid.';

  @override
  String get unableToOpenInventorySheet => 'Unable to open the inventory sheet.';

  @override
  String billingDate(Object date) {
    return 'Billing: $date';
  }

  @override
  String lastLoginDate(Object date) {
    return 'Last login: $date';
  }

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get languageArabicShort => 'AR';

  @override
  String get invoiceAppTitle => 'Invoice AI';

  @override
  String get deleteInvoiceTitle => 'Delete Invoice';

  @override
  String deleteInvoiceMessage(Object name) {
    return 'Delete \"$name\"?\nThis action cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get invoiceLedger => 'Invoice Ledger';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get select => 'Select';

  @override
  String get all => 'ALL';

  @override
  String get outstanding => 'OUTSTANDING';

  @override
  String get collected => 'COLLECTED';

  @override
  String get totalProfit => 'TOTAL PROFIT';

  @override
  String get cost => 'Cost';

  @override
  String get total => 'Total';

  @override
  String get totalProfitLabel => 'Total Profit';

  @override
  String get lineItems => 'Line Items';

  @override
  String get editLineItems => 'Edit Line Items';

  @override
  String get qty => 'Qty';

  @override
  String get price => 'Price';

  @override
  String get costLabel => 'Cost';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get receipts => 'Receipts';

  @override
  String get invoices => 'Invoices';

  @override
  String get somethingWrong => 'Something went wrong';

  @override
  String get pickDate => 'Pick date';

  @override
  String get paid => 'PAID';

  @override
  String get save => 'Save';

  @override
  String get jan => 'JAN';

  @override
  String get feb => 'FEB';

  @override
  String get mar => 'MAR';

  @override
  String get apr => 'APR';

  @override
  String get may => 'MAY';

  @override
  String get jun => 'JUN';

  @override
  String get jul => 'JUL';

  @override
  String get aug => 'AUG';

  @override
  String get sep => 'SEP';

  @override
  String get oct => 'OCT';

  @override
  String get nov => 'NOV';

  @override
  String get dec => 'DEC';
}
