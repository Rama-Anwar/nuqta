import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';
import 'package:invoice_ai/nav.dart';
import 'package:invoice_ai/services/dashboard_service.dart';
import 'package:invoice_ai/widgets/pending_invoices_badge.dart';

class AppColors {
  static const Color primaryBg = Color(0xFF1A1D20);
  static const Color surface = Color(0xFF2B3035);
  static const Color surfaceContainer = Color(0xFF1B2023);
  static const Color borderLowContrast = Color(0xFF3E444A);
  static const Color accent = Color(0xFFEE671C);
  static const Color textMain = Color(0xFFDEE2E6);
  static const Color textDim = Color(0xFFBDC1C6);
  static const Color success = Color(0xFF81B29A);
  static const Color error = Color(0xFFE07A5F);
}

class DashPage extends StatefulWidget {
  const DashPage({super.key});

  @override
  State<DashPage> createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  String selectedRevenuePeriod = 'MONTH';
  String selectedSalesPeriod = 'MONTH';
  String selectedProductTab = 'BEST';
  late final Stream<DashboardData> _dashboardStream;

  @override
  void initState() {
    super.initState();
    _dashboardStream = DashboardService.instance.dashboardStream();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          l10n.dashboard,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          PendingInvoicesBadgeButton(
            onInvoiceSelected: (invoice) {
              AppTabScope.maybeOf(context)?.openPendingInvoice?.call(invoice);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppColors.borderLowContrast, height: 1),
        ),
      ),
      body: StreamBuilder<DashboardData>(
        stream: _dashboardStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildStateMessage(
              l10n.dashboardLoadError,
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          return _buildDashboard(snapshot.data!, l10n);
        },
      ),
    );
  }

  Widget _buildDashboard(DashboardData data, AppLocalizations l10n) {
    final profitStats = data.statsFor(_periodFromLabel(selectedRevenuePeriod));
    final salesStats = data.statsFor(_periodFromLabel(selectedSalesPeriod));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        _buildInteractiveKPI(
          title: l10n.dashboardTotalProfit,
          value: _currency(profitStats.totalProfit),
          selectedPeriod: selectedRevenuePeriod,
          l10n: l10n,
          onPeriodChanged: (p) => setState(() => selectedRevenuePeriod = p),
        ),
        const SizedBox(height: 16),
        _buildInteractiveKPI(
          title: l10n.dashboardPaidSales,
          value: _currency(salesStats.paidTotal),
          selectedPeriod: selectedSalesPeriod,
          l10n: l10n,
          onPeriodChanged: (p) => setState(() => selectedSalesPeriod = p),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 120,
                child: _buildSimpleStatCard(
                  l10n.dashboardAverageInvoice,
                  _currency(profitStats.averageInvoice),
                  null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 120,
                child: _buildSimpleStatCard(
                  l10n.dashboardCustomers,
                  profitStats.customerCount.toString(),
                  null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(
          l10n.dashboardRevenueVsExpenses,
          l10n.dashboardMonthlyPerformance,
        ),
        const SizedBox(height: 12),
        _buildGroupedBarChart(data, l10n),
        const SizedBox(height: 24),
        _buildProductSwitcherCard(data, l10n),
        const SizedBox(height: 24),
        _buildCustomerList(data, l10n),
      ],
    );
  }

  Widget _buildInteractiveKPI({
    required String title,
    required String value,
    required String selectedPeriod,
    required AppLocalizations l10n,
    required Function(String) onPeriodChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: AppColors.textMain,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: ['TODAY', 'WEEK', 'MONTH', 'YEAR'].map((period) {
              final isSelected = selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPeriodChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        _periodLabel(period, l10n),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDim,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatCard(String label, String val, String? sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            val,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: AppColors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildGroupedBarChart(DashboardData data, AppLocalizations l10n) {
    final points = data.monthlyPoints;
    final maxY = data.chartMaxY;
    final interval = maxY <= 100 ? 20.0 : (maxY / 5).ceilToDouble();

    return Container(
      height: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegend(l10n.dashboardRevenue, AppColors.accent),
                const SizedBox(width: 14),
                _buildLegend(l10n.dashboardExpenses, AppColors.error),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0
                          ? l10n.dashboardRevenue
                          : l10n.dashboardExpenses;
                      return BarTooltipItem(
                        '$label\n${_currency(rod.toY)}',
                        const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _localizedMonthLabel(points[index].label, l10n),
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => Text(
                        _compactNumber(value),
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderLowContrast.withValues(alpha: 0.24),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(points.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: points[index].revenue,
                        color: AppColors.accent,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: points[index].expenses,
                        color: AppColors.error,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSwitcherCard(
    DashboardData data,
    AppLocalizations l10n,
  ) {
    final title = selectedProductTab == 'BEST'
        ? l10n.dashboardBestSellingProducts
        : l10n.dashboardLeastSellingProducts;
    final products = selectedProductTab == 'BEST'
        ? data.bestProducts
        : data.leastProducts;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: ['BEST', 'LEAST'].map((mode) {
                    final isSelected = selectedProductTab == mode;
                    return GestureDetector(
                      onTap: () => setState(() => selectedProductTab = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _productTabLabel(mode, l10n),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDim,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            _buildEmptyInline(l10n.dashboardNoProductSales)
          else
            ...products.map((product) => _buildProductRow(product, l10n)),
        ],
      ),
    );
  }

  Widget _buildProductRow(DashboardProduct product, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.dashboardInvoiceLineItem,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency(product.revenue),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dashboardUnits(product.units),
                style: const TextStyle(color: AppColors.textDim, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(DashboardData data, AppLocalizations l10n) {
    final customers = data.topCustomers.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTopCustomersByValue,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (customers.isEmpty)
            _buildEmptyInline(l10n.dashboardNoCustomers)
          else
            ...customers.map((customer) => _buildCustomerRow(customer, l10n)),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(
    DashboardCustomer customer,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLowContrast.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.dashboardInvoicesCount(customer.invoiceCount),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _currency(customer.spent),
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStateMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textDim),
        ),
      ),
    );
  }

  Widget _buildEmptyInline(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(message, style: const TextStyle(color: AppColors.textDim)),
    );
  }

  DashboardPeriod _periodFromLabel(String label) {
    switch (label) {
      case 'TODAY':
        return DashboardPeriod.today;
      case 'WEEK':
        return DashboardPeriod.week;
      case 'YEAR':
        return DashboardPeriod.year;
      case 'MONTH':
      default:
        return DashboardPeriod.month;
    }
  }

  String _periodLabel(String label, AppLocalizations l10n) {
    switch (label) {
      case 'TODAY':
        return l10n.dashboardToday;
      case 'WEEK':
        return l10n.dashboardWeek;
      case 'YEAR':
        return l10n.dashboardYear;
      case 'MONTH':
      default:
        return l10n.dashboardMonth;
    }
  }

  String _productTabLabel(String label, AppLocalizations l10n) {
    return label == 'BEST' ? l10n.dashboardBest : l10n.dashboardLeast;
  }

  String _localizedMonthLabel(String label, AppLocalizations l10n) {
    switch (label.toUpperCase()) {
      case 'JAN':
        return l10n.jan;
      case 'FEB':
        return l10n.feb;
      case 'MAR':
        return l10n.mar;
      case 'APR':
        return l10n.apr;
      case 'MAY':
        return l10n.may;
      case 'JUN':
        return l10n.jun;
      case 'JUL':
        return l10n.jul;
      case 'AUG':
        return l10n.aug;
      case 'SEP':
        return l10n.sep;
      case 'OCT':
        return l10n.oct;
      case 'NOV':
        return l10n.nov;
      case 'DEC':
        return l10n.dec;
      default:
        return label;
    }
  }

  String _currency(double value) {
    final negative = value < 0;
    final whole = value.abs().toStringAsFixed(2);
    final parts = whole.split('.');
    final buffer = StringBuffer();
    for (var i = 0; i < parts.first.length; i++) {
      final remaining = parts.first.length - i;
      buffer.write(parts.first[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return '${negative ? '-' : ''}\$${buffer.toString()}.${parts.last}';
  }

  String _compactNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}
