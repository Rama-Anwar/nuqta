import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A lightweight model representing one document from the
/// top-level `pending_invoices` Firestore collection.
class PendingInvoice {
  final String docId;
  final String customerName;
  final String invoiceId;
  final String status;
  final DateTime? date;
  final List<PendingInvoiceItem> items;

  const PendingInvoice({
    required this.docId,
    required this.customerName,
    required this.invoiceId,
    required this.status,
    this.date,
    required this.items,
  });

  factory PendingInvoice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // invoice_id may arrive as a number or a string from n8n
    final rawId = data['invoice_id'];
    final invoiceIdStr = rawId == null ? '' : rawId.toString();

    final rawItems = data['items'];
    final items = <PendingInvoiceItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          items.add(PendingInvoiceItem.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return PendingInvoice(
      docId: doc.id,
      customerName: (data['customer_name'] as String?) ?? 'Unknown',
      invoiceId: invoiceIdStr,
      status: (data['status'] as String?) ?? 'pending_review',
      date: _parseDate(
        data['date'] ??
            data['invoice_date'] ??
            data['created_at'] ??
            data['createdAt'],
      ),
      items: items,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

class PendingInvoiceItem {
  final String item;
  final int qty;
  final double price;
  final double cost;

  const PendingInvoiceItem({
    required this.item,
    required this.qty,
    required this.price,
    required this.cost,
  });

  factory PendingInvoiceItem.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return PendingInvoiceItem(
      item:
          (map['item'] as String?) ??
          (map['name'] as String?) ??
          (map['product'] as String?) ??
          '',
      qty: parseInt(map['qty'] ?? map['quantity'] ?? map['count']),
      price: parseDouble(map['price'] ?? map['unit_price'] ?? map['unitPrice']),
      cost: parseDouble(map['cost'] ?? map['cost_price'] ?? map['costPrice']),
    );
  }
}

/// Singleton service that wraps the `pending_invoices` collection.
class PendingInvoicesService {
  PendingInvoicesService._();
  static final PendingInvoicesService instance = PendingInvoicesService._();

  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('pending_invoices');

  Future<String> _currentOrganizationId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to access invoices.');
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final organizationId = userDoc.data()?['organization_id'];

    if (organizationId is! String || organizationId.trim().isEmpty) {
      throw StateError(
        'The signed-in user does not have a valid organization_id.',
      );
    }

    return organizationId.trim();
  }

  Future<String> currentOrganizationId() => _currentOrganizationId();

  Future<DocumentReference<Map<String, dynamic>>>
  _invoiceForCurrentOrganization(String docId) async {
    final organizationId = await _currentOrganizationId();
    final snapshot = await _col
        .where('organization_id', isEqualTo: organizationId)
        .where(FieldPath.documentId, isEqualTo: docId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError(
        'Invoice $docId was not found in the current organization.',
      );
    }

    return snapshot.docs.single.reference;
  }

  /// Real-time stream of invoices with status == "pending_review".
  Stream<List<PendingInvoice>> pendingStream() async* {
    final organizationId = await _currentOrganizationId();

    yield* _col
        .where('organization_id', isEqualTo: organizationId)
        .where('status', isEqualTo: 'pending_review')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => PendingInvoice.fromDoc(d)).toList(),
        );
  }

  /// Update the status of a single document.
  Future<void> updateStatus(String docId, String newStatus) async {
    final invoice = await _invoiceForCurrentOrganization(docId);
    await invoice.update({'status': newStatus});
  }

  /// Persist all user edits back to the Firestore document **and** set
  /// status to "completed" in a single atomic [update] call.
  ///
  /// [items] is the final list of line-items after any in-app edits.
  Future<void> approveInvoice({
    required String docId,
    required String customerName,
    required String invoiceId,
    required List<Map<String, dynamic>> items,
  }) async {
    final invoice = await _invoiceForCurrentOrganization(docId);
    await invoice.update({
      'customer_name': customerName,
      'invoice_id': invoiceId,
      'items': items,
      'status': 'completed',
      'approved_at': DateTime.now().toIso8601String(),
    });
  }
}
