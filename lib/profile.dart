import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice_ai/firebase_options.dart';
import 'package:invoice_ai/helper/date_formatting_helpers.dart';
import 'package:invoice_ai/helper/get_current_user_profile.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';
import 'package:invoice_ai/login.dart';
import 'package:invoice_ai/models/user_profile_model.dart';
import 'package:invoice_ai/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nav.dart';
import 'widgets/pending_invoices_badge.dart';

class AppColors {
  static const Color primaryBg = Color(0xFF1A1D20);
  static const Color surface = Color(0xFF2B3035);
  static const Color surfaceContainer = Color(0xFF1B2023);
  static const Color accent = Color(0xFFEE671C);
  static const Color textMain = Color(0xFFDEE2E6);
  static const Color textDim = Color(0xFFBDC1C6);
  static const Color borderLowContrast = Color(0xFF3E444A);
  static const Color errorMuted = Color(0xFFE07A5F);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String selectedLanguage = 'ENGLISH';
  UserProfile? profile;
  bool isLoading = true;
  DateTime? lastLoginAt;
  String? priceSheetUrl;

  double _billingProgress() {
    if (profile?.billingDate == null) return 0;

    final nextBilling = profile!.billingDate!;
    final now = DateTime.now();

    final cycleStart = DateTime(
      nextBilling.year,
      nextBilling.month - 1,
      nextBilling.day,
    );

    final totalDays = nextBilling.difference(cycleStart).inDays;
    final daysPassed = now.difference(cycleStart).inDays;

    if (totalDays <= 0) return 0;

    return (daysPassed / totalDays).clamp(0.0, 1.0);
  }

