import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/get_current_user_profile.dart';
import '../services/pending_invoices_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PendingInvoicesBadgeButton
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in AppBar action (or anywhere you like) that:
///  • Shows a pulsing notification badge with the count of pending invoices.
///  • Opens a premium-styled bottom sheet listing those invoices.
///  • Calls [onInvoiceSelected] with the chosen [PendingInvoice] so the
///    parent screen can populate its state.
class PendingInvoicesBadgeButton extends StatefulWidget {
  /// Called when the user taps an invoice in the bottom sheet.
  final void Function(PendingInvoice invoice) onInvoiceSelected;

  const PendingInvoicesBadgeButton({
    super.key,
    required this.onInvoiceSelected,
  });

  @override
  State<PendingInvoicesBadgeButton> createState() =>
      _PendingInvoicesBadgeButtonState();
}

class _PendingInvoicesBadgeButtonState
    extends State<PendingInvoicesBadgeButton> {
  late final Future<bool> _canDeletePendingInvoices;

  @override
  void initState() {
    super.initState();
    _canDeletePendingInvoices = _loadCanDeletePendingInvoices();
  }

  Future<bool> _loadCanDeletePendingInvoices() async {
    final profile = await getCurrentUserProfile();
    return profile?.isOwner == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canDeletePendingInvoices,
      builder: (context, snapshot) {
        final canDeletePendingInvoices = snapshot.data == true;

        return StreamBuilder<List<PendingInvoice>>(
          stream: PendingInvoicesService.instance.pendingStream(),
          builder: (context, snapshot) {
            final invoices = snapshot.data ?? [];
            final count = invoices.length;
            final hasError = snapshot.hasError;

            return Tooltip(
              message: 'Pending invoices',
              child: Semantics(
                label: 'Pending invoices',
                button: true,
                child: GestureDetector(
                  onTap: hasError
                      ? () => _showLoadError(context)
                      : () => _openSheet(
                          context,
                          invoices,
                          canDeletePendingInvoices: canDeletePendingInvoices,
                        ),
                  child: _BadgeIcon(count: count, hasError: hasError),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLoadError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to load pending invoices. Check your organization access.',
        ),
      ),
    );
  }

  void _openSheet(
    BuildContext context,
    List<PendingInvoice> invoices, {
    required bool canDeletePendingInvoices,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (sheetContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(sheetContext).pop(),
        child: GestureDetector(
          onTap: () {},
          child: _PendingInvoicesSheet(
            invoices: invoices,
            canDeleteInvoices: canDeletePendingInvoices,
            onSelected: (inv) {
              Navigator.of(sheetContext).pop();
              widget.onInvoiceSelected(inv);
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BadgeIcon  – animated bell with a live count badge
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeIcon extends StatefulWidget {
  final int count;
  final bool hasError;

  const _BadgeIcon({required this.count, required this.hasError});

  @override
  State<_BadgeIcon> createState() => _BadgeIconState();
}

class _BadgeIconState extends State<_BadgeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = widget.count > 0;
    final color = widget.hasError
        ? Colors.redAccent
        : hasPending
        ? const Color(0xFFEE671C)
        : const Color(0xFFBDC1C6);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bell icon – pulses when there are pending items
          AnimatedBuilder(
            animation: _scale,
            builder: (_, child) => Transform.scale(
              scale: hasPending ? _scale.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.hasError
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : hasPending
                    ? const Color(0xFFEE671C).withValues(alpha: 0.15)
                    : const Color(0xFF2B3035),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.hasError
                      ? Colors.redAccent.withValues(alpha: 0.45)
                      : hasPending
                      ? const Color(0xFFEE671C).withValues(alpha: 0.45)
                      : const Color(0xFF3E444A),
                ),
              ),
              child: Icon(
                widget.hasError
                    ? Icons.error_outline_rounded
                    : hasPending
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: color,
                size: 22,
              ),
            ),
          ),

          // Badge
          if (hasPending)
            Positioned(
              top: -5,
              right: -5,
              child: AnimatedBuilder(
                animation: _scale,
                builder: (_, child) =>
                    Transform.scale(scale: _scale.value, child: child),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEE671C),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.count > 99 ? '99+' : '${widget.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PendingInvoicesSheet  – the premium bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PendingInvoicesSheet extends StatelessWidget {
  final List<PendingInvoice> invoices;
  final bool canDeleteInvoices;
  final void Function(PendingInvoice) onSelected;

  const _PendingInvoicesSheet({
    required this.invoices,
    required this.canDeleteInvoices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D20),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF3E444A)),
              left: BorderSide(color: Color(0xFF3E444A)),
              right: BorderSide(color: Color(0xFF3E444A)),
            ),
          ),
          child: Column(
            children: [
              // ── handle ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E444A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEE671C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inbox_rounded,
                        color: Color(0xFFEE671C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waiting List',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFFDEE2E6),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${invoices.length} invoice${invoices.length == 1 ? '' : 's'} pending review',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFBDC1C6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Live indicator dot
                    if (invoices.isNotEmpty) _LiveDot(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Divider(
                color: Color(0xFF3E444A),
                height: 1,
                indent: 20,
                endIndent: 20,
              ),

              const SizedBox(height: 8),

              // ── list ────────────────────────────────────────────────────
              Expanded(
                child: invoices.isEmpty
                    ? _EmptyWaitingList()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: invoices.length,
                        itemBuilder: (_, i) => _InvoiceTile(
                          invoice: invoices[i],
                          canDeleteInvoice: canDeleteInvoices,
                          onTap: () => onSelected(invoices[i]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InvoiceTile  – one row in the waiting list
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceTile extends StatefulWidget {
  final PendingInvoice invoice;
  final bool canDeleteInvoice;
  final VoidCallback onTap;

  const _InvoiceTile({
    required this.invoice,
    required this.canDeleteInvoice,
    required this.onTap,
  });

  @override
  State<_InvoiceTile> createState() => _InvoiceTileState();
}

class _InvoiceTileState extends State<_InvoiceTile> {
  bool _loading = false;
  bool _deleting = false;

  Future<void> _handleTap() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      // Mark as in_progress in Firestore immediately
      await PendingInvoicesService.instance.updateStatus(
        widget.invoice.docId,
        'in_progress',
      );
      if (mounted) widget.onTap();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open this invoice. Check your organization access.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_loading || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2B3035),
        title: const Text('Delete pending invoice?'),
        content: Text(
          'Delete "${widget.invoice.customerName}" from pending invoices? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await PendingInvoicesService.instance.deleteInvoice(widget.invoice.docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pending invoice deleted.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to delete this invoice. Check your organization access.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final itemCount = inv.items.length;

    return GestureDetector(
      onTap: _loading ? null : _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2B3035),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF3E444A).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            // Left accent stripe + avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEE671C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEE671C).withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFFEE671C),
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // Customer + invoice id
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.customerName,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFDEE2E6),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        inv.invoiceId.isNotEmpty ? inv.invoiceId : '—',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFEE671C),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E444A).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$itemCount item${itemCount == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFBDC1C6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Action / loader
            if (_loading || _deleting)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFEE671C),
                ),
              )
            else ...[
              if (widget.canDeleteInvoice) ...[
                Tooltip(
                  message: 'Delete pending invoice',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: _handleDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEE671C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFEE671C),
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEE671C),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'LIVE',
          style: GoogleFonts.inter(
            color: const Color(0xFFEE671C),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _EmptyWaitingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: const Color(0xFFBDC1C6).withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'All clear!',
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDEE2E6),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No invoices are waiting for review.',
            style: GoogleFonts.inter(
              color: const Color(0xFFBDC1C6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
