import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice_ai/services/ai_assistant_service.dart';
import 'package:invoice_ai/services/maven_chat_session.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  static const Color _background = Color(0xFF1A1D20);
  static const Color _surface = Color(0xFF2B3035);
  static const Color _surfaceDeep = Color(0xFF1B2023);
  static const Color _accent = Color(0xFFEE671C);
  static const Color _textMain = Color(0xFFDEE2E6);
  static const Color _textDim = Color(0xFFBDC1C6);
  static const Color _border = Color(0xFF3E444A);
  static const Color _error = Color(0xFFE07A5F);
  static bool _quickPromptsHiddenForSession = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MavenChatSession _session = MavenChatSession.instance;
  bool _isSending = false;

  List<MavenChatMessage> get _messages => _session.messages;

  @override
  void initState() {
    super.initState();
    _scrollToBottom(jump: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? prompt]) async {
    if (_isSending) return;

    final text = (prompt ?? _messageController.text).trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _session.addAssistantMessage(_signedOutMessage(context), isError: true);
      });
      _scrollToBottom();
      return;
    }

    final language = Localizations.localeOf(context).languageCode == 'ar'
        ? 'ar'
        : 'en';
    final history = _session.buildRecentHistory(maxMessages: 10);

    setState(() {
      _session.addUserMessage(text);
      _quickPromptsHiddenForSession = true;
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final answer = await AiAssistantService.instance.sendMessage(
        uid: user.uid,
        language: language,
        message: text,
        history: history,
      );

      if (!mounted) return;

      final cleanedAnswer = _cleanAssistantText(answer);
      setState(() {
        _session.addAssistantMessage(
          cleanedAnswer.isEmpty ? _emptyAnswerMessage(context) : cleanedAnswer,
        );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _session.addAssistantMessage(
          _errorMessage(context, error),
          isError: true,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _cleanAssistantText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('**', '')
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .trim();
  }

  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final user = FirebaseAuth.instance.currentUser;
    final canSend = user != null && !_isSending;
    final messages = _messages;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        titleSpacing: 8,
        iconTheme: const IconThemeData(color: _textMain),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withValues(alpha: 0.28)),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: _accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maven',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: _textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isArabic ? 'مساعد مالي ذكي' : 'Financial AI assistant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: isArabic ? 'مسح المحادثة' : 'Clear chat',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                setState(() {
                  _session.clear();
                  _quickPromptsHiddenForSession = false;
                });
              },
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              children: [
                if (user == null) _buildSignedOutBanner(context),
                Expanded(child: _buildMessageList(context, messages)),
                if (_isSending) _buildTypingIndicator(context),
                if (!_quickPromptsHiddenForSession)
                  _buildQuickPrompts(context, enabled: canSend),
                _buildComposer(context, enabled: user != null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    List<MavenChatMessage> messages,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        return ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            isWide ? 24 : 16,
            isWide ? 22 : 14,
            isWide ? 24 : 16,
            16,
          ),
          children: [
            if (messages.isEmpty) _buildEmptyState(context),
            for (final message in messages) _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  Widget _buildSignedOutBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _error.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _error.withValues(alpha: 0.34)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, color: _error, size: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              _signedOutMessage(context),
              style: GoogleFonts.inter(
                color: _textMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            color: _surfaceDeep,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border.withValues(alpha: 0.82)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _accent.withValues(alpha: 0.35)),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: _accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Maven',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: _textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'أهلًا، أنا Maven. اسألني عن المبيعات، الأرباح، الفواتير، العملاء، المنتجات، التدفق النقدي، العملات، الذهب، أو نصائح البزنس.'
                    : "Hi, I'm Maven. Ask me about sales, profit, invoices, customers, products, cash flow, currencies, gold, or business advice.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _textDim,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCapabilityPill(
                    isArabic ? 'الفواتير' : 'Invoices',
                    Icons.receipt_long_rounded,
                  ),
                  _buildCapabilityPill(
                    isArabic ? 'الأرباح' : 'Profit',
                    Icons.trending_up_rounded,
                  ),
                  _buildCapabilityPill(
                    isArabic ? 'التدفق النقدي' : 'Cash flow',
                    Icons.account_balance_wallet_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withValues(alpha: 0.78)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 15),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _textMain,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MavenChatMessage message) {
    final isUser = message.role == MavenChatRole.user;
    final isArabicText = _containsArabic(message.text);
    final alignment = isUser
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final bubbleColor = isUser
        ? _accent
        : message.isError
        ? _error.withValues(alpha: 0.16)
        : _surface;
    final borderColor = isUser
        ? _accent
        : message.isError
        ? _error.withValues(alpha: 0.45)
        : _border;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth < 720
            ? constraints.maxWidth * 0.9
            : 640.0;

        return Align(
          alignment: alignment,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(16),
                topEnd: const Radius.circular(16),
                bottomStart: Radius.circular(isUser ? 16 : 6),
                bottomEnd: Radius.circular(isUser ? 6 : 16),
              ),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isArabicText
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          message.isError
                              ? Icons.error_outline_rounded
                              : Icons.insights_rounded,
                          color: message.isError ? _error : _accent,
                          size: 14,
                        ),
                        Text(
                          message.isError
                              ? (isArabicText ? 'تنبيه Maven' : 'Maven notice')
                              : 'Maven',
                          style: GoogleFonts.inter(
                            color: message.isError ? _error : _textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  message.text,
                  textDirection: isArabicText
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  textAlign: isArabicText ? TextAlign.right : TextAlign.left,
                  softWrap: true,
                  style: GoogleFonts.inter(
                    color: isUser ? Colors.white : _textMain,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  isArabic ? 'جار تجهيز الإجابة...' : 'Preparing an answer...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPrompts(BuildContext context, {required bool enabled}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final prompts = isArabic
        ? const <String>[
            'ملخص اليوم',
            'مبيعات الشهر',
            'الفواتير غير المدفوعة',
            'الربح التقديري',
            'أفضل المنتجات',
            'نصيحة مالية',
          ]
        : const <String>[
            'Today summary',
            'This month sales',
            'Outstanding invoices',
            'Estimated profit',
            'Top products',
            'Financial advice',
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        if (isWide) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: _border.withValues(alpha: 0.45)),
              ),
            ),
            child: Wrap(
              alignment: isArabic ? WrapAlignment.end : WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final prompt in prompts)
                  _buildQuickPromptChip(prompt, enabled: enabled),
              ],
            ),
          );
        }

        return SizedBox(
          height: 56,
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 11),
              itemCount: prompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = prompts[index];
                return _buildQuickPromptChip(prompt, enabled: enabled);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickPromptChip(String prompt, {required bool enabled}) {
    return ActionChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(prompt, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onPressed: enabled ? () => _sendMessage(prompt) : null,
      backgroundColor: _surface,
      disabledColor: _surface.withValues(alpha: 0.55),
      side: BorderSide(color: _border.withValues(alpha: 0.9)),
      labelStyle: GoogleFonts.inter(
        color: enabled ? _textMain : _textDim.withValues(alpha: 0.55),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildComposer(BuildContext context, {required bool enabled}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _surfaceDeep,
          border: const Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: enabled && !_isSending,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => enabled ? _sendMessage() : null,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: GoogleFonts.inter(color: _textMain, fontSize: 14),
                decoration: InputDecoration(
                  hintText: enabled
                      ? isArabic
                            ? 'اكتب رسالتك...'
                            : 'Type a message...'
                      : isArabic
                      ? 'سجل الدخول لاستخدام Maven'
                      : 'Sign in to use Maven',
                  hintStyle: GoogleFonts.inter(color: _textDim),
                  filled: true,
                  fillColor: _surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _accent, width: 1.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _border.withValues(alpha: 0.6),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: isArabic ? 'إرسال' : 'Send',
              child: SizedBox(
                width: 48,
                height: 48,
                child: FilledButton(
                  onPressed: enabled && !_isSending ? _sendMessage : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: _accent.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.send_rounded, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _signedOutMessage(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'يرجى تسجيل الدخول لاستخدام Maven.'
        : 'Please sign in to use Maven.';
  }

  String _emptyAnswerMessage(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'لم يتم استلام إجابة من Maven.'
        : 'No answer was returned from Maven.';
  }

  String _errorMessage(BuildContext context, Object error) {
    if (error is AiAssistantConnectionException) {
      return _connectionErrorMessage(context);
    }

    if (error is AiAssistantMalformedResponseException) {
      return _malformedResponseMessage(context);
    }

    if (error is AiAssistantException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }

    return _connectionErrorMessage(context);
  }

  String _connectionErrorMessage(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'تعذر الاتصال بـ Maven. حاول مرة أخرى.'
        : 'Could not reach Maven. Please try again.';
  }

  String _malformedResponseMessage(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'لم أستطع قراءة رد Maven. جرّب مرة أخرى.'
        : "I couldn't read Maven's response. Please try again.";
  }
}
