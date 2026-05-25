import 'package:flutter/material.dart';

import 'data/receipt_store.dart';
import 'nav.dart';

class DashPage extends StatefulWidget {
  const DashPage({super.key});

  @override
  State<DashPage> createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = ReceiptStore.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D20),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: FutureBuilder<void>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFEE671C)),
                    );
                  }

                  return AnimatedBuilder(
                    animation: ReceiptStore.instance,
                    builder: (context, _) {
                      final store = ReceiptStore.instance;
                      final now = DateTime.now();
                      final thisMonth = store.salesForMonth(now);
                      final lastMonth = store.salesForMonth(DateTime(now.year, now.month - 1));
                      final thisYear = store.salesForYear(now.year);
                      final receiptCount = store.receiptsForMonth(now);
                      final customerCount = store.uniqueCustomerCount();
                      final trend = store.monthlyRevenueSeries(months: 6, referenceDate: now);
                      final customers = store.topCustomers(limit: 4);

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1024;

                          final summaryRow = isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _SummaryCard(
                                        title: 'Total Sales This Month',
                                        value: _currency(thisMonth),
                                        delta: _growthText(thisMonth, lastMonth),
                                        icon: Icons.trending_up_rounded,
                                        iconBackground: const Color(0xFF1E2723),
                                        iconColor: const Color(0xFF81B29A),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _SummaryCard(
                                        title: 'Total Sales This Year',
                                        value: _currency(thisYear),
                                        delta: '$receiptCount saved receipts · $customerCount customers',
                                        icon: Icons.calendar_today_rounded,
                                        iconBackground: const Color(0xFF313539),
                                        iconColor: const Color(0xFFBDC1C6),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _SummaryCard(
                                      title: 'Total Sales This Month',
                                      value: _currency(thisMonth),
                                      delta: _growthText(thisMonth, lastMonth),
                                      icon: Icons.trending_up_rounded,
                                      iconBackground: const Color(0xFF1E2723),
                                      iconColor: const Color(0xFF81B29A),
                                    ),
                                    const SizedBox(height: 16),
                                    _SummaryCard(
                                      title: 'Total Sales This Year',
                                      value: _currency(thisYear),
                                      delta: '$receiptCount saved receipts · $customerCount customers',
                                      icon: Icons.calendar_today_rounded,
                                      iconBackground: const Color(0xFF313539),
                                      iconColor: const Color(0xFFBDC1C6),
                                    ),
                                  ],
                                );

                          final contentRow = isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 8, child: _RevenueTrendCard(series: trend)),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 380, child: _TopCustomersCard(customers: customers)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _RevenueTrendCard(series: trend),
                                    const SizedBox(height: 16),
                                    _TopCustomersCard(customers: customers),
                                  ],
                                );

                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, isWide ? 24 : 96),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _PageHeader(),
                                const SizedBox(height: 24),
                                summaryRow,
                                const SizedBox(height: 16),
                                contentRow,
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 0),
    );
  }

  String _growthText(double currentMonth, double lastMonth) {
    if (lastMonth <= 0) {
      return currentMonth <= 0 ? 'No saved receipts yet' : '+100% vs last month';
    }

    final delta = ((currentMonth - lastMonth) / lastMonth) * 100;
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)}% vs last month';
  }

  String _currency(double value) => '\$${value.toStringAsFixed(2)}';
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1417),
        border: Border(bottom: BorderSide(color: Color(0xFF3E444A))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFEE671C), size: 28),
                SizedBox(width: 12),
                Text(
                  'Invoice AI',
                  style: TextStyle(
                    color: Color(0xFFEE671C),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            if (isDesktop)
              Row(
                children: const [
                  _DesktopNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', active: true, route: AppRoutes.dash),
                  _DesktopNavItem(icon: Icons.receipt_long_rounded, label: 'Receipts', active: false, route: AppRoutes.receipts),
                  _DesktopNavItem(icon: Icons.description_rounded, label: 'Invoices', active: false, route: AppRoutes.invoices),
                  _DesktopNavItem(icon: Icons.person_rounded, label: 'Profile', active: false, route: AppRoutes.profile),
                ],
              )
            else
              const SizedBox.shrink(),
            if (isDesktop)
              const Row(
                children: [
                  _IconAction(icon: Icons.search_rounded),
                  SizedBox(width: 12),
                  _IconAction(icon: Icons.notifications_rounded, showDot: true),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final String route;

  const _DesktopNavItem({required this.icon, required this.label, required this.active, required this.route});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFEE671C) : const Color(0xFFE0C0B2);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: () {
          if (active) return;
          Navigator.of(context).pushReplacementNamed(route);
        },
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final bool showDot;

  const _IconAction({required this.icon, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2B3035),
        border: Border.all(color: const Color(0xFF3E444A)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: const Color(0xFFDEE2E6), size: 20),
          if (showDot)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEE671C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            color: Color(0xFFDEE2E6),
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Financial performance summary',
          style: TextStyle(
            color: Color(0xFFBDC1C6),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2B3035),
        border: Border.all(color: const Color(0xFF3E444A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFBDC1C6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFDEE2E6),
              fontSize: 40,
              fontFamily: 'monospace',
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            delta,
            style: TextStyle(
              color: iconColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueTrendCard extends StatelessWidget {
  final List<MonthlyRevenue> series;

  const _RevenueTrendCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final maxAmount = series.fold<double>(0, (maxValue, point) => point.amount > maxValue ? point.amount : maxValue);
    final chartMax = maxAmount <= 0 ? 1.0 : maxAmount;
    final hasData = maxAmount > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2B3035),
        border: Border.all(color: const Color(0xFF3E444A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Revenue Trend',
                style: TextStyle(
                  color: Color(0xFFDEE2E6),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _PillButton(label: 'YTD', active: true),
                  _PillButton(label: '12M', active: false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_axisLabel(chartMax), style: const TextStyle(color: Color(0xFFBDC1C6), fontSize: 12, fontFamily: 'monospace')),
                      Text(_axisLabel(chartMax * 0.66), style: const TextStyle(color: Color(0xFFBDC1C6), fontSize: 12, fontFamily: 'monospace')),
                      Text(_axisLabel(chartMax * 0.33), style: const TextStyle(color: Color(0xFFBDC1C6), fontSize: 12, fontFamily: 'monospace')),
                      const Text('0', style: TextStyle(color: Color(0xFFBDC1C6), fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(series.length, (index) {
                              final point = series[index];
                              final isCurrentMonth = index == series.length - 1;
                              final factor = point.amount <= 0 ? 0.06 : (point.amount / chartMax).clamp(0.06, 1.0);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: _ChartBar(
                                    fill: isCurrentMonth ? const Color(0xFFEE671C) : const Color(0xFF313539),
                                    factor: factor,
                                    value: _currency(point.amount),
                                    active: isCurrentMonth,
                                    hasData: hasData,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(series.length, (index) {
                          final point = series[index];
                          final isCurrentMonth = index == series.length - 1;
                          return Expanded(
                            child: Text(
                              point.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isCurrentMonth ? const Color(0xFFEE671C) : const Color(0xFFBDC1C6),
                                fontWeight: isCurrentMonth ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!hasData) ...[
            const SizedBox(height: 12),
            const Text(
              'No saved receipts yet. Add receipts to populate this chart.',
              style: TextStyle(color: Color(0xFFBDC1C6), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  String _axisLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _currency(double value) => '\$${value.toStringAsFixed(0)}';
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool active;

  const _PillButton({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF313539) : Colors.transparent,
        border: Border.all(color: const Color(0xFF3E444A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFFDEE2E6) : const Color(0xFFBDC1C6),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final Color fill;
  final double factor;
  final String value;
  final bool active;
  final bool hasData;

  const _ChartBar({
    required this.fill,
    required this.factor,
    required this.value,
    required this.active,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3E444A)),
          ),
        ),
        FractionallySizedBox(
          heightFactor: factor,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              boxShadow: active
                  ? const [BoxShadow(color: Color.fromRGBO(211, 84, 0, 0.2), blurRadius: 20)]
                  : null,
            ),
          ),
        ),
        Positioned(
          top: -34,
          child: Opacity(
            opacity: hasData ? 0 : 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1417),
                border: Border.all(color: active ? const Color(0xFFEE671C) : const Color(0xFF3E444A)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: active ? const Color(0xFFEE671C) : const Color(0xFFBDC1C6),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopCustomersCard extends StatelessWidget {
  final List<CustomerInsight> customers;

  const _TopCustomersCard({required this.customers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B3035),
        border: Border.all(color: const Color(0xFF3E444A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Customers',
                  style: TextStyle(
                    color: Color(0xFFDEE2E6),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEE671C),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D20),
              border: Border(
                top: BorderSide(color: Color(0xFF3E444A)),
                bottom: BorderSide(color: Color(0xFF3E444A)),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Client',
                    style: TextStyle(
                      color: Color(0xFFBDC1C6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Orders',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFFBDC1C6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Spent',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFFBDC1C6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (customers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No customer data yet. Save receipts to populate this section.',
                style: TextStyle(color: Color(0xFFBDC1C6), fontSize: 14),
              ),
            )
          else
            ...customers.map(
              (entry) => Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF3E444A))),
                ),
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF313539),
                                  border: Border.all(color: const Color(0xFF3E444A)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _initials(entry.name),
                                  style: const TextStyle(
                                    color: Color(0xFFDEE2E6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFDEE2E6),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.orderCount.toString(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFFBDC1C6),
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _spentLabel(entry.spent),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFFDEE2E6),
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _spentLabel(double value) => '\$${value.toStringAsFixed(0)}';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '--';
    }
    if (parts.length == 1) {
      final word = parts.first;
      return word.length <= 2 ? word.toUpperCase() : word.substring(0, 2).toUpperCase();
    }
    final first = parts.first[0];
    final last = parts.last[0];
    return '$first$last'.toUpperCase();
  }
}
