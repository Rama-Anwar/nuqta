import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ReceiptStore extends ChangeNotifier {
  ReceiptStore._();

  static final ReceiptStore instance = ReceiptStore._();

  // Firestore collection reference
  static CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users_receipts')
        .doc(uid)
        .collection('receipts');
  }

  final List<ReceiptRecord> _receipts = <ReceiptRecord>[];
  bool _loaded = false;

  List<ReceiptRecord> get receipts => List.unmodifiable(_receipts);

  Stream<List<ReceiptRecord>> receiptsStream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ReceiptRecord.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Loads all receipts from Firestore (once per app session).
  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final snapshot = await _col.orderBy('createdAt', descending: true).get();

    _receipts
      ..clear()
      ..addAll(
        snapshot.docs.map(
          (doc) => ReceiptRecord.fromJson({...doc.data(), 'id': doc.id}),
        ),
      );

    _loaded = true;
    notifyListeners();
  }

  /// Saves a new receipt to Firestore and updates the local cache.
  Future<void> addReceipt(ReceiptRecord receipt) async {
    await ensureLoaded();

    final assigned = _ensureSequentialInvoiceId(receipt);

    // Use the receipt's id as the Firestore document id so they stay in sync.
    await _col.doc(assigned.id).set(assigned.toJson());

    _receipts.insert(0, assigned);
    notifyListeners();
  }

  /// Updates an existing receipt in Firestore and in the local cache.
  Future<void> updateReceipt(ReceiptRecord updated) async {
    await ensureLoaded();

    final idx = _receipts.indexWhere((r) => r.id == updated.id);
    if (idx == -1) return;

    final assigned = _ensureSequentialInvoiceId(updated, excludeId: updated.id);

    await _col.doc(assigned.id).set(assigned.toJson());

    _receipts[idx] = assigned;
    notifyListeners();
  }

  // ─── invoice-id helpers ───────────────────────────────────────────────────

  ReceiptRecord _ensureSequentialInvoiceId(
    ReceiptRecord receipt, {
    String? excludeId,
  }) {
    final existingIds = _receipts
        .where((r) => r.invoiceId != null && r.id != excludeId)
        .map((r) => r.invoiceId!)
        .toSet();

    final currentId = receipt.invoiceId?.trim();
    if (currentId != null &&
        currentId.isNotEmpty &&
        !existingIds.contains(currentId)) {
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
      userUid: receipt.userUid,
      status: receipt.status,
    );
  }

  int _nextInvoiceNumber(Set<String> existingIds) {
    var maxNumber = 0;
    for (final id in existingIds) {
      final match = RegExp(r'^(?:INV-)?(\d+)$').firstMatch(id);
      if (match != null) {
        final value = int.tryParse(match.group(1)!);
        if (value != null && value > maxNumber) maxNumber = value;
      }
    }
    return maxNumber + 1;
  }

  // ─── analytics helpers (unchanged) ───────────────────────────────────────

  double salesForMonth(DateTime month) {
    return _receipts
        .where((r) => _isSameMonth(r.date, month))
        .fold<double>(0, (sum, r) => sum + r.total);
  }

  double salesForYear(int year) {
    return _receipts
        .where((r) => r.date.year == year)
        .fold<double>(0, (sum, r) => sum + r.total);
  }

  int receiptsForMonth(DateTime month) =>
      _receipts.where((r) => _isSameMonth(r.date, month)).length;

  int uniqueCustomerCount() => _receipts
      .map((r) => _normalizeCustomer(r.customerName))
      .where((name) => name.isNotEmpty)
      .toSet()
      .length;

  List<MonthlyRevenue> monthlyRevenueSeries({
    int months = 6,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return List<MonthlyRevenue>.generate(months, (index) {
      final month = _addMonths(currentMonth, -(months - 1 - index));
      final amount = _receipts
          .where((r) => _isSameMonth(r.date, month))
          .fold<double>(0, (sum, r) => sum + r.total);

      return MonthlyRevenue(label: _monthLabel(month.month), amount: amount);
    });
  }

  List<CustomerInsight> topCustomers({int limit = 4}) {
    final groups = <String, CustomerInsight>{};

    for (final receipt in _receipts) {
      final key = _normalizeCustomer(receipt.customerName);
      if (key.isEmpty) continue;

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

    return (groups.values.toList()..sort((a, b) => b.spent.compareTo(a.spent)))
        .take(limit)
        .toList();
  }

  // ─── private utilities ────────────────────────────────────────────────────

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  String _normalizeCustomer(String value) => value.trim().toLowerCase();

  DateTime _addMonths(DateTime base, int months) {
    final year = base.year + ((base.month - 1 + months) ~/ 12);
    final month = ((base.month - 1 + months) % 12) + 1;
    return DateTime(year, month);
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }
}

// ─── Data models (unchanged) ─────────────────────────────────────────────────
enum InvoiceStatus { paid, outstanding }

class ReceiptRecord {
  final String id;
  final String customerName;
  final String? invoiceId;
  final DateTime date;
  final DateTime createdAt;
  final List<ReceiptLineItem> items;
  final String userUid;
  final InvoiceStatus status;

  const ReceiptRecord({
    required this.id,
    required this.userUid,
    required this.customerName,
    required this.invoiceId,
    required this.date,
    required this.createdAt,
    required this.items,
    required this.status,
  });

  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.1;
  double get total => subtotal + tax;
  double get totalCost => items.fold<double>(
    0,
    (sum, item) => sum + (item.costPrice * item.quantity),
  );
  double get profit => subtotal - totalCost;
  double get totalProfit => profit;
  
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'customerName': customerName,
    'customer_name': customerName,
    'invoiceId': invoiceId,
    'userUid': userUid,
    'status': status.name,
    // Store as real Firestore timestamps
    'date': Timestamp.fromDate(date),
    'createdAt': Timestamp.fromDate(createdAt),

    'items': items.map((i) => i.toJson()).toList(),
  };

  factory ReceiptRecord.fromJson(Map<String, dynamic> json) {
    // Helper that handles both ISO strings and Firestore Timestamps.
    DateTime _parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    }

    return ReceiptRecord(
      id: json['id'] as String? ?? '',
      userUid: json['userUid'] as String? ?? '',
      customerName:
          (json['customer_name'] as String?) ??
          (json['customerName'] as String?) ??
          'عميل نُقطة',
      invoiceId: json['invoiceId'] as String?,
      date: _parseDate(json['date']),
      createdAt: _parseDate(json['createdAt']),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.paid,
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ReceiptLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReceiptLineItem {
  final String item;
  final int quantity;
  final double unitPrice;
  final double cost;
  double get costPrice => cost;

  const ReceiptLineItem({
    required this.item,
    required this.quantity,
    required this.unitPrice,
    required double costPrice,
  }) : cost = costPrice;

  double get total => quantity * unitPrice;
  double get profit => quantity * (unitPrice - cost);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item': item,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'cost': cost,
    'costPrice': cost,
  };

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) =>
      ReceiptLineItem(
        item: json['item'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        costPrice:
            (json['cost'] as num?)?.toDouble() ??
            (json['costPrice'] as num?)?.toDouble() ??
            0,
      );
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

  CustomerInsight copyWith({String? name, int? orderCount, double? spent}) =>
      CustomerInsight(
        name: name ?? this.name,
        orderCount: orderCount ?? this.orderCount,
        spent: spent ?? this.spent,
      );
}
