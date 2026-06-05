import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';

import 'nav.dart';

class TechnicalSupportPage extends StatefulWidget {
  const TechnicalSupportPage({super.key});

  @override
  State<TechnicalSupportPage> createState() => _TechnicalSupportPageState();
}

class _TechnicalSupportPageState extends State<TechnicalSupportPage> {
  String? selectedIssue;
  bool _isSending = false;
  final TextEditingController _messageController = TextEditingController();

  static const Color _background = Color(0xFF1A1D20);
  static const Color _surfaceCard = Color(0xFF2B3035);
  static const Color _surfaceContainer = Color(0xFF1B2023);
  static const Color _accent = Color(0xFFEE671C);
  static const Color _textPrimary = Color(0xFFDEE2E6);
  static const Color _textMuted = Color(0xFFBDC1C6);
  static const Color _border = Color(0xFF3E444A);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.technicalSupport,
          style: GoogleFonts.montserrat(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _border, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        children: [
          _buildIntroCard(l10n),
          const SizedBox(height: 16),
          _buildIssueSelector(l10n),
          const SizedBox(height: 16),
          _buildMessageCard(l10n),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(activeIndex: 3),
    );
  }

  Widget _buildIntroCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.support_agent_outlined,
              color: _accent,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.needHelp,
                  style: GoogleFonts.montserrat(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.supportIntro,
                  style: GoogleFonts.inter(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueSelector(AppLocalizations l10n) {
    selectedIssue ??= l10n.issueInvoices;
    final issues = [
      l10n.issueInvoices,
      l10n.issueReceipts,
      l10n.issueAccount,
      l10n.issueOther,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(l10n.issueType),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: issues.map((issue) {
              final isActive = selectedIssue == issue;

              return ChoiceChip(
                label: Text(issue),
                selected: isActive,
                onSelected: (_) => setState(() => selectedIssue = issue),
                selectedColor: _accent,
                backgroundColor: _surfaceCard,
                side: BorderSide(color: isActive ? _accent : _border),
                labelStyle: GoogleFonts.inter(
                  color: isActive ? Colors.white : _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(l10n.message),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            minLines: 5,
            maxLines: 5,
            style: GoogleFonts.inter(color: _textPrimary),
            decoration: InputDecoration(
              hintText: l10n.describeIssue,
              hintStyle: GoogleFonts.inter(color: _textMuted),
              filled: true,
              fillColor: _surfaceCard,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : () => _sendSupportRequest(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withValues(alpha: 0.65),
                disabledForegroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(
                _isSending ? l10n.sending : l10n.sendRequest,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSupportRequest(AppLocalizations l10n) async {
    final issueType = selectedIssue?.trim() ?? '';
    final message = _messageController.text.trim();

    if (issueType.isEmpty) {
      _showSupportError(l10n.issueType);
      return;
    }

    if (message.isEmpty) {
      _showSupportError(l10n.writeMessageFirst);
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      final userEmail = user?.email?.trim();

      if (userId == null || userId.isEmpty) {
        throw StateError('A signed-in user is required.');
      }

      if (userEmail == null || userEmail.isEmpty) {
        throw StateError('A user email is required.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final organizationId = userDoc.data()?['organization_id'];

      if (organizationId is! String || organizationId.trim().isEmpty) {
        throw StateError('A valid organization_id is required.');
      }

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'user_id': userId,
        'organization_id': organizationId.trim(),
        'user_email': userEmail,
        'issue_type': issueType,
        'message': message,
        'status': 'new',
        'source': 'flutter_app',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requestSentSuccessfully)));

      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSupportError(l10n.failedToSendRequest);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSupportError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surfaceCard,
        content: Text(message, style: GoogleFonts.inter(color: _textPrimary)),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: _textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}
