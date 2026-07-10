import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_ai/data/receipt_store.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance = DashboardService._();

  Stream<DashboardData> dashboardStream() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to load the dashboard.');
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

    yield* FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId.trim())
        .collection('receipts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final receipts = snapshot.docs
              .map(
                (doc) => ReceiptRecord.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();

          return DashboardData.fromReceipts(receipts);
        });
  }
}

class DashboardData {
  final List<ReceiptRecord> receipts;
  final List<DashboardMonthPoint> monthlyPoints;
  final List<DashboardProduct> bestProducts;
  final List<DashboardProduct> leastProducts;
  final List<DashboardCustomer> topCustomers;
  final int customerCount;
  final double averageInvoice;

  const DashboardData({
    required this.receipts,
    required this.monthlyPoints,
    required this.bestProducts,
    required this.leastProducts,
    required this.topCustomers,
    required this.customerCount,
    required this.averageInvoice,
  });

  factory DashboardData.fromReceipts(List<ReceiptRecord> receipts) {
    final topCustomers = _buildTopCustomers(receipts);
    return DashboardData(
      receipts: receipts,
      monthlyPoints: _buildMonthlyPoints(receipts),
      bestProducts: _buildProducts(receipts, least: false),
      leastProducts: _buildProducts(receipts, least: true),
      topCustomers: topCustomers,
      customerCount: topCustomers.length,
      averageInvoice: receipts.isEmpty
          ? 0
          : _sumTotal(receipts) / receipts.length,
    );
  }

  DashboardPeriodStats statsFor(DashboardPeriod period) {
    final now = DateTime.now();
    final currentRange = _rangeForPeriod(period, now, 0);
    final previousRange = _rangeForPeriod(period, now, -1);
    final current = receipts
        .where((r) => currentRange.contains(r.date))
        .toList();
    final previous = receipts
        .where((r) => previousRange.contains(r.date))
        .toList();

    final currentTotal = _sumTotal(current);
    final previousTotal = _sumTotal(previous);
    final currentProfit = _sumProfit(current);
    final previousProfit = _sumProfit(previous);

    return DashboardPeriodStats(
      total: currentTotal,
      totalProfit: currentProfit,
      paidTotal: _sumTotal(
        current.where((r) => r.status == InvoiceStatus.paid).toList(),
      ),
      averageInvoice: current.isEmpty ? 0 : currentTotal / current.length,
      customerCount: current
          .map((r) => r.customerName.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet()
          .length,
      growthPercent: _growthPercent(currentTotal, previousTotal),
      profitGrowthPercent: _growthPercent(currentProfit, previousProfit),
    );
  }

  double get chartMaxY {
    final maxValue = monthlyPoints.fold<double>(
      0,
      (max, point) =>
          [max, point.revenue, point.expenses].reduce((a, b) => a > b ? a : b),
    );
    if (maxValue <= 0) return 100;
    return (maxValue * 1.2).ceilToDouble();
  }

  static List<DashboardMonthPoint> _buildMonthlyPoints(
    List<ReceiptRecord> receipts,
  ) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return List<DashboardMonthPoint>.generate(6, (index) {
      final month = _addMonths(currentMonth, -(5 - index));
      final monthReceipts = receipts
          .where((receipt) => _isSameMonth(receipt.date, month))
          .toList();

      return DashboardMonthPoint(
        label: _monthLabel(month.month).toUpperCase(),
        revenue: _sumTotal(monthReceipts),
        expenses: monthReceipts.fold<double>(
          0,
          (total, receipt) => total + receipt.totalCost,
        ),
      );
    });
  }

