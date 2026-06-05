import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice_ai/helper/date_formatting_helpers.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';

import 'data/receipt_store.dart';
import 'models/invoice_model.dart';
import 'nav.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  // final List<InvoiceModel> _invoices = [];
  String? selectedYear;
  String? selectedMonth;
  bool isAllSelected = true;
  DateTime? _selectedDate;

  // ── Delete helpers ──────────────────────────────────────────────────────

  /// Shows a confirmation dialog; returns true only if the user taps Delete.
  Future<bool?> _confirmDelete(InvoiceModel invoice, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteInvoiceTitle,
          style: GoogleFonts.montserrat(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.deleteInvoiceMessage(invoice.customerName),
          style: GoogleFonts.inter(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: GoogleFonts.inter(
                color: AppColors.errorMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps an invoice card with swipe-to-delete (end-to-start).
  Widget _buildDismissibleCard(InvoiceModel invoice, AppLocalizations l10n) {
    return Dismissible(
      key: Key(invoice.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(invoice, l10n),
      onDismissed: (_) => ReceiptStore.instance.deleteReceipt(invoice.id),
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          color: AppColors.errorMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: _buildInvoiceCard(invoice, l10n),
    );
  }

  Future<void> _toggleStatus(InvoiceModel invoice) async {
    final receipt = (await ReceiptStore.instance.receiptsStream().first)
        .firstWhere((r) => r.id == invoice.id);
    final newStatus = invoice.status == InvoiceStatus.paid
        ? InvoiceStatus.outstanding
        : InvoiceStatus.paid;

    await ReceiptStore.instance.updateReceipt(
      ReceiptRecord(
        id: receipt.id,
        userUid: receipt.userUid,
        customerName: receipt.customerName,
        invoiceId: receipt.invoiceId,
        date: receipt.date,
        createdAt: receipt.createdAt,
        items: receipt.items,
        status: newStatus,
      ),
    );
  }

  Widget _buildFilterSectionWithInvoices(
    List<InvoiceModel> invoices,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLowContrast),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 150,
            child: _buildDropdown(
              l10n.year,
              selectedYear,
              _availableYears(invoices),
              l10n,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildDropdown(
              l10n.month,
              selectedMonth,
              _availableMonths(l10n),
              l10n,
            ),
          ),
          _buildAllToggle(l10n),
        ],
      ),
    );
  }

  List<InvoiceModel> _mapInvoices(List<ReceiptRecord> receipts) {
    return receipts
        .map(
          (r) => InvoiceModel(
            id: r.id,
            userUid: r.userUid,
            customerName: r.customerName,
            date: r.date,
            totalAmount: r.total,
            status: r.status,
            items: r.items
                .map(
                  (it) => InvoiceLine(
                    name: it.item,
                    quantity: it.quantity,
                    unitPrice: it.unitPrice,
                    costPrice: it.costPrice,
                  ),
                )
                .toList(),
            createdAt: r.createdAt,
            invoiceId: r.invoiceId,
          ),
        )
        .toList();
  }

  List<InvoiceModel> _visibleInvoices(
    List<InvoiceModel> invoices,
    AppLocalizations l10n,
  ) {
    if (isAllSelected) return invoices;

    Iterable<InvoiceModel> filtered = invoices;

    if (selectedYear != null) {
      filtered = filtered.where((invoice) {
        return invoice.date.year.toString() == selectedYear;
      });
    }

    if (selectedMonth != null) {
      filtered = filtered.where((invoice) {
        return _monthLabel(invoice.date.month, l10n) == selectedMonth;
      });
    }

    if (_selectedDate != null) {
      filtered = filtered.where((invoice) {
        return invoice.date.year == _selectedDate!.year &&
            invoice.date.month == _selectedDate!.month &&
            invoice.date.day == _selectedDate!.day;
      });
    }

    return filtered.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundScaffold,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScaffold,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          'Invoice AI',
          style: GoogleFonts.montserrat(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long, color: AppColors.accent),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppColors.borderLowContrast, height: 1),
        ),
      ),
      body: StreamBuilder<List<ReceiptRecord>>(
        stream: ReceiptStore.instance.receiptsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                l10n.somethingWrong,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            );
          }

          final receipts = snapshot.data ?? [];

          final invoices = _mapInvoices(receipts);

          final visibleInvoices = _visibleInvoices(invoices, l10n);

          final outstandingTotal = visibleInvoices
              .where((invoice) => invoice.status != InvoiceStatus.paid)
              .fold<double>(0, (sum, invoice) => sum + invoice.totalAmount);

          final collectedTotal = visibleInvoices
              .where((invoice) => invoice.status == InvoiceStatus.paid)
              .fold<double>(0, (sum, invoice) => sum + invoice.totalAmount);

          final earningsTotal = visibleInvoices
              .where((invoice) => invoice.status == InvoiceStatus.paid)
              .fold<double>(0, (sum, invoice) => sum + invoice.totalProfit);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: [
              _buildFilterSectionWithInvoices(invoices, l10n),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.invoiceLedger,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.pickDate,
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                              selectedYear = picked.year.toString();
                              selectedMonth = _monthLabel(picked.month, l10n);
                              isAllSelected = false;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(width: 4),

                      Text(
                        '${visibleInvoices.length} ${l10n.total}',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ...visibleInvoices.map(
                (invoice) => _buildDismissibleCard(invoice, l10n),
              ),

              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = constraints.maxWidth >= 435
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth >= 290
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: _buildStatTile(
                          l10n.outstanding,
                          _currency(outstandingTotal),
                          Icons.pending_actions,
                          AppColors.errorMuted,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _buildStatTile(
                          l10n.collected,
                          _currency(collectedTotal),
                          Icons.account_balance_wallet,
                          AppColors.successMuted,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _buildStatTile(
                          l10n.totalProfit,
                          _currency(earningsTotal),
                          Icons.trending_up,
                          AppColors.accent,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLowContrast),
          ),
          child: DropdownButtonFormField<String>(
            initialValue:
                (isAllSelected || value == null || !items.contains(value))
                ? null
                : value,
            hint: Text(
              l10n.select,
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
            decoration: const InputDecoration.collapsed(hintText: ''),
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textMuted,
            ),
            isExpanded: true,
            dropdownColor: AppColors.surfaceCard,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            items: items
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedDate = null;
                if (label == l10n.year) {
                  selectedYear = val;
                } else {
                  selectedMonth = val;
                }
                isAllSelected = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllToggle(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() {
        isAllSelected = true;
        selectedYear = null;
        selectedMonth = null;
        _selectedDate = null;
      }),
      child: Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isAllSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAllSelected
                ? AppColors.accent
                : AppColors.borderLowContrast,
          ),
        ),
        child: Text(
          l10n.all,
          style: GoogleFonts.inter(
            color: isAllSelected ? Colors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, AppLocalizations l10n) {
    final costAmount = _invoiceCost(invoice);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceId ?? invoice.id,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(context, invoice.date),
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currency(invoice.totalAmount),
                    style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.costLabel} ${_currency(costAmount)}',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _toggleStatus(invoice),
                    child: _buildStatusPill(invoice.status, l10n),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  invoice.customerName,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => _openDetails(invoice),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(InvoiceStatus status, AppLocalizations l10n) {
    late final Color color;
    late final String label;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppColors.successMuted;
        label = l10n.paid;
        break;

      case InvoiceStatus.outstanding:
        color = AppColors.accent;
        label = l10n.outstanding;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLowContrast),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              Icon(icon, color: accentColor.withValues(alpha: 0.35), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(top: BorderSide(color: AppColors.borderLowContrast)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.grid_view_rounded,
              l10n.dashboard,
              AppRoutes.dash,
              false,
            ),
            _buildNavItem(
              Icons.receipt_long,
              l10n.receipts,
              AppRoutes.receipts,
              false,
            ),
            _buildNavItem(
              Icons.description,
              l10n.invoices,
              AppRoutes.invoices,
              true,
            ),
            _buildNavItem(Icons.person, l10n.profile, AppRoutes.profile, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    String route,
    bool isActive,
  ) {
    final color = isActive ? AppColors.accent : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () {
          // If already on invoices and user taps invoices, do nothing
          if (route == AppRoutes.invoices) return;
          Navigator.of(context).pushReplacementNamed(route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _availableYears(List<InvoiceModel> invoices) {
    final currentYear = DateTime.now().year;
    final startYear = 2020;

    return List.generate(
      currentYear - startYear + 1,
      (i) => (startYear + i).toString(),
    ).reversed.toList();
  }

  List<String> _availableMonths(AppLocalizations l10n) => [
    l10n.jan,
    l10n.feb,
    l10n.mar,
    l10n.apr,
    l10n.may,
    l10n.jun,
    l10n.jul,
    l10n.aug,
    l10n.sep,
    l10n.oct,
    l10n.nov,
    l10n.dec,
  ];

  String _monthLabel(int month, AppLocalizations l10n) {
    final labels = [
      l10n.jan,
      l10n.feb,
      l10n.mar,
      l10n.apr,
      l10n.may,
      l10n.jun,
      l10n.jul,
      l10n.aug,
      l10n.sep,
      l10n.oct,
      l10n.nov,
      l10n.dec,
    ];
    return labels[month - 1];
  }

  String _currency(double value) => '\$${value.toStringAsFixed(2)}';

  double _invoiceCost(InvoiceModel invoice) => invoice.items.fold<double>(
    0,
    (sum, item) => sum + (item.costPrice * item.quantity),
  );

  void _openDetails(InvoiceModel invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _InvoiceDetailPage(invoice: invoice)),
    );
  }
}

class _InvoiceDetailPage extends StatefulWidget {
  final InvoiceModel invoice;

  const _InvoiceDetailPage({required this.invoice});

  @override
  State<_InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<_InvoiceDetailPage> {
  late InvoiceModel _invoice;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  bool get _isEditable {
    final now = DateTime.now();
    return _invoice.date.year == now.year &&
        _invoice.date.month == now.month &&
        _invoice.date.day == now.day;
  }

  double get _invoiceCost => _invoice.items.fold<double>(
    0,
    (sum, item) => sum + (item.costPrice * item.quantity),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundScaffold,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScaffold,
        elevation: 0,
        title: Text(
          _invoice.invoiceId ?? _invoice.id,
          style: GoogleFonts.montserrat(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_isEditable)
            IconButton(icon: const Icon(Icons.edit), onPressed: _openEditor),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: AppColors.errorMuted),
            tooltip: l10n.deleteInvoiceTitle,
            onPressed: () async {
              final navigator = Navigator.of(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    l10n.deleteInvoiceTitle,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    l10n.deleteInvoiceMessage(_invoice.customerName),
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        l10n.delete,
                        style: GoogleFonts.inter(
                          color: AppColors.errorMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ReceiptStore.instance.deleteReceipt(_invoice.id);
                if (!mounted) return;
                navigator.pop();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              _invoice.customerName,
              style: GoogleFonts.montserrat(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(_invoice.date),
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLowContrast),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.lineItems,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._invoice.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity} x',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${item.unitPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.costLabel} \$${item.costPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0x1AFFFFFF)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        'Cost',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '\$${_invoiceCost.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.totalProfitLabel,
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '\$${_invoice.totalProfit.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.total,
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '\$${_invoice.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final edited = await showModalBottomSheet<List<InvoiceLine>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final controllers = _invoice.items
            .map(
              (item) => {
                'qty': TextEditingController(text: item.quantity.toString()),
                'price': TextEditingController(
                  text: item.unitPrice.toStringAsFixed(2),
                ),
                'cost': TextEditingController(
                  text: item.costPrice.toStringAsFixed(2),
                ),
              },
            )
            .toList();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.editLineItems,
                      style: GoogleFonts.montserrat(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_invoice.items.length, (index) {
                      final item = _invoice.items[index];
                      final qtyController = controllers[index]['qty']!;
                      final priceController = controllers[index]['price']!;
                      final costController = controllers[index]['cost']!;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: TextField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: l10n.qty,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 86,
                              child: TextField(
                                controller: priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: l10n.price,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 86,
                              child: TextField(
                                controller: costController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: l10n.cost,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final updated = <InvoiceLine>[];
                            for (var i = 0; i < _invoice.items.length; i++) {
                              final current = _invoice.items[i];
                              final qty =
                                  int.tryParse(controllers[i]['qty']!.text) ??
                                  current.quantity;
                              final price =
                                  double.tryParse(
                                    controllers[i]['price']!.text,
                                  ) ??
                                  current.unitPrice;
                              final cost =
                                  double.tryParse(
                                    controllers[i]['cost']!.text,
                                  ) ??
                                  current.costPrice;
                              updated.add(
                                InvoiceLine(
                                  name: current.name,
                                  quantity: qty,
                                  unitPrice: price,
                                  costPrice: cost,
                                ),
                              );
                            }
                            Navigator.of(ctx).pop(updated);
                          },
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (edited == null) return;

    final updatedReceipt = ReceiptRecord(
      id: _invoice.id,
      customerName: _invoice.customerName,
      userUid: _invoice.userUid,
      invoiceId: _invoice.invoiceId,
      date: _invoice.date,
      status: _invoice.status,
      createdAt: _invoice.createdAt,
      items: edited
          .map(
            (line) => ReceiptLineItem(
              item: line.name,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              costPrice: line.costPrice,
            ),
          )
          .toList(),
    );

    await ReceiptStore.instance.updateReceipt(updatedReceipt);
    if (!mounted) return;
    setState(() {
      _invoice = InvoiceModel(
        id: updatedReceipt.id,
        userUid: updatedReceipt.userUid,
        customerName: updatedReceipt.customerName,
        date: updatedReceipt.date,
        totalAmount: updatedReceipt.total,
        status: _invoice.status,
        items: updatedReceipt.items
            .map(
              (line) => InvoiceLine(
                name: line.item,
                quantity: line.quantity,
                unitPrice: line.unitPrice,
                costPrice: line.costPrice,
              ),
            )
            .toList(),
        createdAt: updatedReceipt.createdAt,
        invoiceId: updatedReceipt.invoiceId,
      );
    });
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class AppColors {
  static const Color backgroundScaffold = Color(0xFF1A1D20);
  static const Color surfaceCard = Color(0xFF2B3035);
  static const Color surfaceContainer = Color(0xFF1B2023);
  static const Color surfaceVariant = Color(0xFF313539);
  static const Color accent = Color(0xFFEE671C);
  static const Color textPrimary = Color(0xFFDEE2E6);
  static const Color textMuted = Color(0xFFBDC1C6);
  static const Color borderLowContrast = Color(0xFF3E444A);
  static const Color successMuted = Color(0xFF81B29A);
  static const Color errorMuted = Color(0xFFE07A5F);
}
