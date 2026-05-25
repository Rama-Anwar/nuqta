import 'package:flutter/material.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String dash = '/dash';
  static const String receipts = '/receipts';
  static const String invoices = '/invoices';
  static const String profile = '/profile';
}

class AppBottomNavBar extends StatelessWidget {
  final int activeIndex;

  const AppBottomNavBar({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 768) {
      return const SizedBox.shrink();
    }

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
          children: List.generate(_NavEntry.entries.length, (index) {
            final entry = _NavEntry.entries[index];
            final isActive = index == activeIndex;
            final color = isActive ? const Color(0xFFEE671C) : const Color(0xFFDEE2E6).withValues(alpha: 0.62);

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (isActive) return;
                  Navigator.of(context).pushReplacementNamed(entry.route);
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
          }),
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
                const Icon(Icons.construction_rounded, size: 56, color: Color(0xFFEE671C)),
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

class _NavEntry {
  final String label;
  final IconData icon;
  final String route;

  const _NavEntry({required this.label, required this.icon, required this.route});

  static const entries = <_NavEntry>[
    _NavEntry(label: 'Dashboard', icon: Icons.dashboard_rounded, route: AppRoutes.dash),
    _NavEntry(label: 'Receipts', icon: Icons.receipt_long_rounded, route: AppRoutes.receipts),
    _NavEntry(label: 'Invoices', icon: Icons.description_rounded, route: AppRoutes.invoices),
    _NavEntry(label: 'Profile', icon: Icons.person_rounded, route: AppRoutes.profile),
  ];
}