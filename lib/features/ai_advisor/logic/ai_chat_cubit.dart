import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/ai_chat_service.dart';
import 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final AiChatService service;

  AiChatCubit({required this.service}) : super(const AiChatInitial());

  final List<Map<String, String>> _messages = [];
  List<Map<String, dynamic>> _sessions = [];
  String? _sessionId;

  List<Map<String, String>> get messages => List.unmodifiable(_messages);
  List<Map<String, dynamic>> get sessions => List.unmodifiable(_sessions);
  String? get sessionId => _sessionId;

  Future<void> loadSessions() async {
    try {
      _sessions = await service.getSessions();
      emit(
        AiChatSuccess(
          messages: List.from(_messages),
          sessionId: _sessionId,
          sessions: List.from(_sessions),
        ),
      );
    } catch (_) {
      // History should not block the chat screen.
      emit(
        AiChatSuccess(
          messages: List.from(_messages),
          sessionId: _sessionId,
          sessions: List.from(_sessions),
        ),
      );
    }
  }

  Future<void> startNewChat() async {
    _sessionId = null;
    _messages.clear();

    emit(
      AiChatSuccess(
        messages: List.from(_messages),
        sessionId: _sessionId,
        sessions: List.from(_sessions),
      ),
    );
  }

  Future<void> openSession(String sessionId) async {
    try {
      _sessionId = sessionId;
      emit(AiChatLoading(messages: List.from(_messages)));

      final rawMessages = await service.getSessionMessages(sessionId);

      _messages
        ..clear()
        ..addAll(
          rawMessages.map((message) {
            final role = message['role']?.toString() ?? 'assistant';
            final content = message['content']?.toString() ?? '';

            return {
              'sender': role == 'user' ? 'user' : 'assistant',
              'text': content,
            };
          }),
        );

      emit(
        AiChatSuccess(
          messages: List.from(_messages),
          sessionId: _sessionId,
          sessions: List.from(_sessions),
        ),
      );
    } catch (e) {
      emit(
        AiChatError(
          error: e.toString(),
          messages: List.from(_messages),
          sessionId: _sessionId,
          sessions: List.from(_sessions),
        ),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final question = text.trim();
    if (question.isEmpty) return;

    _messages.add({
      'sender': 'user',
      'text': question,
    });

    emit(AiChatLoading(messages: List.from(_messages)));

    try {
      final response = await service.askQuestion(
        question: question,
        sessionId: _sessionId,
      );

      _sessionId = response['session_id']?.toString();

      final data = response['data'];
      final answer = data is Map
          ? data['answer']?.toString()
          : response['answer']?.toString();

      _messages.add({
        'sender': 'assistant',
        'text': answer ?? 'I could not generate a response right now.',
      });

      await loadSessions();

      emit(
        AiChatSuccess(
          messages: List.from(_messages),
          sessionId: _sessionId,
          sessions: List.from(_sessions),
        ),
      );
    } catch (e) {
      emit(
        AiChatError(
          error: e.toString(),
          messages: List.from(_messages),
          sessionId: _sessionId,
          sessions: List.from(_sessions),
        ),
      );
    }
  }
}
