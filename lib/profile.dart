import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:invoice_ai/helper/getCurrentUserProfile.dart';
import 'package:invoice_ai/models/user_profile_model.dart';
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

  User? get user => FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      print("Loading profile...");

      profile = await getCurrentUserProfile();

      print("Profile loaded: $profile");

      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print("ERROR: $e");
      print(stackTrace);

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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textMain,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
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
                          final sheetUrl = profile?.sheetUrl;

                          if (sheetUrl == null || sheetUrl.isEmpty) return;

                          final url = Uri.parse(sheetUrl);
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
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
                      value: 0.7,
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
    final lastLogin = user?.metadata.lastSignInTime;
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
                      lastLogin != null
                          ? 'Last login: ${DateFormat('d MMM yyyy, HH:mm').format(lastLogin)}'
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
                if (!context.mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
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
