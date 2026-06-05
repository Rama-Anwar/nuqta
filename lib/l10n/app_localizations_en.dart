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
}
