import 'package:invoice_ai/data/receipt_store.dart';

class InvoiceLine {
  final String name;
  final int quantity;
  final double unitPrice;
  final double cost;
  double get costPrice => cost;

  const InvoiceLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required double costPrice,
  }) : cost = costPrice;

  double get total => quantity * unitPrice;
  double get profit => (unitPrice - cost) * quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'cost': cost,
    'costPrice': cost,
  };

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      costPrice:
          (json['cost'] as num?)?.toDouble() ??
          (json['costPrice'] as num?)?.toDouble() ??
          0,
    );
  }
}

class InvoiceModel {
  final String id;
  final String userUid;
  final String customerName;
  final DateTime date;
  final double totalAmount;
  final InvoiceStatus status;
  final List<InvoiceLine> items;
  final DateTime createdAt;
  final String? invoiceId;

  const InvoiceModel({
    required this.id,
    required this.userUid,
    required this.customerName,
    required this.date,
    required this.totalAmount,
    required this.status,
    this.items = const [],
    required this.createdAt,
    this.invoiceId,
  });

  double get totalProfit =>
      items.fold<double>(0, (sum, item) => sum + item.profit);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userUid': userUid,
    'customerName': customerName,
    'customer_name': customerName,
    'date': date.toIso8601String(),
    'totalAmount': totalAmount,
    'status': status.name,
    'items': items.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'invoiceId': invoiceId,
  };

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    }

    return InvoiceModel(
      id: json['id'] as String? ?? '',
      userUid: json['userUid'] as String? ?? '',
      customerName:
          (json['customer_name'] as String?) ??
          (json['customerName'] as String?) ??
          'عميل نُقطة',
      date: parseDate(json['date']),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.outstanding,
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: parseDate(json['createdAt']),
      invoiceId: json['invoiceId'] as String?,
    );
  }
}
