// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get inventorySheetUrlInvalid =>
      'Inventory sheet URL is missing or invalid.';

  @override
  String get unableToOpenInventorySheet =>
      'Unable to open the inventory sheet.';

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
  String get profile => 'Profile';

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

  @override
  String get newIntakeReceipt => 'New Receipt';

  @override
  String get draft => 'Draft';

  @override
  String get orderInformation => 'Order Information';

  @override
  String get customerSupplierName => 'Customer/Supplier Name';

  @override
  String get enterName => 'Enter name';

  @override
  String get invoiceIdOptional => 'Invoice ID (Optional)';

  @override
  String get date => 'Date';

  @override
  String get jod => 'JOD';

  @override
  String get addItem => 'Add Item';

  @override
  String get itemName => 'Item Name';

  @override
  String get scanOrTypeItem => 'Scan or type item';

  @override
  String get quantity => 'Quantity';

  @override
  String get addItemButton => 'ADD ITEM';

  @override
  String itemsCount(Object count) {
    return '$count Items';
  }

  @override
  String get description => 'Description';

  @override
  String get profit => 'Profit';

  @override
  String get items => 'Items';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get tax => 'Tax (10%)';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get approveInvoice => 'APPROVE INVOICE';

  @override
  String get noItemsAdded => 'No items added yet.';

  @override
  String loadedFromWaitingList(Object customer) {
    return 'Loaded \"$customer\" from waiting list.';
  }

  @override
  String get addValidItem => 'Add a valid item, quantity, and price.';

  @override
  String get addAtLeastOneItem => 'Add at least one item before saving.';

  @override
  String get unnamedCustomer => 'Unnamed Customer';

  @override
  String get invoiceApprovedProcessed => 'Invoice approved & processed!';

  @override
  String get receiptSavedDashboardUpdated =>
      'Receipt saved and dashboard updated.';

  @override
  String get invoiceApprovedNotificationFailed =>
      'Invoice approved, but finalization notification failed.';

  @override
  String failedSaveApproveInvoice(Object error) {
    return 'Failed to save or approve invoice: $error';
  }

  @override
  String failedSaveReceipt(Object error) {
    return 'Failed to save receipt: $error';
  }

  @override
  String get needHelp => 'Need help?';

  @override
  String get supportIntro =>
      'Send us the issue details and the support team will follow up.';

  @override
  String get issueType => 'ISSUE TYPE';

  @override
  String get issueInvoices => 'Invoices';

  @override
  String get issueReceipts => 'Receipts';

  @override
  String get issueAccount => 'Account';

  @override
  String get issueOther => 'Other';

  @override
  String get message => 'MESSAGE';

  @override
  String get describeIssue => 'Describe what happened...';

  @override
  String get sendRequest => 'SEND REQUEST';

  @override
  String get sending => 'SENDING...';

  @override
  String get writeMessageFirst => 'Please write a message first.';

  @override
  String get requestSentSuccessfully => 'Request sent successfully';

  @override
  String get failedToSendRequest => 'Failed to send request. Try again.';

  @override
  String get technicalSupportTitle => 'Technical Support';

  @override
  String get username => 'Username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get securePassword => 'Secure Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get reset => 'RESET';

  @override
  String get loginToConsole => 'Login to Console';

  @override
  String get securedByInfrastructure => 'Secured by Nuqta Core Infrastructure';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get noUserFoundForEmail => 'No user found for this email.';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get invalidEmail => 'Invalid email.';
}