  static List<DashboardProduct> _buildProducts(
    List<ReceiptRecord> receipts, {
    required bool least,
  }) {
    final groups = <String, _ProductAccumulator>{};

    for (final receipt in receipts) {
      for (final item in receipt.items) {
        final name = item.item.trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        groups.putIfAbsent(key, () => _ProductAccumulator(name)).add(item);
      }
    }

    final products =
        groups.values
            .map(
              (group) => DashboardProduct(
                name: group.name,
                revenue: group.revenue,
                units: group.units,
              ),
            )
            .toList()
          ..sort(
            (a, b) =>
                least ? a.units.compareTo(b.units) : b.units.compareTo(a.units),
          );

    return products.take(4).toList();
  }

  static List<DashboardCustomer> _buildTopCustomers(
    List<ReceiptRecord> receipts,
  ) {
    final groups = <String, DashboardCustomer>{};

    for (final receipt in receipts) {
      final name = receipt.customerName.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      final current = groups[key];
      groups[key] = DashboardCustomer(
        name: current?.name ?? name,
        invoiceCount: (current?.invoiceCount ?? 0) + 1,
        spent: (current?.spent ?? 0) + receipt.total,
      );
    }

    return groups.values.toList()..sort((a, b) => b.spent.compareTo(a.spent));
  }

  static double _sumTotal(List<ReceiptRecord> receipts) {
    return receipts.fold<double>(0, (total, receipt) => total + receipt.total);
  }

  static double _sumProfit(List<ReceiptRecord> receipts) {
    return receipts.fold<double>(0, (total, receipt) => total + receipt.profit);
  }

  static double _growthPercent(double current, double previous) {
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }

  static _DateRange _rangeForPeriod(
    DashboardPeriod period,
    DateTime now,
    int offset,
  ) {
    switch (period) {
      case DashboardPeriod.today:
        final day = DateTime(now.year, now.month, now.day + offset);
        return _DateRange(day, day.add(const Duration(days: 1)));
      case DashboardPeriod.week:
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1) + (offset * 7),
        );
        return _DateRange(
          startOfWeek,
          startOfWeek.add(const Duration(days: 7)),
        );
      case DashboardPeriod.month:
        final month = _addMonths(DateTime(now.year, now.month), offset);
        return _DateRange(month, _addMonths(month, 1));
      case DashboardPeriod.year:
        final year = DateTime(now.year + offset);
        return _DateRange(year, DateTime(year.year + 1));
    }
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static DateTime _addMonths(DateTime base, int months) {
    final year = base.year + ((base.month - 1 + months) ~/ 12);
    final month = ((base.month - 1 + months) % 12) + 1;
    return DateTime(year, month);
  }

  static String _monthLabel(int month) {
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

enum DashboardPeriod { today, week, month, year }

class DashboardPeriodStats {
  final double total;
  final double totalProfit;
  final double paidTotal;
  final double averageInvoice;
  final int customerCount;
  final double growthPercent;
  final double profitGrowthPercent;

  const DashboardPeriodStats({
    required this.total,
    required this.totalProfit,
    required this.paidTotal,
    required this.averageInvoice,
    required this.customerCount,
    required this.growthPercent,
    required this.profitGrowthPercent,
  });
}

class DashboardMonthPoint {
  final String label;
  final double revenue;
  final double expenses;

  const DashboardMonthPoint({
    required this.label,
    required this.revenue,
    required this.expenses,
  });
}

class DashboardProduct {
  final String name;
  final double revenue;
  final int units;

  const DashboardProduct({
    required this.name,
    required this.revenue,
    required this.units,
  });
}

class DashboardCustomer {
  final String name;
  final int invoiceCount;
  final double spent;

  const DashboardCustomer({
    required this.name,
    required this.invoiceCount,
    required this.spent,
  });
}

class _ProductAccumulator {
  final String name;
  double revenue = 0;
  int units = 0;

  _ProductAccumulator(this.name);

  void add(ReceiptLineItem item) {
    revenue += item.total;
    units += item.quantity;
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange(this.start, this.end);

  bool contains(DateTime value) {
    return !value.isBefore(start) && value.isBefore(end);
  }
}
