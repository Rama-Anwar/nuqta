import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:invoice_ai/helper/sendSupportEmail.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nav.dart';

class TechnicalSupportPage extends StatefulWidget {
  const TechnicalSupportPage({super.key});

  @override
  State<TechnicalSupportPage> createState() => _TechnicalSupportPageState();
}

class _TechnicalSupportPageState extends State<TechnicalSupportPage> {
  String selectedIssue = 'Invoices';
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
          'Technical Support',
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
          _buildIntroCard(),
          const SizedBox(height: 16),
          _buildIssueSelector(),
          const SizedBox(height: 16),
          _buildMessageCard(),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 3),
    );
  }

  Widget _buildIntroCard() {
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
                  'Need help?',
                  style: GoogleFonts.montserrat(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Send us the issue details and the support team will follow up.',
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

  Widget _buildIssueSelector() {
    final issues = ['Invoices', 'Receipts', 'Inventory', 'Account'];

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
          _buildSectionLabel('ISSUE TYPE'),
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

  Widget _buildMessageCard() {
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
          _buildSectionLabel('MESSAGE'),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            minLines: 5,
            maxLines: 5,
            style: GoogleFonts.inter(color: _textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe what happened...',
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
              onPressed: _sendSupportRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(
                'SEND REQUEST',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSupportRequest() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      _showSupportError("Please write a message first.");
      return;
    }

    try {
      await sendSupportEmail(issueType: selectedIssue, message: message);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent successfully")),
      );

      _messageController.clear();
    } catch (e) {
      _showSupportError("Failed to send request. Try again.");
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
