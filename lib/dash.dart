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
            color: AppColors.textMain,
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
            return _buildStateMessage(l10n.dashboardLoadError);
          }

          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          return _buildDashboard(snapshot.data!, l10n);
        },
      ),
    );
  }

  Widget _buildDashboard(DashboardData data, AppLocalizations l10n) {
    final revenuePeriod = _periodFromLabel(selectedRevenuePeriod);
    final profitStats = data.statsFor(revenuePeriod);
    final salesStats = data.statsFor(_periodFromLabel(selectedSalesPeriod));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final content = <Widget>[
          _buildKpiGrid(
            profitStats,
            salesStats,
            data.averageInvoice,
            data.customerCount,
            l10n,
          ),
          SizedBox(height: isDesktop ? 28 : 24),
          _buildSectionHeader(
            l10n.dashboardRevenueVsExpenses,
            l10n.dashboardMonthlyPerformance,
          ),
          const SizedBox(height: 12),
          if (isDesktop)
            Column(
              children: [
                _buildGroupedBarChart(data, l10n),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildProductSwitcherCard(data, l10n),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _buildCustomerList(data, l10n)),
                  ],
                ),
              ],
            )
          else ...[
            _buildGroupedBarChart(data, l10n),
            const SizedBox(height: 24),
            _buildProductSwitcherCard(data, l10n),
            const SizedBox(height: 24),
            _buildCustomerList(data, l10n),
          ],
        ];

        return ListView(
          padding: EdgeInsets.fromLTRB(16, isDesktop ? 24 : 12, 16, 44),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(
    DashboardPeriodStats profitStats,
    DashboardPeriodStats salesStats,
    double averageInvoice,
    int customerCount,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1024;
        final isTablet = width >= 620;
        final spacing = isDesktop ? 16.0 : 14.0;
        final tileWidth = isDesktop
            ? (width - spacing * 3) / 4
            : isTablet
            ? (width - spacing) / 2
            : width;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: tileWidth,
              child: _buildInteractiveKPI(
                title: l10n.dashboardTotalProfit,
                value: _currency(profitStats.totalProfit),
                selectedPeriod: selectedRevenuePeriod,
                l10n: l10n,
                onPeriodChanged: (p) =>
                    setState(() => selectedRevenuePeriod = p),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _buildInteractiveKPI(
                title: l10n.dashboardPaidSales,
                value: _currency(salesStats.paidTotal),
                selectedPeriod: selectedSalesPeriod,
                l10n: l10n,
                onPeriodChanged: (p) => setState(() => selectedSalesPeriod = p),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _buildSimpleStatCard(
                l10n.dashboardAverageInvoice,
                _currency(averageInvoice),
                null,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _buildSimpleStatCard(
                l10n.dashboardCustomers,
                customerCount.toString(),
                null,
              ),
            ),
          ],
        );
      },
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
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricValue(value, fontSize: 22),
          const SizedBox(height: 22),
          Row(
            children: ['TODAY', 'WEEK', 'MONTH', 'YEAR'].map((period) {
              final isSelected = selectedPeriod == period;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      onTap: () => onPeriodChanged(period),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.borderLowContrast.withValues(
                                    alpha: 0.38,
                                  ),
                          ),
                        ),
                        child: Text(
                          _periodLabel(period, l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDim,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
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
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 34),
          _buildMetricValue(val, fontSize: 21),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildMetricValue(String value, {required double fontSize}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.montserrat(
                color: AppColors.textMain,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: AppColors.textMain,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedBarChart(DashboardData data, AppLocalizations l10n) {
    final points = data.monthlyPoints;
    final maxY = data.chartMaxY;
    final interval = maxY <= 100 ? 20.0 : (maxY / 5).ceilToDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        return Container(
          height: isCompact ? 320 : 350,
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 20,
            18,
            isCompact ? 14 : 20,
            18,
          ),
          decoration: _surfaceDecoration(
            color: AppColors.surface,
            borderAlpha: 0.52,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _buildLegend(l10n.dashboardRevenue, AppColors.accent),
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
                          reservedSize: 28,
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
                          reservedSize: isCompact ? 36 : 42,
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
                        color: AppColors.borderLowContrast.withValues(
                          alpha: 0.24,
                        ),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(points.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barsSpace: isCompact ? 3 : 4,
                        barRods: [
                          BarChartRodData(
                            toY: points[index].revenue,
                            color: AppColors.accent,
                            width: isCompact ? 8 : 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: points[index].expenses,
                            color: AppColors.error,
                            width: isCompact ? 8 : 10,
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
      },
    );
  }

  Widget _buildProductSwitcherCard(DashboardData data, AppLocalizations l10n) {
    final title = selectedProductTab == 'BEST'
        ? l10n.dashboardBestSellingProducts
        : l10n.dashboardLeastSellingProducts;
    final products = selectedProductTab == 'BEST'
        ? data.bestProducts
        : data.leastProducts;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    height: 1.25,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: ['BEST', 'LEAST'].map((mode) {
                  final isSelected = selectedProductTab == mode;
                  return Material(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      onTap: () => setState(() => selectedProductTab = mode),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.borderLowContrast.withValues(
                                    alpha: 0.38,
                                  ),
                          ),
                        ),
                        child: Text(
                          _productTabLabel(mode, l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDim,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(
        color: AppColors.surfaceContainer,
        radius: 10,
        borderAlpha: 0.34,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.dashboardInvoiceLineItem,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currency(product.revenue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dashboardUnits(product.units),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(DashboardData data, AppLocalizations l10n) {
    final customers = data.topCustomers.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTopCustomersByValue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          if (customers.isEmpty)
            _buildEmptyInline(l10n.dashboardNoCustomers)
          else
            ...customers.map((customer) => _buildCustomerRow(customer, l10n)),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(DashboardCustomer customer, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dashboardInvoicesCount(customer.invoiceCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              _currency(customer.spent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildStateMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(18),
          decoration: _surfaceDecoration(color: AppColors.surface),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error.withValues(alpha: 0.9),
                size: 22,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.start,
                  style: const TextStyle(color: AppColors.textDim, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 44),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: const [
                    _LoadingBlock(width: 288, height: 168),
                    _LoadingBlock(width: 288, height: 168),
                    _LoadingBlock(width: 288, height: 168),
                    _LoadingBlock(width: 288, height: 168),
                  ],
                ),
                const SizedBox(height: 28),
                const _LoadingBlock(height: 350),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 760) {
                      return const Column(
                        children: [
                          _LoadingBlock(height: 260),
                          SizedBox(height: 24),
                          _LoadingBlock(height: 260),
                        ],
                      );
                    }

                    return const Row(
                      children: [
                        Expanded(child: _LoadingBlock(height: 260)),
                        SizedBox(width: 24),
                        Expanded(child: _LoadingBlock(height: 260)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyInline(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: _surfaceDecoration(
        color: AppColors.surfaceContainer,
        radius: 10,
        borderAlpha: 0.35,
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 18,
            color: AppColors.textDim.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textDim, height: 1.35),
            ),
          ),
        ],
      ),
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

  BoxDecoration _surfaceDecoration({
    Color color = AppColors.surfaceContainer,
    double radius = 14,
    double borderAlpha = 0.72,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.borderLowContrast.withValues(alpha: borderAlpha),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double? width;
  final double height;

  const _LoadingBlock({this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.36),
        ),
      ),
    );
  }
}
