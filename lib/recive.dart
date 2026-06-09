import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:invoice_ai/helper/get_current_user_profile.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';

import 'data/receipt_store.dart';
import 'nav.dart';
import 'services/n8n_webhook_service.dart';
import 'services/pending_invoices_service.dart';
import 'widgets/pending_invoices_badge.dart';

class ReceivePageController extends ChangeNotifier {
  PendingInvoice? _pendingInvoice;

  void loadPendingInvoice(PendingInvoice invoice) {
    _pendingInvoice = invoice;
    notifyListeners();
  }

  PendingInvoice? takePendingInvoice() {
    final invoice = _pendingInvoice;
    _pendingInvoice = null;
    return invoice;
  }
}

class ReceivePage extends StatefulWidget {
  final ReceivePageController? controller;

  const ReceivePage({super.key, this.controller});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final _customerController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _dateController = TextEditingController();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _costPriceController = TextEditingController();

  final List<_ReceiptLine> _items = <_ReceiptLine>[];

  /// The Firestore docId of the pending invoice currently loaded in the form.
  /// Null when the user is creating a brand-new manual invoice.
  String? _activePendingDocId;

  /// True while [_submit] is running – disables the submit button and shows
  /// a spinner to prevent double-submissions.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerLoad);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleControllerLoad();
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerLoad);
    _customerController.dispose();
    _invoiceController.dispose();
    _dateController.dispose();
    _itemController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  void _handleControllerLoad() {
    final invoice = widget.controller?.takePendingInvoice();
    if (invoice == null || !mounted) return;
    _loadFromPendingInvoice(invoice);
  }

  double get _subtotal =>
      _items.fold<double>(0, (sum, line) => sum + line.total);
  double get _tax => 0.0;
  double get _total => _subtotal;

  void _addItem(AppLocalizations l10n) {
    final name = _itemController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final price = double.tryParse(_unitPriceController.text.trim()) ?? 0;
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;

    if (name.isEmpty || quantity <= 0 || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addValidItem)));
      return;
    }

    setState(() {
      _items.add(
        _ReceiptLine(
          item: name,
          quantity: quantity,
          unitPrice: price,
          costPrice: costPrice,
        ),
      );
      _itemController.clear();
      _quantityController.text = '1';
      _unitPriceController.clear();
      _costPriceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateItemName(int index, String value) {
    setState(() {
      _items[index].item = value;
    });
  }

  void _updateItemQuantity(int index, String value) {
    setState(() {
      _items[index].quantity = int.tryParse(value) ?? 0;
    });
  }

  void _updateItemPrice(int index, String value) {
    setState(() {
      _items[index].unitPrice = double.tryParse(value) ?? 0.0;
    });
  }

  void _updateItemCost(int index, String value) {
    setState(() {
      _items[index].costPrice = double.tryParse(value) ?? 0.0;
    });
  }

  /// Populates the form with data from a [PendingInvoice] selected in the
  /// waiting-list sheet. The Firestore status is already flipped to
  /// "in_progress" by the tile widget before this is called.
  void _loadFromPendingInvoice(PendingInvoice inv) {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) return;

    setState(() {
      // ── Remember which Firestore doc is loaded so _submit() can update it ──
      _activePendingDocId = inv.docId;

      _customerController.text = inv.customerName;
      _invoiceController.text = inv.invoiceId;
      if (inv.date != null) {
        _dateController.text = _formatReceiptDate(inv.date!);
      }
      _items
        ..clear()
        ..addAll(
          inv.items.map(
            (i) => _ReceiptLine(
              item: i.item,
              quantity: i.qty,
              unitPrice: i.price,
              costPrice: i.cost,
            ),
          ),
        );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.loadedFromWaitingList(inv.customerName)),
        backgroundColor: AppPalette.primaryContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  DateTime _parseReceiptDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return DateTime.now();

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final match = RegExp(
      r'^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})$',
    ).firstMatch(raw);
    if (match == null) return DateTime.now();

    final first = int.tryParse(match.group(1)!);
    final second = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (first == null || second == null || year == null) {
      return DateTime.now();
    }

    final day = first;
    final month = second;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return DateTime.now();
    }
    return date;
  }

  String _formatReceiptDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_isSubmitting) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOneItem)));
      return;
    }

    setState(() => _isSubmitting = true);

    final docId = _activePendingDocId;
    final customerName = _customerController.text.trim().isEmpty
        ? l10n.unnamedCustomer
        : _customerController.text.trim();
    final invoiceId = _invoiceController.text.trim();
    final editedItems = _items
        .map(
          (line) => <String, dynamic>{
            'item': line.item,
            'qty': line.quantity,
            'price': line.unitPrice,
            'cost': line.costPrice,
          },
        )
        .toList();
    var webhookFailed = false;

    try {
      if (docId != null) {
        // ── Pending architecture ──────────────────────────────────────────
        final receipt = ReceiptRecord(
          id: 'RCPT-${DateTime.now().millisecondsSinceEpoch}',
          userUid: FirebaseAuth.instance.currentUser!.uid,
          customerName: customerName,
          invoiceId: invoiceId.isEmpty ? null : invoiceId,
          date: _parseReceiptDate(_dateController.text),
          createdAt: DateTime.now(),
          status: InvoiceStatus.outstanding,
          items: _items
              .map(
                (line) => ReceiptLineItem(
                  item: line.item,
                  quantity: line.quantity,
                  unitPrice: line.unitPrice,
                  costPrice: line.costPrice,
                ),
              )
              .toList(),
        );

        await ReceiptStore.instance.addReceipt(receipt);

        try {
          await PendingInvoicesService.instance.approveInvoice(
            docId: docId,
            customerName: customerName,
            invoiceId: invoiceId,
            items: editedItems,
          );
        } catch (approvalError) {
          try {
            await ReceiptStore.instance.deleteReceipt(receipt.id);
          } catch (rollbackError) {
            debugPrint(
              'Receipt rollback failed after approveInvoice error: '
              '$rollbackError',
            );
          }
          rethrow;
        }

        try {
          final organizationId = await PendingInvoicesService.instance
              .currentOrganizationId();
          await N8nWebhookService.instance.pingDocId(
            organizationId: organizationId,
            docId: docId,
            invoiceId: invoiceId,
            customerName: customerName,
            items: editedItems,
          );
        } catch (webhookError) {
          webhookFailed = true;
          debugPrint('n8n pingDocId error (non-fatal): $webhookError');
        }
      } else {
        // ── Manual invoice ────────────────────────────────────────────────
        final receipt = ReceiptRecord(
          id: 'RCPT-${DateTime.now().millisecondsSinceEpoch}',
          userUid: FirebaseAuth.instance.currentUser!.uid,
          customerName: customerName,
          invoiceId: invoiceId.isEmpty ? null : invoiceId,
          date: _parseReceiptDate(_dateController.text),
          createdAt: DateTime.now(),
          status: InvoiceStatus.outstanding,
          items: _items
              .map(
                (line) => ReceiptLineItem(
                  item: line.item,
                  quantity: line.quantity,
                  unitPrice: line.unitPrice,
                  costPrice: line.costPrice,
                ),
              )
              .toList(),
        );

        await ReceiptStore.instance.addReceipt(receipt);
      }

      if (!mounted) return;

      // ── Success: clear form state ──────────────────────────────────────
      setState(() {
        _activePendingDocId = null;
        _customerController.clear();
        _invoiceController.clear();
        _dateController.clear();
        _items.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                webhookFailed
                    ? l10n.invoiceApprovedNotificationFailed
                    : docId != null
                    ? l10n.invoiceApprovedProcessed
                    : l10n.receiptSavedDashboardUpdated,
              ),
            ],
          ),
          backgroundColor: webhookFailed
              ? AppPalette.errorMuted
              : AppPalette.primaryContainer,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      final profile = await getCurrentUserProfile();

      if (!mounted) return;
      final targetRoute = profile?.isOwner == true
          ? AppRoutes.dash
          : AppRoutes.receipts;
      final shell = AppTabScope.maybeOf(context);
      if (shell?.switchToRoute != null) {
        shell!.switchToRoute!(targetRoute);
      } else {
        Navigator.of(context).pushReplacementNamed(targetRoute);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            docId != null
                ? l10n.failedSaveApproveInvoice(error)
                : l10n.failedSaveReceipt(error),
          ),
          backgroundColor: AppPalette.errorMuted,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pendingInvoiceIsLoaded = _activePendingDocId != null;
    final submitLabel = pendingInvoiceIsLoaded
        ? l10n.approveInvoice
        : 'SAVE RECEIPT';

    return Scaffold(
      backgroundColor: AppPalette.backgroundScaffold,
      body: SafeArea(
        child: Column(
          children: [
            _TopAppBar(
              onBack: () => Navigator.of(context).maybePop(),
              onPendingTap: _loadFromPendingInvoice,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 1024;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      isDesktop ? 48 : 220,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (pendingInvoiceIsLoaded) ...[
                              _PendingInvoiceBanner(
                                customerName: _customerController.text.trim(),
                                invoiceId: _invoiceController.text.trim(),
                              ),
                              const SizedBox(height: 16),
                            ],
                            isDesktop
                                ? _DesktopLayout(
                                    customerController: _customerController,
                                    costPriceController: _costPriceController,
                                    invoiceController: _invoiceController,
                                    dateController: _dateController,
                                    itemController: _itemController,
                                    quantityController: _quantityController,
                                    unitPriceController: _unitPriceController,
                                    items: _items,
                                    subtotal: _subtotal,
                                    tax: _tax,
                                    total: _total,
                                    onAddItem: () => _addItem(l10n),
                                    onRemoveItem: _removeItem,
                                    onNameChanged: _updateItemName,
                                    onQtyChanged: _updateItemQuantity,
                                    onPriceChanged: _updateItemPrice,
                                    onCostChanged: _updateItemCost,
                                    onSubmit: () => _submit(l10n),
                                    isSubmitting: _isSubmitting,
                                    submitLabel: submitLabel,
                                  )
                                : _MobileLayout(
                                    costPriceController: _costPriceController,
                                    customerController: _customerController,
                                    invoiceController: _invoiceController,
                                    dateController: _dateController,
                                    itemController: _itemController,
                                    quantityController: _quantityController,
                                    unitPriceController: _unitPriceController,
                                    items: _items,
                                    subtotal: _subtotal,
                                    tax: _tax,
                                    total: _total,
                                    onAddItem: () => _addItem(l10n),
                                    onRemoveItem: _removeItem,
                                    onNameChanged: _updateItemName,
                                    onQtyChanged: _updateItemQuantity,
                                    onPriceChanged: _updateItemPrice,
                                    onCostChanged: _updateItemCost,
                                    onSubmit: () => _submit(l10n),
                                    isSubmitting: _isSubmitting,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return const SizedBox.shrink();
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MobileActionBar(
                total: _total,
                onSubmit: () => _submit(l10n),
                isSubmitting: _isSubmitting,
                submitLabel: submitLabel,
              ),
              const AppBottomNavBar(activeIndex: 1),
            ],
          );
        },
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  final VoidCallback onBack;
  final void Function(PendingInvoice invoice) onPendingTap;

  const _TopAppBar({required this.onBack, required this.onPendingTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(bottom: BorderSide(color: AppPalette.borderLowContrast)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.newIntakeReceipt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PendingInvoicesBadgeButton(onInvoiceSelected: onPendingTap),
        ],
      ),
    );
  }
}

class _PendingInvoiceBanner extends StatelessWidget {
  final String customerName;
  final String invoiceId;

  const _PendingInvoiceBanner({
    required this.customerName,
    required this.invoiceId,
  });

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (customerName.isNotEmpty) customerName,
      if (invoiceId.isNotEmpty) invoiceId,
    ].join(' - ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.primaryContainer.withValues(alpha: 0.12),
        border: Border.all(
          color: AppPalette.primaryContainer.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppPalette.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: AppPalette.primaryContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loaded from Waiting List',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final TextEditingController customerController;
  final TextEditingController costPriceController;
  final TextEditingController invoiceController;
  final TextEditingController dateController;
  final TextEditingController itemController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final List<_ReceiptLine> items;
  final double subtotal;
  final double tax;
  final double total;
  final VoidCallback onAddItem;
  final void Function(int index) onRemoveItem;
  final void Function(int index, String value) onNameChanged;
  final void Function(int index, String value) onQtyChanged;
  final void Function(int index, String value) onPriceChanged;
  final void Function(int index, String value) onCostChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String submitLabel;

  const _DesktopLayout({
    required this.customerController,
    required this.costPriceController,
    required this.invoiceController,
    required this.dateController,
    required this.itemController,
    required this.quantityController,
    required this.unitPriceController,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onCostChanged,
    required this.onSubmit,
    required this.isSubmitting,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 380,
          child: Column(
            children: [
              _CardShell(
                title: l10n.orderInformation,
                child: Column(
                  children: [
                    _LabeledInput(
                      controller: customerController,
                      label: l10n.customerSupplierName,
                      hint: l10n.enterName,
                    ),
                    const SizedBox(height: 16),
                    _LabeledInput(
                      controller: invoiceController,
                      label: l10n.invoiceIdOptional,
                      hint: 'INV-0000',
                      mono: true,
                    ),
                    const SizedBox(height: 16),
                    _LabeledInput(
                      controller: dateController,
                      label: l10n.date,
                      hint: '01-05-2026',
                      mono: true,
                      isDate: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _CardShell(
                title: l10n.addItem,
                child: Column(
                  children: [
                    _LabeledInput(
                      controller: itemController,
                      label: l10n.itemName,
                      hint: l10n.scanOrTypeItem,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LabeledInput(
                            controller: quantityController,
                            label: l10n.quantity,
                            hint: '0',
                            mono: true,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledInput(
                            controller: unitPriceController,
                            label: l10n.price,
                            hint: '0.00',
                            mono: true,
                            isNumber: true,
                            prefix: '\$',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledInput(
                            controller: costPriceController,
                            label: l10n.costLabel,
                            hint: "0.00",
                            mono: true,
                            prefix: '\$',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onAddItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primaryContainer,
                          foregroundColor: AppPalette.textPrimary,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          l10n.addItem,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _ItemsPanelDesktop(
            items: items,
            subtotal: subtotal,
            tax: tax,
            total: total,
            onRemoveItem: onRemoveItem,
            onNameChanged: onNameChanged,
            onQtyChanged: onQtyChanged,
            onPriceChanged: onPriceChanged,
            onCostChanged: onCostChanged,
            onSubmit: onSubmit,
            isSubmitting: isSubmitting,
            submitLabel: submitLabel,
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final TextEditingController customerController;
  final TextEditingController invoiceController;
  final TextEditingController dateController;
  final TextEditingController itemController;
  final TextEditingController costPriceController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final List<_ReceiptLine> items;
  final double subtotal;
  final double tax;
  final double total;
  final VoidCallback onAddItem;
  final void Function(int index) onRemoveItem;
  final void Function(int index, String value) onNameChanged;
  final void Function(int index, String value) onQtyChanged;
  final void Function(int index, String value) onPriceChanged;
  final void Function(int index, String value) onCostChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const _MobileLayout({
    required this.costPriceController,
    required this.customerController,
    required this.invoiceController,
    required this.dateController,
    required this.itemController,
    required this.quantityController,
    required this.unitPriceController,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onCostChanged,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardShell(
          title: l10n.orderInformation,
          child: Column(
            children: [
              _LabeledInput(
                controller: customerController,
                label: l10n.customerSupplierName,
                hint: l10n.enterName,
              ),
              const SizedBox(height: 16),
              _LabeledInput(
                controller: invoiceController,
                label: l10n.invoiceIdOptional,
                hint: 'INV-0000',
                mono: true,
              ),
              const SizedBox(height: 16),
              _LabeledInput(
                controller: dateController,
                label: l10n.date,
                hint: '01-05-2026',
                mono: true,
                isDate: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _CardShell(
          title: l10n.addItem,
          child: Column(
            children: [
              _LabeledInput(
                controller: itemController,
                label: l10n.itemName,
                hint: l10n.scanOrTypeItem,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _LabeledInput(
                      controller: quantityController,
                      label: l10n.quantity,
                      hint: '0',
                      mono: true,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LabeledInput(
                      controller: unitPriceController,
                      label: l10n.price,
                      hint: '0.00',
                      mono: true,
                      isNumber: true,
                      prefix: '\$ ',
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: _LabeledInput(
                      controller: costPriceController,
                      label: l10n.cost,
                      hint: '0.00',
                      mono: true,
                      isNumber: true,
                      prefix: '\$',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAddItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primaryContainer,
                    foregroundColor: AppPalette.textPrimary,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    l10n.addItem,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ItemsPanelMobile(
          items: items,
          subtotal: subtotal,
          tax: tax,
          total: total,
          totalCost: items.fold<double>(
            0,
            (sum, item) => sum + (item.costPrice * item.quantity),
          ),
          onRemoveItem: onRemoveItem,
          onNameChanged: onNameChanged,
          onQtyChanged: onQtyChanged,
          onPriceChanged: onPriceChanged,
          onCostChanged: onCostChanged,
        ),
      ],
    );
  }
}

class _ItemsPanelDesktop extends StatelessWidget {
  final List<_ReceiptLine> items;
  final double subtotal;
  final double tax;
  final double total;
  final void Function(int index) onRemoveItem;
  final void Function(int index, String value) onNameChanged;
  final void Function(int index, String value) onQtyChanged;
  final void Function(int index, String value) onPriceChanged;
  final void Function(int index, String value) onCostChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String submitLabel;

  const _ItemsPanelDesktop({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onRemoveItem,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onCostChanged,
    required this.onSubmit,
    required this.isSubmitting,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CardShell(
      title: l10n.lineItems,
      trailing: Text(
        '${items.length} ${l10n.items}',
        style: const TextStyle(
          color: AppPalette.textMuted,
          fontFamily: 'monospace',
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppPalette.backgroundScaffold,
              border: Border(
                bottom: BorderSide(color: AppPalette.borderLowContrast),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('#', style: _HeadCellStyle.style),
                ),
                Expanded(
                  flex: 7,
                  child: Text(l10n.description, style: _HeadCellStyle.style),
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    l10n.qty,
                    textAlign: TextAlign.center,
                    style: _HeadCellStyle.style,
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    l10n.price,
                    textAlign: TextAlign.center,
                    style: _HeadCellStyle.style,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    l10n.total,
                    textAlign: TextAlign.right,
                    style: _HeadCellStyle.style,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const _EmptyState()
          else
            ...List.generate(items.length, (index) {
              final line = items[index];
              return _ItemRow(
                key: ValueKey(line),
                index: index + 1,
                line: line,
                onNameChanged: (value) => onNameChanged(index, value),
                onQtyChanged: (value) => onQtyChanged(index, value),
                onPriceChanged: (value) => onPriceChanged(index, value),
                onCostChanged: (value) => onCostChanged(index, value),
                onRemove: () => onRemoveItem(index),
              );
            }),
          _DesktopTotalsSummary(
            total: total,
            subtotal: subtotal,
            tax: tax,
            totalCost: items.fold<double>(
              0,
              (sum, item) => sum + (item.costPrice * item.quantity),
            ),
            onSubmit: onSubmit,
            isSubmitting: isSubmitting,
            submitLabel: submitLabel,
          ),
        ],
      ),
    );
  }
}

class _ItemsPanelMobile extends StatelessWidget {
  final List<_ReceiptLine> items;
  final double subtotal;
  final double tax;
  final double totalCost;
  final double total;
  final void Function(int index) onRemoveItem;
  final void Function(int index, String value) onNameChanged;
  final void Function(int index, String value) onQtyChanged;
  final void Function(int index, String value) onPriceChanged;
  final void Function(int index, String value) onCostChanged;

  const _ItemsPanelMobile({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.totalCost,
    required this.total,
    required this.onRemoveItem,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onCostChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CardShell(
      title: l10n.lineItems,
      trailing: Text(
        '${items.length} ${l10n.items}',
        style: const TextStyle(
          color: AppPalette.textMuted,
          fontFamily: 'monospace',
        ),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            const _EmptyState()
          else
            ...List.generate(items.length, (index) {
              final line = items[index];
              return _MobileItemCard(
                key: ValueKey(line),
                index: index + 1,
                line: line,
                onNameChanged: (value) => onNameChanged(index, value),
                onQtyChanged: (value) => onQtyChanged(index, value),
                onPriceChanged: (value) => onPriceChanged(index, value),
                onCostChanged: (value) => onCostChanged(index, value),
                onRemove: () => onRemoveItem(index),
              );
            }),
          _MobileCompactTotals(
            subtotal: subtotal,
            tax: tax,
            total: total,
            totalCost: totalCost,
          ),
        ],
      ),
    );
  }
}

class _DesktopTotalsSummary extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double total;
  final double totalCost;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String submitLabel;

  const _DesktopTotalsSummary({
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.totalCost,
    required this.onSubmit,
    required this.isSubmitting,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppPalette.backgroundScaffold,
        border: Border(top: BorderSide(color: AppPalette.borderLowContrast)),
      ),
      child: Column(
        children: [
          _SummaryRow(label: l10n.subtotal, value: _currency(subtotal, l10n)),
          const SizedBox(height: 8),
          _SummaryRow(label: l10n.tax, value: _currency(tax, l10n)),
          const SizedBox(height: 12),
          const Divider(color: AppPalette.borderLowContrast, height: 1),
          const SizedBox(height: 12),
          _SummaryRow(label: l10n.totalCost, value: _currency(totalCost, l10n)),
          const SizedBox(height: 8),
          _SummaryRow(
            label: l10n.total,
            value: _currency(total, l10n),
            bold: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.primaryContainer,
                foregroundColor: AppPalette.textPrimary,
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          submitLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCompactTotals extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double total;
  final double totalCost;

  const _MobileCompactTotals({
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _MobileActionBar extends StatelessWidget {
  final double total;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String submitLabel;

  const _MobileActionBar({
    required this.total,
    required this.onSubmit,
    required this.isSubmitting,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppPalette.surfaceCard,
        border: Border(top: BorderSide(color: AppPalette.borderLowContrast)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalAmount,
                  style: TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _currency(total, l10n),
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primaryContainer,
                  foregroundColor: AppPalette.textPrimary,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            submitLabel,

                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _CardShell({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        border: Border.all(color: AppPalette.borderLowContrast),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool mono;
  final bool isDate;
  final bool isNumber;
  final String? prefix;

  const _LabeledInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.mono = false,
    this.isDate = false,
    this.isNumber = false,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isDate
              ? TextInputType.datetime
              : isNumber
              ? TextInputType.number
              : TextInputType.text,
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontSize: mono ? 14 : 16,
            fontFamily: mono ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppPalette.surfaceContainerHighest,
            ),
            filled: true,
            fillColor: AppPalette.backgroundScaffold,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppPalette.borderLowContrast,
                width: 2,
              ),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppPalette.borderLowContrast,
                width: 2,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppPalette.primaryContainer,
                width: 2,
              ),
            ),
            prefixText: prefix,
            prefixStyle: const TextStyle(color: AppPalette.textMuted),
          ),
        ),
      ],
    );
  }
}

class _HeadCellStyle {
  static const TextStyle style = TextStyle(
    color: AppPalette.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );
}

class _ItemRow extends StatelessWidget {
  final int index;
  final _ReceiptLine line;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onQtyChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onCostChanged;
  final VoidCallback onRemove;

  const _ItemRow({
    required super.key,
    required this.index,
    required this.line,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onCostChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.borderLowContrast)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppPalette.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: TextFormField(
              initialValue: line.item,
              onChanged: onNameChanged,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: AppPalette.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                isCollapsed: true,
                hintText: l10n.itemName,
                hintStyle: TextStyle(color: AppPalette.textMuted),
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.qty,
                  style: TextStyle(color: AppPalette.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: line.quantity.toString(),
                  onChanged: onQtyChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: '0',
                    hintStyle: TextStyle(color: AppPalette.textMuted),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.price,
                        style: TextStyle(
                          color: AppPalette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: line.unitPrice.toStringAsFixed(2),
                          onChanged: onPriceChanged,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppPalette.textPrimary,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppPalette.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.costLabel,
                        style: TextStyle(
                          color: AppPalette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: line.costPrice.toStringAsFixed(2),
                          onChanged: onCostChanged,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppPalette.textPrimary,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppPalette.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.total,
                            style: TextStyle(
                              color: AppPalette.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currency(line.total, l10n),
                            style: const TextStyle(
                              color: AppPalette.textPrimary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Profit',
                            style: TextStyle(
                              color: AppPalette.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currency(line.profit, l10n),
                            style: const TextStyle(
                              color: AppPalette.textPrimary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppPalette.errorMuted,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileItemCard extends StatelessWidget {
  final int index;
  final _ReceiptLine line;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onQtyChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onCostChanged;
  final VoidCallback onRemove;

  const _MobileItemCard({
    required super.key,
    required this.index,
    required this.line,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onCostChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.backgroundScaffold,
        border: Border.all(color: AppPalette.borderLowContrast),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppPalette.surfaceCard,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: line.item,
                  onChanged: onNameChanged,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: l10n.itemName,
                    hintStyle: TextStyle(color: AppPalette.textMuted),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppPalette.errorMuted,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MobileEditableStatBlock(
                  label: l10n.qty,
                  value: line.quantity.toString(),
                  onChanged: onQtyChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.price,
                        style: TextStyle(
                          color: AppPalette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: line.unitPrice.toStringAsFixed(2),
                          onChanged: onPriceChanged,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppPalette.textPrimary,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppPalette.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.cost,
                        style: TextStyle(
                          color: AppPalette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: line.costPrice.toStringAsFixed(2),
                          onChanged: onCostChanged,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppPalette.textPrimary,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppPalette.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: _MobileStatBlock(
                        label: l10n.total,
                        value: _currency(line.total, l10n),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MobileStatBlock(
                      label: l10n.profit,
                      value: _currency(line.profit, l10n),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileEditableStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final TextAlign textAlign;

  const _MobileEditableStatBlock({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.keyboardType,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppPalette.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textAlign: textAlign,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            isCollapsed: true,
            hintStyle: TextStyle(color: AppPalette.textMuted),
          ),
        ),
      ],
    );
  }
}

class _MobileStatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _MobileStatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 44,
            color: AppPalette.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            l10n.noItemsAdded,
            style: TextStyle(color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppPalette.textPrimary : AppPalette.textMuted,
            fontSize: bold ? 24 : 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontSize: bold ? 24 : 14,
            fontFamily: 'monospace',
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ReceiptLine {
  String item;
  int quantity;
  double unitPrice;
  double costPrice;

  _ReceiptLine({
    required this.item,
    required this.quantity,
    required this.unitPrice,
    this.costPrice = 0.0,
  });

  double get total => quantity * unitPrice;
  double get profit => (unitPrice - costPrice) * quantity;
}

String _currency(double value, AppLocalizations l10n) =>
    '${l10n.jod} ${value.toStringAsFixed(2)}';

class AppPalette {
  static const Color backgroundScaffold = Color(0xFF1A1D20);
  static const Color surfaceCard = Color(0xFF2B3035);
  static const Color surface = Color(0xFF0F1417);
  static const Color borderLowContrast = Color(0xFF3E444A);
  static const Color textPrimary = Color(0xFFDEE2E6);
  static const Color textMuted = Color(0xFFBDC1C6);
  static const Color onSurfaceVariant = Color(0xFFE0C0B2);
  static const Color surfaceContainerHigh = Color(0xFF262B2E);
  static const Color surfaceContainerHighest = Color(0xFF313539);
  static const Color primaryContainer = Color(0xFFEE671C);
  static const Color errorMuted = Color(0xFFE07A5F);
}
