import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:invoice_ai/helper/getCurrentUserProfile.dart';
import 'package:invoice_ai/login.dart';
import 'package:invoice_ai/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nav.dart';

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
    if (profile == null) return 0;

    final nextBilling = profile!.billingDate;
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

  Future<void> _loadProfile() async {
    try {
      profile = await getCurrentUserProfile();
      final currentUser = FirebaseAuth.instance.currentUser;
      String? loadedPriceSheetUrl;

      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        final organizationId = userDoc.data()?['organization_id'];

        if (organizationId is String && organizationId.trim().isNotEmpty) {
          final organizationDoc = await FirebaseFirestore.instance
              .collection('organizations')
              .doc(organizationId.trim())
              .get();
          final rawPriceSheetUrl = organizationDoc.data()?['price_sheet_url'];

          if (rawPriceSheetUrl is String &&
              rawPriceSheetUrl.trim().isNotEmpty) {
            loadedPriceSheetUrl = rawPriceSheetUrl.trim();
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final savedLastLogin = prefs.getString('last_login_at');

      setState(() {
        priceSheetUrl = loadedPriceSheetUrl;
        lastLoginAt = savedLastLogin == null
            ? user?.metadata.lastSignInTime
            : DateTime.tryParse(savedLastLogin);
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            color: AppColors.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.borderLowContrast, height: 1),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 28),
                _buildSectionCard(
                  title: 'BUSINESS',
                  child: Column(
                    children: [
                      _buildInfoRow(
                        label: 'Registered name',
                        value: profile?.name ?? 'Unknown Business',
                        icon: Icons.apartment_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(title: 'PLAN', child: _buildPlanSection()),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'TOOLS',
                  child: Column(
                    children: [
                      _buildActionRow(
                        icon: Icons.inventory_2_outlined,
                        title: 'Inventory Sheet',
                        subtitle: 'Manage stock and products',
                        onTap: () async {
                          final sheetUrl = priceSheetUrl?.trim();
                          debugPrint('Inventory Sheet URL: $sheetUrl');

                          final uri = sheetUrl == null
                              ? null
                              : Uri.tryParse(sheetUrl);
                          if (sheetUrl == null ||
                              sheetUrl.isEmpty ||
                              uri == null ||
                              uri.scheme != 'https' ||
                              uri.host.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Inventory sheet URL is missing or invalid.',
                                ),
                              ),
                            );
                            return;
                          }

                          var launched = false;
                          try {
                            debugPrint(
                              'Inventory Sheet external launch attempt.',
                            );
                            launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            debugPrint(
                              'Inventory Sheet external launch result: $launched',
                            );
                          } catch (error, stackTrace) {
                            debugPrint(
                              'Inventory Sheet external launch error: $error',
                            );
                            debugPrintStack(stackTrace: stackTrace);
                          }

                          if (!launched) {
                            try {
                              debugPrint(
                                'Inventory Sheet platform-default launch attempt.',
                              );
                              launched = await launchUrl(
                                uri,
                                mode: LaunchMode.platformDefault,
                              );
                              debugPrint(
                                'Inventory Sheet platform-default launch result: $launched',
                              );
                            } catch (error, stackTrace) {
                              debugPrint(
                                'Inventory Sheet platform-default launch error: $error',
                              );
                              debugPrintStack(stackTrace: stackTrace);
                            }
                          }

                          if (!launched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to open the inventory sheet.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _buildDivider(),
                      _buildActionRow(
                        icon: Icons.support_agent_outlined,
                        title: 'Technical Support',
                        subtitle: 'Contact help desk',
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.support),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'SETTINGS',
                  child: _buildLanguageRow(),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'ACCOUNT',
                  child: _buildAccountSection(),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 3),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLowContrast),
          ),
          child: const Icon(Icons.business, size: 34, color: AppColors.accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.name ?? 'Unknown Business',
                style: GoogleFonts.montserrat(
                  color: AppColors.textMain,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile?.address ?? '',
                style: GoogleFonts.inter(
                  color: AppColors.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLowContrast.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
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
                  style: GoogleFonts.inter(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
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

  Widget _buildPlanSection() {
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
                          'Enterprise',
                          style: GoogleFonts.montserrat(
                            color: AppColors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _buildStatusPill('ACTIVE'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.billingDate != null
                        ? 'Billing: ${DateFormat('d MMM yyyy').format(profile!.billingDate)}'
                        : 'Billing: -',

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
                    style: GoogleFonts.inter(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _buildRowIcon(Icons.language),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Language',
              style: GoogleFonts.inter(
                color: AppColors.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLowContrast),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangToggle('EN', 'ENGLISH'),
          _buildLangToggle('AR', 'ARABIC'),
        ],
      ),
    );
  }

  Widget _buildLangToggle(String label, String value) {
    final isActive = selectedLanguage == value;

    return GestureDetector(
      onTap: () => setState(() => selectedLanguage = value),
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

  Widget _buildAccountSection() {
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
                      user?.email ?? 'No email',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastLoginAt != null
                          ? 'Last login: ${DateFormat('d MMM yyyy, HH:mm').format(lastLoginAt!)}'
                          : 'Last login: -',
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
                'LOGOUT',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRowIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.textDim, size: 21),
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
    return const Divider(
      height: 1,
      color: AppColors.borderLowContrast,
      indent: 54,
    );
  }
}