  User? get user => FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  bool _localeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_localeInitialized) {
      final locale = context.read<LocaleProvider>().locale;

      selectedLanguage = locale.languageCode == 'ar' ? 'ARABIC' : 'ENGLISH';

      _localeInitialized = true;
    }
  }

  Future<void> _loadProfile() async {
    try {
      profile = await getCurrentUserProfile();

      final prefs = await SharedPreferences.getInstance();
      final savedLastLogin = prefs.getString('last_login_at');

      if (!mounted) return;
      setState(() {
        priceSheetUrl = profile?.isOwner == true
            ? profile?.priceSheetUrl.trim()
            : null;
        lastLoginAt = savedLastLogin == null
            ? user?.metadata.lastSignInTime
            : DateTime.tryParse(savedLastLogin);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = profile?.isOwner == true;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final mobileContentBottomPadding = 168.0 + safeBottom;
    final mobileFabBottom = 96.0 + safeBottom;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          l10n.profile,
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

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.borderLowContrast, height: 1),
        ),
      ),
      body: isLoading
          ? _buildProfileLoadingState()
          : Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    isDesktop ? 40 : mobileContentBottomPadding,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileHeader(l10n),
                            const SizedBox(height: 28),
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        if (isOwner) ...[
                                          _buildSectionCard(
                                            title: l10n.plan,
                                            child: _buildPlanSection(l10n),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        _buildToolsCard(l10n, isOwner),
                                        const SizedBox(height: 16),
                                        _buildSectionCard(
                                          title: l10n.settings,
                                          child: _buildLanguageRow(l10n),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildBusinessCard(l10n),
                                        const SizedBox(height: 16),
                                        _buildSectionCard(
                                          title: l10n.account,
                                          child: _buildAccountSection(l10n),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildBusinessCard(l10n),
                              const SizedBox(height: 16),
                              if (isOwner) ...[
                                _buildSectionCard(
                                  title: l10n.plan,
                                  child: _buildPlanSection(l10n),
                                ),
                                const SizedBox(height: 16),
                              ],
                              _buildToolsCard(l10n, isOwner),
                              const SizedBox(height: 16),
                              _buildSectionCard(
                                title: l10n.settings,
                                child: _buildLanguageRow(l10n),
                              ),
                              const SizedBox(height: 16),
                              _buildSectionCard(
                                title: l10n.account,
                                child: _buildAccountSection(l10n),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isOwner && profile != null)
                  PositionedDirectional(
                    end: isDesktop ? 32 : 20,
                    bottom: isDesktop ? 32 : mobileFabBottom,
                    child: _buildAiAssistantFloatingButton(),
                  ),
              ],
            ),
      bottomNavigationBar: AppBottomNavBar(activeIndex: 3),
    );
  }

  Widget _buildBusinessCard(AppLocalizations l10n) {
    return _buildSectionCard(
      title: l10n.business,
      child: Column(
        children: [
          _buildInfoRow(
            label: l10n.registeredName,
            value: profile?.name ?? l10n.unknownBusiness,
            icon: Icons.apartment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard(AppLocalizations l10n, bool isOwner) {
    return _buildSectionCard(
      title: l10n.tools,
      child: Column(
        children: [
          if (isOwner) ...[
            _buildActionRow(
              icon: Icons.group_add_outlined,
              title: l10n.addEmployees,
              subtitle: l10n.inviteTeamMembers,
              onTap: _showAddEmployeeDialog,
            ),
            _buildDivider(),
            _buildActionRow(
              icon: Icons.percent_outlined,
              title: l10n.taxPercentage,
              subtitle:
                  '${l10n.currentTax} ${_formatPercentage(profile?.taxPercentage ?? 0)}',
              onTap: _showTaxPercentageDialog,
            ),
            _buildDivider(),
            _buildActionRow(
              icon: Icons.inventory_2_outlined,
              title: l10n.inventorySheet,
              subtitle: l10n.manageStockAndProducts,
              onTap: () => _openInventorySheet(l10n),
            ),
            _buildDivider(),
          ],
          _buildActionRow(
            icon: Icons.support_agent_outlined,
            title: l10n.technicalSupport,
            subtitle: l10n.contactHelpDesk,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.support),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantFloatingButton() {
    const label = 'Maven';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.34),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _surfaceDecoration(),
        child: const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEmployeeDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainer,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          titleTextStyle: GoogleFonts.montserrat(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: GoogleFonts.inter(
            color: AppColors.textDim,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          title: const Text('Add employee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create employee credentials for your organization.'),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: 'Employee email',
                  hintText: 'name@example.com',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.borderLowContrast.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Employee password',
                  hintText: 'At least 6 characters',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.borderLowContrast.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isEmpty || !_isValidEmail(email)) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address.'),
                    ),
                  );
                  return;
                }
                if (password.length < 6) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password must be at least 6 characters long.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();
                await _createEmployeeAccount(email, password);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _createEmployeeAccount(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();
    final ownerProfile = profile;

    if (ownerProfile?.isOwner != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only owners can add employees.')),
      );
      return;
    }

    final organizationId = ownerProfile?.organizationId.trim();
    final currentUserId = user?.uid;

    if (organizationId == null ||
        organizationId.isEmpty ||
        currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add employee right now.')),
      );
      return;
    }

    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'employeeCreation',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'duplicate-app') {
        secondaryApp = Firebase.app('employeeCreation');
      } else {
        rethrow;
      }
    }

    try {
      final employeeAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await employeeAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final employeeUser = credential.user;
      if (employeeUser == null) {
        throw StateError('Employee account was not created.');
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(employeeUser.uid)
            .set({
              'name': trimmedEmail.split('@').first,
              'email': trimmedEmail,
              'organization_id': organizationId,
              'role': 'employee',
              'created_by': currentUserId,
              'created_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {
        await employeeUser.delete();
        rethrow;
      }

      await employeeAuth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employee account for $trimmedEmail was added.'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_employeeAuthErrorMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add employee: $error')));
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _employeeAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please use a stronger password.';
      default:
        return 'Unable to add employee: ${error.message ?? error.code}';
    }
  }

  Future<void> _showTaxPercentageDialog() async {
    final controller = TextEditingController(
      text: _formatTaxInput(profile?.taxPercentage ?? 0),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainer,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          titleTextStyle: GoogleFonts.montserrat(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: GoogleFonts.inter(
            color: AppColors.textDim,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          title: const Text('Tax percentage'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tax percentage',
              suffixText: '%',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.borderLowContrast.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                final value = double.tryParse(controller.text.trim());
                if (value == null || value < 0 || value > 100) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a tax percentage from 0 to 100.'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();
                await _saveTaxPercentage(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _saveTaxPercentage(double value) async {
    final ownerProfile = profile;
    final organizationId = ownerProfile?.organizationId.trim();

    if (ownerProfile?.isOwner != true ||
        organizationId == null ||
        organizationId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only owners can update tax settings.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .set({
          'tax_percentage': value,
          'tax_updated_at': FieldValue.serverTimestamp(),
          'tax_updated_by': user?.uid,
        }, SetOptions(merge: true));

    await _loadProfile();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tax percentage set to ${_formatPercentage(value)}.'),
      ),
    );
  }

  String _formatTaxInput(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _formatPercentage(double value) => '${_formatTaxInput(value)}%';

  Future<void> _openInventorySheet(AppLocalizations l10n) async {
    final sheetUrl = priceSheetUrl?.trim();
    debugPrint('Inventory Sheet URL: $sheetUrl');

    final uri = sheetUrl == null ? null : Uri.tryParse(sheetUrl);
    if (sheetUrl == null ||
        sheetUrl.isEmpty ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.inventorySheetUrlInvalid)));
      return;
    }

    var launched = false;
    try {
      debugPrint('Inventory Sheet external launch attempt.');
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('Inventory Sheet external launch result: $launched');
    } catch (error, stackTrace) {
      debugPrint('Inventory Sheet external launch error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!launched) {
      try {
        debugPrint('Inventory Sheet platform-default launch attempt.');
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        debugPrint('Inventory Sheet platform-default launch result: $launched');
      } catch (error, stackTrace) {
        debugPrint('Inventory Sheet platform-default launch error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.unableToOpenInventorySheet)));
    }
  }

  Widget _buildProfileHeader(AppLocalizations l10n) {
    final businessAddress = profile?.address.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.business,
              size: 30,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? l10n.unknownBusiness,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textMain,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (businessAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textDim.withValues(alpha: 0.78),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          businessAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.textDim,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRowIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSection(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRowIcon(Icons.workspace_premium_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.enterprise,
                          style: GoogleFonts.montserrat(
                            color: AppColors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _buildStatusPill(l10n.active),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.billingDate != null
                        ? l10n.billingDate(
                            formatDate(context, profile!.billingDate!),
                          )
                        : 'Billing: Not set',

                    style: GoogleFonts.inter(
                      color: AppColors.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _billingProgress(),
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            _buildRowIcon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isRtl ? Icons.chevron_left : Icons.chevron_right,
              color: AppColors.textDim.withValues(alpha: 0.72),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          final labelRow = Row(
            children: [
              _buildRowIcon(Icons.language),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.language,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelRow,
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _buildLanguageSelector(l10n),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: labelRow),
              const SizedBox(width: 12),
              _buildLanguageSelector(l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangToggle(l10n.languageEnglishShort, 'ENGLISH'),
          _buildLangToggle(l10n.languageArabicShort, 'ARABIC'),
        ],
      ),
    );
  }

  Widget _buildLangToggle(String label, String value) {
    final isActive = selectedLanguage == value;

    return GestureDetector(
      onTap: () {
        final localeProvider = context.read<LocaleProvider>();

        if (value == 'ENGLISH') {
          localeProvider.setLocale('en');
        } else {
          localeProvider.setLocale('ar');
        }

        setState(() => selectedLanguage = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(AppLocalizations l10n) {
    final email = user?.email ?? profile?.email ?? l10n.noEmail;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _buildRowIcon(Icons.person_outline),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _accountDisplayName(),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _roleLabel(),
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastLoginAt != null
                          ? l10n.lastLoginDate(
                              formatDateTime(context, lastLoginAt!),
                            )
                          : l10n.lastLoginUnavailable,
                      style: GoogleFonts.inter(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildDivider(),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => LoginPage()));
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.errorMuted.withValues(alpha: 0.12),
                foregroundColor: AppColors.errorMuted,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(
                l10n.logout,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _accountDisplayName() {
    final name = profile?.userName.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user?.email ?? profile?.email;
    if (email != null && email.trim().isNotEmpty) return email.trim();

    return 'User';
  }

  String _roleLabel() {
    final role = profile?.role.trim().toLowerCase();
    if (role == 'owner') return 'Owner';
    return 'Employee';
  }

  Widget _buildRowIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.45),
        ),
      ),
      child: Icon(
        icon,
        color: AppColors.textDim.withValues(alpha: 0.9),
        size: 21,
      ),
    );
  }

  Widget _buildStatusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.borderLowContrast.withValues(alpha: 0.62),
      indent: 54,
    );
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
