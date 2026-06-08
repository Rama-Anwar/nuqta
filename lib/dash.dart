import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice_ai/nav.dart';
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
  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  String selectedRevenuePeriod = 'MONTH';
  String selectedSalesPeriod = 'MONTH';
  String selectedProductTab = 'BEST';

  final List<Map<String, dynamic>> bestProducts = [
    {
      'name': 'Enterprise License v4',
      'sub': 'SOFTWARE',
      'val': '€ 82.400',
      'meta': '142 units',
    },
    {
      'name': 'Consultancy Block (50h)',
      'sub': 'SERVICE',
      'val': '€ 45.000',
      'meta': '30 units',
    },
  ];

  final List<Map<String, dynamic>> leastProducts = [
    {
      'name': 'Legacy Connector API',
      'sub': 'STAGNANT 90D',
      'val': '€ 1.200',
      'meta': '2 units',
    },
    {
      'name': 'Beta Support Add-on',
      'sub': 'STAGNANT 120D',
      'val': '€ 450',
      'meta': '0 units',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF1A1D20),
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          "Dashboard",
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _buildInteractiveKPI(
            title: 'TOTAL REVENUE',
            value: '€ 1.245.000,00',
            growth: '+12.4%',
            isPositive: true,
            selectedPeriod: selectedRevenuePeriod,
            onPeriodChanged: (p) => setState(() => selectedRevenuePeriod = p),
          ),
          SizedBox(height: 16),
          _buildInteractiveKPI(
            title: 'TOTAL SALES',
            value: '€ 892.450,25',
            growth: '+8.2%',
            isPositive: true,
            selectedPeriod: selectedSalesPeriod,
            onPeriodChanged: (p) => setState(() => selectedSalesPeriod = p),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: _buildSimpleStatCard('AVG INVOICE', '€ 1.240', null),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: _buildSimpleStatCard('Customers', '1,482', null),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildSectionHeader(
            'Revenue vs Expenses',
            'Monthly performance tracking',
          ),
          SizedBox(height: 12),
          _buildGroupedBarChart(),
          SizedBox(height: 24),
          _buildProductSwitcherCard(),
          SizedBox(height: 24),
          _buildCustomerList(),
        ],
      ),
    );
  }

  Widget _buildInteractiveKPI({
    required String title,
    required String value,
    required String growth,
    required bool isPositive,
    required String selectedPeriod,
    required Function(String) onPeriodChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withOpacity(0.35),
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
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                  SizedBox(width: 4),
                  Text(
                    growth,
                    style: TextStyle(
                      color: isPositive ? AppColors.success : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: AppColors.textMain,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: ['TODAY', 'WEEK', 'MONTH', 'YEAR'].map((period) {
              bool isSelected = selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPeriodChanged(period),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        period,
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            val,
            style: GoogleFonts.montserrat(
              color: AppColors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
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
        Text(sub, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
      ],
    );
  }

  Widget _buildGroupedBarChart() {
    final labels = ['JAN', 'MAR', 'MAY', 'JUL', 'SEP', 'NOV'];
    final revenueData = [60.0, 75.0, 65.0, 85.0, 70.0, 80.0];
    final expenseData = [45.0, 55.0, 50.0, 40.0, 52.0, 60.0];

    return Container(
      height: 340,
      padding: EdgeInsets.all(20),
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
                _buildLegend('Revenue', AppColors.accent),
                SizedBox(width: 14),
                _buildLegend('Expenses', AppColors.error),
              ],
            ),
          ),
          SizedBox(height: 18),
          Expanded(
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt().clamp(0, labels.length - 1)],
                            style: TextStyle(
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
                      interval: 20,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderLowContrast.withOpacity(0.24),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(labels.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: revenueData[index],
                        color: AppColors.accent,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expenseData[index],
                        color: AppColors.error,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSwitcherCard() {
    final title = selectedProductTab == 'BEST'
        ? 'BEST-SELLING PRODUCTS'
        : 'LEAST SELLING PRODUCTS';
    final products = selectedProductTab == 'BEST'
        ? bestProducts
        : leastProducts;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withOpacity(0.35),
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
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: 2),
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
                        duration: Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
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
                          mode,
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
          SizedBox(height: 16),
          ...products.map(
            (p) => Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                          p['name'],
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          p['sub'],
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p['val'],
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        p['meta'],
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLowContrast.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP CUSTOMERS BY VALUE',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...[
                {'name': 'Aria Corp Ltd', 'id': '#AC-2941', 'val': '€ 124.500'},
                {
                  'name': 'Vortex Industries',
                  'id': '#VX-8832',
                  'val': '€ 98.200',
                },
                {'name': 'Nexus Partners', 'id': '#NP-1104', 'val': '€ 64.900'},
              ]
              .map(
                (c) => Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderLowContrast.withOpacity(0.35),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['name']!,
                            style: TextStyle(
                              color: AppColors.textMain,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            c['id']!,
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        c['val']!,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildLegend(String l, Color c) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          l,
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
