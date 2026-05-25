import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptStore extends ChangeNotifier {
  ReceiptStore._();

  static final ReceiptStore instance = ReceiptStore._();
  static const String _storageKey = 'invoice_ai_saved_receipts_v1';

  final List<ReceiptRecord> _receipts = <ReceiptRecord>[];
  bool _loaded = false;

  List<ReceiptRecord> get receipts => List.unmodifiable(_receipts);

  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];

    _receipts
      ..clear()
      ..addAll(
        stored
            .map((value) => ReceiptRecord.fromJson(jsonDecode(value) as Map<String, dynamic>))
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt)),
      );

    _loaded = true;
    notifyListeners();
  }

  Future<void> addReceipt(ReceiptRecord receipt) async {
    await ensureLoaded();
    final assigned = _ensureSequentialInvoiceId(receipt);
    _receipts.insert(0, assigned);
    await _persist();
    notifyListeners();
  }

  Future<void> updateReceipt(ReceiptRecord updated) async {
    await ensureLoaded();
    final idx = _receipts.indexWhere((r) => r.id == updated.id);
    if (idx == -1) return;
    _receipts[idx] = _ensureSequentialInvoiceId(updated, excludeId: updated.id);
    await _persist();
    notifyListeners();
  }

  ReceiptRecord _ensureSequentialInvoiceId(ReceiptRecord receipt, {String? excludeId}) {
    final existingIds = _receipts
        .where((r) => r.invoiceId != null && r.id != excludeId)
        .map((r) => r.invoiceId!)
        .toSet();

    final currentId = receipt.invoiceId?.trim();
    if (currentId != null && currentId.isNotEmpty && !existingIds.contains(currentId)) {
      return receipt;
    }

    final nextNumber = _nextInvoiceNumber(existingIds);
    return ReceiptRecord(
      id: receipt.id,
      customerName: receipt.customerName,
      invoiceId: 'INV-$nextNumber',
      date: receipt.date,
      createdAt: receipt.createdAt,
      items: receipt.items,
    );
  }

  int _nextInvoiceNumber(Set<String> existingIds) {
    var maxNumber = 0;
    for (final id in existingIds) {
      final match = RegExp(r'^(?:INV-)?(\d+)$').firstMatch(id);
      if (match != null) {
        final value = int.tryParse(match.group(1)!);
        if (value != null && value > maxNumber) {
          maxNumber = value;
        }
      }
    }
    return maxNumber + 1;
  }

  double salesForMonth(DateTime month) {
    return _receipts
        .where((receipt) => _isSameMonth(receipt.date, month))
        .fold<double>(0, (sum, receipt) => sum + receipt.total);
  }

  double salesForYear(int year) {
    return _receipts
        .where((receipt) => receipt.date.year == year)
        .fold<double>(0, (sum, receipt) => sum + receipt.total);
  }

  int receiptsForMonth(DateTime month) {
    return _receipts.where((receipt) => _isSameMonth(receipt.date, month)).length;
  }

  int uniqueCustomerCount() {
    return _receipts
        .map((receipt) => _normalizeCustomer(receipt.customerName))
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;
  }

  List<MonthlyRevenue> monthlyRevenueSeries({int months = 6, DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return List<MonthlyRevenue>.generate(months, (index) {
      final month = _addMonths(currentMonth, -(months - 1 - index));
      final amount = _receipts
          .where((receipt) => _isSameMonth(receipt.date, month))
          .fold<double>(0, (sum, receipt) => sum + receipt.total);

      return MonthlyRevenue(
        label: _monthLabel(month.month),
        amount: amount,
      );
    });
  }

  List<CustomerInsight> topCustomers({int limit = 4}) {
    final groups = <String, CustomerInsight>{};

    for (final receipt in _receipts) {
      final key = _normalizeCustomer(receipt.customerName);
      if (key.isEmpty) {
        continue;
      }

      final current = groups[key];
      if (current == null) {
        groups[key] = CustomerInsight(
          name: receipt.customerName,
          orderCount: 1,
          spent: receipt.total,
        );
      } else {
        groups[key] = current.copyWith(
          orderCount: current.orderCount + 1,
          spent: current.spent + receipt.total,
        );
      }
    }

    final ranked = groups.values.toList()
      ..sort((left, right) => right.spent.compareTo(left.spent));

    return ranked.take(limit).toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _receipts.map((receipt) => jsonEncode(receipt.toJson())).toList(),
    );
  }

  bool _isSameMonth(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month;
  }

  String _normalizeCustomer(String value) {
    return value.trim().toLowerCase();
  }

  DateTime _addMonths(DateTime base, int months) {
    final year = base.year + ((base.month - 1 + months) ~/ 12);
    final month = ((base.month - 1 + months) % 12) + 1;
    return DateTime(year, month);
  }

  String _monthLabel(int month) {
    const labels = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[month - 1];
  }
}

class ReceiptRecord {
  final String id;
  final String customerName;
  final String? invoiceId;
  final DateTime date;
  final DateTime createdAt;
  final List<ReceiptLineItem> items;

  const ReceiptRecord({
    required this.id,
    required this.customerName,
    required this.invoiceId,
    required this.date,
    required this.createdAt,
    required this.items,
  });

  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.1;
  double get total => subtotal + tax;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerName': customerName,
      'invoiceId': invoiceId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory ReceiptRecord.fromJson(Map<String, dynamic> json) {
    return ReceiptRecord(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Unnamed Customer',
      invoiceId: json['invoiceId'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => ReceiptLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReceiptLineItem {
  final String item;
  final int quantity;
  final double unitPrice;

  const ReceiptLineItem({
    required this.item,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item': item,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    return ReceiptLineItem(
      item: json['item'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MonthlyRevenue {
  final String label;
  final double amount;

  const MonthlyRevenue({required this.label, required this.amount});
}

class CustomerInsight {
  final String name;
  final int orderCount;
  final double spent;

  const CustomerInsight({
    required this.name,
    required this.orderCount,
    required this.spent,
  });

  CustomerInsight copyWith({String? name, int? orderCount, double? spent}) {
    return CustomerInsight(
      name: name ?? this.name,
      orderCount: orderCount ?? this.orderCount,
      spent: spent ?? this.spent,
    );
  }
}
