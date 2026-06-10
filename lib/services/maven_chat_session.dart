enum MavenChatRole { user, assistant }

class MavenChatMessage {
  final MavenChatRole role;
  final String text;
  final bool isError;
  final bool isLoading;

  const MavenChatMessage._({
    required this.role,
    required this.text,
    this.isError = false,
    this.isLoading = false,
  });

  factory MavenChatMessage.user(String text) {
    return MavenChatMessage._(role: MavenChatRole.user, text: text);
  }

  factory MavenChatMessage.assistant(String text, {bool isError = false}) {
    return MavenChatMessage._(
      role: MavenChatRole.assistant,
      text: text,
      isError: isError,
    );
  }

  factory MavenChatMessage.loading(String text) {
    return MavenChatMessage._(
      role: MavenChatRole.assistant,
      text: text,
      isLoading: true,
    );
  }
}

class MavenChatSession {
  MavenChatSession._();

  static final MavenChatSession instance = MavenChatSession._();

  final List<MavenChatMessage> _messages = <MavenChatMessage>[];

  List<MavenChatMessage> get messages => List.unmodifiable(_messages);

  void addUserMessage(String text) {
    _messages.add(MavenChatMessage.user(text));
  }

  void addAssistantMessage(String text, {bool isError = false}) {
    _messages.add(MavenChatMessage.assistant(text, isError: isError));
  }

  void addLoadingMessage(String text) {
    _messages.add(MavenChatMessage.loading(text));
  }

  void removeLoadingMessages() {
    _messages.removeWhere((message) => message.isLoading);
  }

  void clear() {
    _messages.clear();
  }

  List<Map<String, String>> buildRecentHistory({
    int maxMessages = 10,
    int maxContentLength = 1200,
  }) {
    return _messages
        .where((message) => !message.isLoading)
        .map((message) {
          final content = _limitText(message.text.trim(), maxContentLength);
          if (content.isEmpty) return null;

          return <String, String>{
            'role': message.role == MavenChatRole.user ? 'user' : 'assistant',
            'content': content,
          };
        })
        .nonNulls
        .toList()
        .reversed
        .take(maxMessages)
        .toList()
        .reversed
        .toList();
  }

  String _limitText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength).trimRight();
  }
}
