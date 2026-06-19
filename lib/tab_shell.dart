import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';

import 'dash.dart';
import 'helper/get_current_user_profile.dart';
import 'invoices.dart';
import 'login.dart';
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
  UserProfile? _profile;
  bool _isLoadingProfile = true;
  bool _isSubscriptionExpired = false;
  bool _isSigningOut = false;
  int _currentPosition = 0;
  late final PageController _pageController;
  late final ReceivePageController _receivePageController;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _userActiveSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _receivePageController = ReceivePageController();
    _listenForUserActiveChanges();
    _loadProfile();
  }

  @override
  void dispose() {
    _userActiveSubscription?.cancel();
    _pageController.dispose();
    _receivePageController.dispose();
    super.dispose();
  }

  void _listenForUserActiveChanges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    _userActiveSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.data()?['is_active'] == false) {
              _signOut();
            }
          },
          onError: (error) {
            debugPrint('Unable to listen for user active status: $error');
          },
        );
  }

  Future<void> _loadProfile() async {
    UserProfile? profile;
    var profileLoadFailed = false;

    try {
      profile = await getCurrentUserProfile();
    } on InactiveOrganizationException {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _isSubscriptionExpired = true;
        _isLoadingProfile = false;
      });
      return;
    } catch (error) {
      profileLoadFailed = true;
      debugPrint('Unable to load tab profile: $error');
    }

    if (!mounted) return;

    final entries = _entriesFor(profile);
    final initialPosition = _positionForRoute(widget.initialRoute, entries);

    setState(() {
      _profile = profile;
      _isSubscriptionExpired = false;
      _currentPosition = initialPosition;
      _isLoadingProfile = false;
    });
    _syncPageController(jump: true);

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

  String _subscriptionExpiredMessage() {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'اشتراكك منتهي، يرجى تجديد الاشتراك للاستمرار باستخدام Invoice AI.'
        : 'Your subscription has expired. Please renew your subscription to continue using Invoice AI.';
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    _isSigningOut = true;
    await _userActiveSubscription?.cancel();
    _userActiveSubscription = null;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
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
    _syncPageController();
  }

  void _switchToRoute(String route) {
    final entries = _entriesFor(_profile);
    final position = _positionForRoute(route, entries);
    if (position == _currentPosition) return;

    setState(() => _currentPosition = position);
    _syncPageController();
  }

  void _openPendingInvoice(PendingInvoice invoice) {
    _switchToRoute(AppRoutes.receipts);
    _receivePageController.loadPendingInvoice(invoice);
  }

  void _syncPageController({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final page = _pageController.page?.round();
      if (page == _currentPosition) return;

      if (jump) {
        _pageController.jumpToPage(_currentPosition);
        return;
      }

      _pageController.animateToPage(
        _currentPosition,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
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

    if (_isSubscriptionExpired) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1D20),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      size: 56,
                      color: Color(0xFFEE671C),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _subscriptionExpiredMessage(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFDEE2E6),
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _signOut,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEE671C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(
                          AppLocalizations.of(context)!.logout,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final entries = _entriesFor(_profile);
    final pages = entries.map(_pageForEntry).toList();
    final activeIndex = entries[_currentPosition].index;
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return AppTabScope(
      switchToRoute: _switchToRoute,
      openPendingInvoice: _openPendingInvoice,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1D20),
        body: isDesktop
            ? Row(
                children: [
                  _DesktopNavigationRail(
                    entries: entries,
                    selectedPosition: _currentPosition,
                    onEntryTap: _switchToEntry,
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFF3E444A),
                  ),
                  Expanded(child: _buildDesktopPage(pages)),
                ],
              )
            : _buildMobilePages(pages),
        bottomNavigationBar: AppBottomNavigationSurface(
          activeIndex: activeIndex,
          isOwner: _profile?.isOwner == true,
          onEntryTap: _switchToEntry,
        ),
      ),
    );
  }

  Widget _buildDesktopPage(List<Widget> pages) {
    return IndexedStack(index: _currentPosition, children: pages);
  }

  Widget _buildMobilePages(List<Widget> pages) {
    return PageView(
      controller: _pageController,
      onPageChanged: (position) {
        if (position == _currentPosition) return;
        setState(() => _currentPosition = position);
      },
      children: pages,
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

class _DesktopNavigationRail extends StatelessWidget {
  final List<AppNavEntry> entries;
  final int selectedPosition;
  final ValueChanged<AppNavEntry> onEntryTap;

  const _DesktopNavigationRail({
    required this.entries,
    required this.selectedPosition,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRoute = entries[selectedPosition].route;

    return SafeArea(
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Invoice AI',
                  style: TextStyle(
                    color: Color(0xFFDEE2E6),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isSelected = entry.route == selectedRoute;
                    return _DesktopNavigationItem(
                      entry: entry,
                      isSelected: isSelected,
                      onTap: () => onEntryTap(entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigationItem extends StatelessWidget {
  final AppNavEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _DesktopNavigationItem({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFFEE671C)
        : const Color(0xFFDEE2E6).withValues(alpha: 0.72);

    return Material(
      color: isSelected
          ? const Color(0xFFEE671C).withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(entry.icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
