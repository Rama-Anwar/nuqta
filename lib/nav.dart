import 'package:flutter/material.dart';
import 'package:invoice_ai/helper/get_current_user_profile.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';
import 'package:invoice_ai/services/pending_invoices_service.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String dash = '/dash';
  static const String receipts = '/receipts';
  static const String invoices = '/invoices';
  static const String profile = '/profile';
  static const String support = '/support';
  static const String aiAssistant = '/ai-assistant';
    static const String inventory = '/inventory';
}

class AppBottomNavBar extends StatelessWidget {
  final int activeIndex;

  const AppBottomNavBar({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 768) {
      return const SizedBox.shrink();
    }

    if (AppTabScope.maybeOf(context) != null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: getCurrentUserProfile(),
      builder: (context, snapshot) {
        return AppBottomNavigationSurface(
          activeIndex: activeIndex,
          isOwner: snapshot.data?.isOwner == true,
        );
      },
    );
  }
}

class AppTabScope extends InheritedWidget {
  final void Function(String route)? switchToRoute;
  final void Function(PendingInvoice invoice)? openPendingInvoice;

  const AppTabScope({
    super.key,
    required super.child,
    this.switchToRoute,
    this.openPendingInvoice,
  });

  static AppTabScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTabScope>();
  }

  @override
  bool updateShouldNotify(AppTabScope oldWidget) {
    return switchToRoute != oldWidget.switchToRoute ||
        openPendingInvoice != oldWidget.openPendingInvoice;
  }
}

class AppBottomNavigationSurface extends StatelessWidget {
  final int activeIndex;
  final bool isOwner;
  final ValueChanged<AppNavEntry>? onEntryTap;

  const AppBottomNavigationSurface({
    super.key,
    required this.activeIndex,
    required this.isOwner,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 768) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final entries = AppNavEntry.entries(l10n, isOwner: isOwner);

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D20),
        border: Border(top: BorderSide(color: Color(0xFF3E444A))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: entries.map((entry) {
            final isActive = entry.index == activeIndex;
            final color = isActive
                ? const Color(0xFFEE671C)
                : const Color(0xFFDEE2E6).withValues(alpha: 0.62);

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (isActive) return;
                  final shell = AppTabScope.maybeOf(context);
                  if (onEntryTap != null) {
                    onEntryTap!(entry);
                  } else if (shell?.switchToRoute != null) {
                    shell!.switchToRoute!(entry.route);
                  } else {
                    Navigator.of(context).pushReplacementNamed(entry.route);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(entry.icon, size: 24, color: color),
                    const SizedBox(height: 2),
                    Text(
                      entry.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SectionPlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final int activeIndex;

  const SectionPlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D20),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 56,
                  color: Color(0xFFEE671C),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDEE2E6),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFBDC1C6),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(activeIndex: activeIndex),
    );
  }
}

class AppNavEntry {
  final String label;
  final IconData icon;
  final String route;
  final int index;

  const AppNavEntry({
    required this.label,
    required this.icon,
    required this.route,
    required this.index,
  });

  static List<AppNavEntry> entries(
    AppLocalizations l10n, {
    required bool isOwner,
  }) {
    return [
      if (isOwner)
        AppNavEntry(
          label: l10n.dashboard,
          icon: Icons.dashboard_rounded,
          route: AppRoutes.dash,
          index: 0,
        ),
      AppNavEntry(
        label: l10n.receipts,
        icon: Icons.receipt_long_rounded,
        route: AppRoutes.receipts,
        index: 1,
      ),
      AppNavEntry(
        label: l10n.invoices,
        icon: Icons.description_rounded,
        route: AppRoutes.invoices,
        index: 2,
      ),
      AppNavEntry(
        label: l10n.profile,
        icon: Icons.person_rounded,
        route: AppRoutes.profile,
        index: 3,
      ),
    ];
  }
}
