import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/chat.dart';
import '../data/models/message.dart';
import '../data/models/attachment.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../services/ai_service.dart';
import '../services/openrouter_service.dart';
import '../services/anthropic_service.dart';
import '../services/auto_detect_service.dart';

const _uuid = Uuid();

// ── Repositories ──────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final settingsRepositoryProvider =
    FutureProvider<SettingsRepository>((ref) async {
  return SettingsRepository.create();
});

// ── Settings ──────────────────────────────────────────────────────────────────

class AppSettings {
  final String provider; // 'openrouter' | 'anthropic'
  final String theme;    // 'dark' | 'light'
  final String mode;     // 'auto' | 'manual'
  final double temperature;
  final int maxTokens;
  final String model;
  final String systemPrompt;
  final String orApiKey;
  final String anthropicApiKey;

  const AppSettings({
    this.provider = 'openrouter',
    this.theme = 'dark',
    this.mode = 'auto',
    this.temperature = 0.7,
    this.maxTokens = 8192,
    this.model = 'anthropic/claude-sonnet-4-6',
    this.systemPrompt = '',
    this.orApiKey = '',
    this.anthropicApiKey = '',
  });

  AppSettings copyWith({
    String? provider,
    String? theme,
    String? mode,
    double? temperature,
    int? maxTokens,
    String? model,
    String? systemPrompt,
    String? orApiKey,
    String? anthropicApiKey,
  }) =>
      AppSettings(
        provider: provider ?? this.provider,
        theme: theme ?? this.theme,
        mode: mode ?? this.mode,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        model: model ?? this.model,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        orApiKey: orApiKey ?? this.orApiKey,
        anthropicApiKey: anthropicApiKey ?? this.anthropicApiKey,
      );

  ThemeMode get themeMode =>
      theme == 'light' ? ThemeMode.light : ThemeMode.dark;

  String get activeApiKey =>
      provider == 'anthropic' ? anthropicApiKey : orApiKey;
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsRepository? _repo;

  SettingsNotifier() : super(const AppSettings());

  Future<void> init(SettingsRepository repo) async {
    _repo = repo;
    final orKey = await repo.getOrApiKey() ?? '';
    final anthropicKey = await repo.getAnthropicApiKey() ?? '';
    state = AppSettings(
      provider: repo.provider,
      theme: repo.theme,
      mode: repo.mode,
      temperature: repo.temperature,
      maxTokens: repo.maxTokens,
      model: repo.model,
      systemPrompt: repo.systemPrompt,
      orApiKey: orKey,
      anthropicApiKey: anthropicKey,
    );
  }

  Future<void> setProvider(String v) async {
    state = state.copyWith(provider: v);
    await _repo?.setProvider(v);
  }

  Future<void> toggleTheme() async {
    final next = state.theme == 'dark' ? 'light' : 'dark';
    state = state.copyWith(theme: next);
    await _repo?.setTheme(next);
  }

  Future<void> setMode(String v) async {
    state = state.copyWith(mode: v);
    await _repo?.setMode(v);
  }

  Future<void> setTemperature(double v) async {
    state = state.copyWith(temperature: v);
    await _repo?.setTemperature(v);
  }

  Future<void> setMaxTokens(int v) async {
    state = state.copyWith(maxTokens: v);
    await _repo?.setMaxTokens(v);
  }

  Future<void> setModel(String v) async {
    state = state.copyWith(model: v);
    await _repo?.setModel(v);
  }

  Future<void> setSystemPrompt(String v) async {
    state = state.copyWith(systemPrompt: v);
    await _repo?.setSystemPrompt(v);
  }

  Future<void> setOrApiKey(String v) async {
    state = state.copyWith(orApiKey: v);
    await _repo?.setOrApiKey(v);
  }

  Future<void> setAnthropicApiKey(String v) async {
    state = state.copyWith(anthropicApiKey: v);
    await _repo?.setAnthropicApiKey(v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final notifier = SettingsNotifier();
  ref.listen(settingsRepositoryProvider, (_, next) {
    next.whenData((repo) => notifier.init(repo));
  });
  return notifier;
});

// ── AI Service ────────────────────────────────────────────────────────────────

final aiServiceProvider = Provider<AiService>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.provider == 'anthropic'
      ? AnthropicService()
      : OpenRouterService();
});

// ── History ───────────────────────────────────────────────────────────────────

class HistoryNotifier extends StateNotifier<List<Chat>> {
  final ChatRepository _repo;

  HistoryNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getAllChats();
  }

  Future<Chat> createChat() async {
    final chat = Chat(id: _uuid.v4());
    await _repo.saveChat(chat);
    state = [chat, ...state];
    return chat;
  }

  Future<void> deleteChat(String id) async {
    await _repo.deleteChat(id);
    state = state.where((c) => c.id != id).toList();
  }

  Future<void> updateTitle(String chatId, String title) async {
    await _repo.updateChatTitle(chatId, title);
    state = state
        .map((c) => c.id == chatId ? c.copyWith(title: title) : c)
        .toList();
  }

  void refreshChat(Chat updated) {
    state = state
        .map((c) => c.id == updated.id ? updated : c)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> reload() => _load();
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<Chat>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return HistoryNotifier(repo);
});

// ── Chat State ────────────────────────────────────────────────────────────────

class ChatState {
  final Chat? activeChat;
  final bool isStreaming;
  final String streamingText;
  final String? error;
  final AutoDetectParams? lastParams;

  const ChatState({
    this.activeChat,
    this.isStreaming = false,
    this.streamingText = '',
    this.error,
    this.lastParams,
  });

  List<Message> get messages => activeChat?.messages ?? [];

  ChatState copyWith({
    Chat? Function()? activeChat,
    bool? isStreaming,
    String? streamingText,
    String? Function()? error,
    AutoDetectParams? lastParams,
  }) =>
      ChatState(
        activeChat:
            activeChat != null ? activeChat() : this.activeChat,
        isStreaming: isStreaming ?? this.isStreaming,
        streamingText: streamingText ?? this.streamingText,
        error: error != null ? error() : this.error,
        lastParams: lastParams ?? this.lastParams,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final Ref _ref;
  StreamSubscription<String>? _streamSub;

  ChatNotifier(this._repo, this._ref) : super(const ChatState());

  // ── Load chat ──────────────────────────────────────────────────────────────

  Future<void> loadChat(String chatId) async {
    final chat = await _repo.getChatById(chatId);
    state = state.copyWith(
      activeChat: () => chat,
      streamingText: '',
      error: () => null,
    );
  }

  Future<void> setActiveChat(Chat chat) async {
    state = state.copyWith(activeChat: () => chat, streamingText: '');
  }

  // ── Send message ───────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String text,
    List<Attachment> attachments = const [],
  }) async {
    if (state.isStreaming) return;
    if (text.trim().isEmpty && attachments.isEmpty) return;

    final settings = _ref.read(settingsProvider);

    // Ensure there's an active chat
    Chat chat;
    if (state.activeChat == null) {
      chat = await _ref.read(historyProvider.notifier).createChat();
    } else {
      chat = state.activeChat!;
    }

    // Add user message
    final userMsg = Message(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text.trim(),
      attachments: attachments,
    );
    chat.messages.add(userMsg);
    chat.updatedAt = DateTime.now();
    await _repo.insertMessage(chat.id, userMsg);
    state = state.copyWith(
      activeChat: () => chat,
      isStreaming: true,
      streamingText: '',
      error: () => null,
    );

    // Auto-detect or manual params
    AutoDetectParams params;
    if (settings.mode == 'auto') {
      params = AutoDetectService.detect(chat.messages, text, attachments);
    } else {
      params = AutoDetectParams(
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        tempLabel: _tempLabel(settings.temperature),
        tokLabel: _tokLabel(settings.maxTokens),
      );
    }

    // Stream AI response
    final aiService = _ref.read(aiServiceProvider);
    final aiMsgId = _uuid.v4();
    String accumulated = '';

    try {
      final stream = aiService.streamChat(
        messages: chat.messages.where((m) => m.isUser || m.isAssistant).toList(),
        model: settings.model,
        temperature: params.temperature,
        maxTokens: params.maxTokens,
        systemPrompt: settings.systemPrompt.isEmpty ? null : settings.systemPrompt,
        apiKey: settings.activeApiKey,
      );

      _streamSub = stream.listen(
        (chunk) {
          accumulated += chunk;
          state = state.copyWith(streamingText: accumulated, lastParams: params);
        },
        onDone: () async {
          await _finalizeAiMessage(chat, aiMsgId, accumulated);
        },
        onError: (e) async {
          await _finalizeAiMessage(
            chat,
            aiMsgId,
            accumulated.isEmpty ? '**Error:** ${e.toString()}' : accumulated,
          );
        },
        cancelOnError: true,
      );
    } catch (e) {
      await _finalizeAiMessage(
        chat,
        aiMsgId,
        '**Error:** ${e.toString()}',
      );
    }
  }

  Future<void> _finalizeAiMessage(
    Chat chat,
    String aiMsgId,
    String content,
  ) async {
    final aiMsg = Message(
      id: aiMsgId,
      role: MessageRole.assistant,
      content: content.isEmpty ? '_[Empty response]_' : content,
    );
    chat.messages.add(aiMsg);
    chat.updatedAt = DateTime.now();
    await _repo.insertMessage(chat.id, aiMsg);

    // Auto-title after first exchange
    if (chat.messages.length == 2 && chat.title == 'New conversation') {
      _autoTitle(chat);
    }

    _ref.read(historyProvider.notifier).refreshChat(chat);

    state = state.copyWith(
      activeChat: () => chat,
      isStreaming: false,
      streamingText: '',
    );
    _streamSub = null;
  }

  // ── Stop ───────────────────────────────────────────────────────────────────

  void stopStreaming() {
    _streamSub?.cancel();
    _streamSub = null;
    final chat = state.activeChat;
    if (chat == null) return;

    final accumulated = state.streamingText;
    final aiMsgId = _uuid.v4();
    _finalizeAiMessage(
      chat,
      aiMsgId,
      accumulated.isEmpty ? '_[Generation stopped]_' : accumulated,
    );
  }

  // ── Edit & regenerate ──────────────────────────────────────────────────────

  Future<void> editAndRegenerate(String messageId, String newText) async {
    if (state.isStreaming) return;
    final chat = state.activeChat;
    if (chat == null) return;

    final idx = chat.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    // Delete message at idx and all after it
    await _repo.deleteMessagesAfter(chat.id, chat.messages[idx].id);
    chat.messages.removeRange(idx, chat.messages.length);

    // Update the edited message
    chat.messages[idx < chat.messages.length ? idx : chat.messages.length - 1];

    state = state.copyWith(activeChat: () => chat);
    await sendMessage(text: newText);
  }

  Future<void> regenerateLast() async {
    if (state.isStreaming) return;
    final chat = state.activeChat;
    if (chat == null || chat.messages.isEmpty) return;

    // Remove last AI message
    final last = chat.messages.last;
    if (!last.isAssistant) return;

    await _repo.deleteMessage(last.id);
    chat.messages.removeLast();
    state = state.copyWith(activeChat: () => chat);

    // Retrigger with same last user message
    final lastUser =
        chat.messages.lastWhere((m) => m.isUser, orElse: () => chat.messages.last);
    await sendMessage(text: lastUser.content, attachments: lastUser.attachments);
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  Future<void> clearMessages() async {
    final chat = state.activeChat;
    if (chat == null) return;
    await _repo.clearChatMessages(chat.id);
    chat.messages.clear();
    chat.title = 'New conversation';
    state = state.copyWith(activeChat: () => chat);
    _ref.read(historyProvider.notifier).refreshChat(chat);
  }

  // ── Auto title ─────────────────────────────────────────────────────────────

  Future<void> _autoTitle(Chat chat) async {
    try {
      final settings = _ref.read(settingsProvider);
      final prompt =
          'Summarize this in 4 words or less (no punctuation): "${chat.messages.first.content}"';
      final aiService = _ref.read(aiServiceProvider);
      final title = await aiService.complete(
        prompt: prompt,
        model: settings.model,
        apiKey: settings.activeApiKey,
        maxTokens: 20,
      );
      if (title.isNotEmpty) {
        final cleaned =
            title.replaceAll(RegExp(r'''["\']'''), '').trim();
        final finalTitle = cleaned.length > 44
            ? cleaned.substring(0, 44)
            : cleaned;
        await _ref
            .read(historyProvider.notifier)
            .updateTitle(chat.id, finalTitle);
        chat.title = finalTitle;
        state = state.copyWith(activeChat: () => chat);
      }
    } catch (_) {}
  }

  String _tempLabel(double t) {
    if (t < 0.3) return 'Precise';
    if (t < 0.6) return 'Focused';
    if (t < 0.9) return 'Balanced';
    if (t < 1.3) return 'Creative';
    return 'Wild';
  }

  String _tokLabel(int t) {
    if (t <= 1024) return 'Short';
    if (t <= 4096) return 'Medium';
    if (t <= 12288) return 'Long';
    if (t <= 32000) return 'Detailed';
    return 'Max';
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repo, ref);
});

// ── Pending attachments ────────────────────────────────────────────────────────

class AttachmentsNotifier extends StateNotifier<List<Attachment>> {
  AttachmentsNotifier() : super([]);

  void add(Attachment att) => state = [...state, att];

  void remove(String id) =>
      state = state.where((a) => a.id != id).toList();

  void clear() => state = [];
}

final pendingAttachmentsProvider =
    StateNotifierProvider<AttachmentsNotifier, List<Attachment>>(
  (ref) => AttachmentsNotifier(),
);
