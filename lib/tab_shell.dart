import 'package:flutter/material.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';

import 'dash.dart';
import 'helper/get_current_user_profile.dart';
import 'invoices.dart';
import 'models/user_profile_model.dart';
import 'nav.dart';
import 'profile.dart';
import 'recive.dart';
import 'services/pending_invoices_service.dart';

class AppTabShell extends StatefulWidget {
  final String initialRoute;

  const AppTabShell({super.key, required this.initialRoute});

  @override
  State<AppTabShell> createState() => _AppTabShellState();
}

class _AppTabShellState extends State<AppTabShell> {
  late PageController _pageController;
  UserProfile? _profile;
  bool _isLoadingProfile = true;
  int _currentPosition = 0;
  late final ReceivePageController _receivePageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _receivePageController = ReceivePageController();
    _loadProfile();
  }

  @override
  void dispose() {
    _receivePageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    UserProfile? profile;
    var profileLoadFailed = false;

    try {
      profile = await getCurrentUserProfile();
    } catch (error) {
      profileLoadFailed = true;
      debugPrint('Unable to load tab profile: $error');
    }

    if (!mounted) return;

    final entries = _entriesFor(profile);
    final initialPosition = _positionForRoute(widget.initialRoute, entries);

    _pageController.dispose();
    _pageController = PageController(initialPage: initialPosition);

    setState(() {
      _profile = profile;
      _currentPosition = initialPosition;
      _isLoadingProfile = false;
    });

    if (profileLoadFailed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load account details. Limited access shown.',
          ),
        ),
      );
    }
  }

  List<AppNavEntry> _entriesFor(UserProfile? profile) {
    final l10n = AppLocalizations.of(context)!;
    return AppNavEntry.entries(l10n, isOwner: profile?.isOwner == true);
  }

  int _positionForRoute(String route, List<AppNavEntry> entries) {
    final index = entries.indexWhere((entry) => entry.route == route);
    if (index >= 0) return index;

    final receiptsIndex = entries.indexWhere(
      (entry) => entry.route == AppRoutes.receipts,
    );
    return receiptsIndex >= 0 ? receiptsIndex : 0;
  }

  void _switchToEntry(AppNavEntry entry) {
    final entries = _entriesFor(_profile);
    final position = _positionForRoute(entry.route, entries);
    if (position == _currentPosition) return;

    setState(() => _currentPosition = position);
    _pageController.animateToPage(
      position,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _switchToRoute(String route) {
    final entries = _entriesFor(_profile);
    final position = _positionForRoute(route, entries);
    if (position == _currentPosition) return;

    setState(() => _currentPosition = position);
    _pageController.animateToPage(
      position,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _openPendingInvoice(PendingInvoice invoice) {
    _switchToRoute(AppRoutes.receipts);
    _receivePageController.loadPendingInvoice(invoice);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1D20),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEE671C)),
        ),
      );
    }

    final entries = _entriesFor(_profile);
    final pages = entries.map(_pageForEntry).toList();
    final activeIndex = entries[_currentPosition].index;

    return AppTabScope(
      switchToRoute: _switchToRoute,
      openPendingInvoice: _openPendingInvoice,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1D20),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentPosition = index);
          },
          children: pages,
        ),
        bottomNavigationBar: AppBottomNavigationSurface(
          activeIndex: activeIndex,
          isOwner: _profile?.isOwner == true,
          onEntryTap: _switchToEntry,
        ),
      ),
    );
  }

  Widget _pageForEntry(AppNavEntry entry) {
    return _KeepAliveTab(
      child: switch (entry.route) {
        AppRoutes.dash => DashPage(),
        AppRoutes.receipts => ReceivePage(controller: _receivePageController),
        AppRoutes.invoices => const InvoicesPage(),
        AppRoutes.profile => const ProfileScreen(),
        _ => ReceivePage(controller: _receivePageController),
      },
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
