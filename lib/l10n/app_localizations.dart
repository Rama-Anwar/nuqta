import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS'**
  String get business;

  /// No description provided for @registeredName.
  ///
  /// In en, this message translates to:
  /// **'Registered name'**
  String get registeredName;

  /// No description provided for @unknownBusiness.
  ///
  /// In en, this message translates to:
  /// **'Unknown Business'**
  String get unknownBusiness;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get plan;

  /// No description provided for @enterprise.
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get enterprise;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @billingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Billing: -'**
  String get billingUnavailable;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get tools;

  /// No description provided for @inventorySheet.
  ///
  /// In en, this message translates to:
  /// **'Inventory Sheet'**
  String get inventorySheet;

  /// No description provided for @manageStockAndProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage stock and products'**
  String get manageStockAndProducts;

  /// No description provided for @technicalSupport.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get technicalSupport;

  /// No description provided for @contactHelpDesk.
  ///
  /// In en, this message translates to:
  /// **'Contact help desk'**
  String get contactHelpDesk;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get lastLogin;

  /// No description provided for @lastLoginUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Last login: -'**
  String get lastLoginUnavailable;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT'**
  String get logout;

  /// No description provided for @inventorySheetUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Inventory sheet URL is missing or invalid.'**
  String get inventorySheetUrlInvalid;

  /// No description provided for @unableToOpenInventorySheet.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the inventory sheet.'**
  String get unableToOpenInventorySheet;

  /// No description provided for @billingDate.
  ///
  /// In en, this message translates to:
  /// **'Billing: {date}'**
  String billingDate(Object date);

  /// No description provided for @lastLoginDate.
  ///
  /// In en, this message translates to:
  /// **'Last login: {date}'**
  String lastLoginDate(Object date);

  /// No description provided for @languageEnglishShort.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageEnglishShort;

  /// No description provided for @languageArabicShort.
  ///
  /// In en, this message translates to:
  /// **'AR'**
  String get languageArabicShort;

  /// No description provided for @invoiceAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice AI'**
  String get invoiceAppTitle;

  /// No description provided for @deleteInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get deleteInvoiceTitle;

  /// No description provided for @deleteInvoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?\nThis action cannot be undone.'**
  String deleteInvoiceMessage(Object name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @invoiceLedger.
  ///
  /// In en, this message translates to:
  /// **'Invoice Ledger'**
  String get invoiceLedger;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get all;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'OUTSTANDING'**
  String get outstanding;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get collected;

  /// No description provided for @totalProfit.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PROFIT'**
  String get totalProfit;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Profit'**
  String get totalProfitLabel;

  /// No description provided for @lineItems.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get lineItems;

  /// No description provided for @editLineItems.
  ///
  /// In en, this message translates to:
  /// **'Edit Line Items'**
  String get editLineItems;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWrong;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paid;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'JAN'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'FEB'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'MAR'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'APR'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'MAY'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'JUN'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'JUL'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'AUG'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'SEP'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'OCT'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'NOV'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'DEC'**
  String get dec;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
