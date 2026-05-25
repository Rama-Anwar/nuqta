class InvoiceLine {
  final String name;
  final int quantity;
  final double unitPrice;

  const InvoiceLine({required this.name, required this.quantity, required this.unitPrice});
}

enum InvoiceStatus { paid, sent, draft, overdue }

class InvoiceModel {
  final String id;
  final String customerName;
  final DateTime date;
  final double totalAmount;
  final InvoiceStatus status;
  final List<InvoiceLine> items;
  final DateTime createdAt;
  final String? invoiceId;

  const InvoiceModel({
    required this.id,
    required this.customerName,
    required this.date,
    required this.totalAmount,
    required this.status,
    this.items = const [],
    required this.createdAt,
    this.invoiceId,
  });
}
