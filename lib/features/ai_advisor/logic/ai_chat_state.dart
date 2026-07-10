abstract class AiChatState {
  const AiChatState();
}

class AiChatInitial extends AiChatState {
  const AiChatInitial();
}

class AiChatLoading extends AiChatState {
  final List<Map<String, String>> messages;

  const AiChatLoading({required this.messages});
}

class AiChatSuccess extends AiChatState {
  final List<Map<String, String>> messages;
  final String? sessionId;
  final List<Map<String, dynamic>> sessions;

  const AiChatSuccess({
    required this.messages,
    this.sessionId,
    this.sessions = const [],
  });
}

class AiChatError extends AiChatState {
  final String error;
  final List<Map<String, String>> messages;
  final String? sessionId;
  final List<Map<String, dynamic>> sessions;

  const AiChatError({
    required this.error,
    required this.messages,
    this.sessionId,
    this.sessions = const [],
  });
}
