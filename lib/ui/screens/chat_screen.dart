import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/message.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';
import '../drawer/history_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_row.dart';
import '../widgets/empty_state.dart';
import '../sheets/settings_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  bool _showScrollFab = false;
  // ignore: unused_field
  String _searchQuery = '';
  int _searchIdx = -1;
  List<int> _searchHits = [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _initFirstChat();
  }

  Future<void> _initFirstChat() async {
    final history = ref.read(historyProvider);
    if (history.isEmpty) {
      final chat =
          await ref.read(historyProvider.notifier).createChat();
      ref.read(chatProvider.notifier).setActiveChat(chat);
    } else {
      ref.read(chatProvider.notifier).loadChat(history.first.id);
    }
  }

  void _onScroll() {
    final atBottom = _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100;
    if (mounted) setState(() => _showScrollFab = !atBottom);
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  void _runSearch(String query, List<Message> messages) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchHits = [];
        _searchIdx = -1;
      });
      return;
    }
    final q = query.toLowerCase();
    final hits = <int>[];
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].content.toLowerCase().contains(q)) {
        hits.add(i);
      }
    }
    setState(() {
      _searchHits = hits;
      _searchIdx = hits.isEmpty ? -1 : 0;
    });
    if (hits.isNotEmpty) _scrollToSearchHit(hits.first);
  }

  void _navSearch(int dir, List<Message> messages) {
    if (_searchHits.isEmpty) return;
    final next =
        (_searchIdx + dir + _searchHits.length) % _searchHits.length;
    setState(() => _searchIdx = next);
    _scrollToSearchHit(_searchHits[next]);
  }

  void _scrollToSearchHit(int messageIndex) {
    // Approximate scroll position based on message index
    final approxHeight = messageIndex * 120.0;
    _scrollCtrl.animateTo(
      approxHeight.clamp(0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<void> _exportChat(List<Message> messages, String title) async {
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export')),
      );
      return;
    }
    final md = messages
        .map((m) =>
            '**${m.isUser ? 'You' : 'AI'}**\n\n${m.content}')
        .join('\n\n---\n\n');
    await Share.share(md, subject: title);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final chatState = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final messages = chatState.messages;
    final activeChat = chatState.activeChat;

    // Auto-scroll when new content streams in
    ref.listen(chatProvider, (prev, next) {
      if (next.isStreaming) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) _scrollToBottom(animated: false);
        });
      }
    });

    // Find the model label
    final modelLabel = settings.model
        .split('/')
        .last
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1)
            : w)
        .join(' ');

    return Scaffold(
      drawer: const HistoryDrawer(),
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          _ChatHeader(
            title: activeChat?.title ?? 'New Chat',
            modelLabel: modelLabel,
            showSearch: _showSearch,
            onMenuTap: () => Scaffold.of(context).openDrawer(),
            onSearchTap: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _searchQuery = '';
                _searchHits = [];
                _searchIdx = -1;
              }
            }),
            onThemeTap: () =>
                ref.read(settingsProvider.notifier).toggleTheme(),
            onExportTap: () =>
                _exportChat(messages, activeChat?.title ?? 'Chat'),
            onSettingsTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const SettingsSheet(),
            ),
            onClearTap: () => _confirmClear(context),
          ),

          // ── Search Bar ───────────────────────────────────────────────────
          if (_showSearch)
            _SearchBar(
              controller: _searchCtrl,
              hitCount: _searchHits.length,
              hitIdx: _searchIdx,
              onSearch: (q) {
                setState(() => _searchQuery = q);
                _runSearch(q, messages);
              },
              onPrev: () => _navSearch(-1, messages),
              onNext: () => _navSearch(1, messages),
              onClose: () => setState(() {
                _showSearch = false;
                _searchCtrl.clear();
                _searchQuery = '';
                _searchHits = [];
                _searchIdx = -1;
              }),
            ),

          // ── Messages ─────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                messages.isEmpty && !chatState.isStreaming
                    ? EmptyState(
                        onSuggestion: (text) {
                          ref
                              .read(chatProvider.notifier)
                              .sendMessage(text: text);
                        },
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: messages.length +
                            (chatState.isStreaming ? 1 : 0),
                        itemBuilder: (_, i) {
                          // Streaming bubble at the end
                          if (chatState.isStreaming &&
                              i == messages.length) {
                            return _StreamingBubble(
                              text: chatState.streamingText,
                            );
                          }

                          final msg = messages[i];
                          final isSearchHit = _searchHits.contains(i);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            color: isSearchHit && i == _searchHits[_searchIdx < 0 ? 0 : _searchIdx]
                                ? c.gold.withOpacity(0.07)
                                : Colors.transparent,
                            child: MessageBubble(
                              message: msg,
                              onCopy: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: msg.content),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              onRegenerate: msg.isAssistant
                                  ? () => ref
                                      .read(chatProvider.notifier)
                                      .regenerateLast()
                                  : null,
                              onEdit: msg.isUser
                                  ? (newText) => ref
                                      .read(chatProvider.notifier)
                                      .editAndRegenerate(msg.id, newText)
                                  : null,
                            ),
                          );
                        },
                      ),

                // Scroll FAB
                if (_showScrollFab)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: () => _scrollToBottom(),
                      backgroundColor: c.surface,
                      foregroundColor: c.muted,
                      elevation: 2,
                      child: const Icon(Icons.keyboard_arrow_down, size: 20),
                    ),
                  ),
              ],
            ),
          ),

          // ── Input Area ───────────────────────────────────────────────────
          const InputRow(),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text(
            'All messages in this conversation will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).clearMessages();
            },
            style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).appColors.danger),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ── Chat Header ────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String title;
  final String modelLabel;
  final bool showSearch;
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final VoidCallback onThemeTap;
  final VoidCallback onExportTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onClearTap;

  const _ChatHeader({
    required this.title,
    required this.modelLabel,
    required this.showSearch,
    required this.onMenuTap,
    required this.onSearchTap,
    required this.onThemeTap,
    required this.onExportTap,
    required this.onSettingsTap,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding:
          EdgeInsets.only(left: 12, right: 12, top: top + 8, bottom: 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Menu
          Builder(
            builder: (ctx) => _HdrBtn(
              icon: Icons.menu,
              onTap: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),

          // Title + badge
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.syne(
                      color: c.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02 * 13.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.panel,
                    border: Border.all(color: c.border, width: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    modelLabel,
                    style: GoogleFonts.dmMono(
                        color: c.gold, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          _HdrBtn(
            icon: Icons.search,
            onTap: onSearchTap,
            active: showSearch,
          ),
          _HdrBtn(icon: Icons.light_mode_outlined, onTap: onThemeTap),
          _HdrBtn(icon: Icons.ios_share_outlined, onTap: onExportTap),
          _HdrBtn(icon: Icons.settings_outlined, onTap: onSettingsTap),
          _HdrBtn(
              icon: Icons.delete_outline, onTap: onClearTap, danger: true),
        ],
      ),
    );
  }
}

class _HdrBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  const _HdrBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: active
                ? c.gold
                : danger
                    ? c.border
                    : c.border,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 14,
          color: active
              ? c.gold
              : danger
                  ? c.danger
                  : c.muted,
        ),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final int hitCount;
  final int hitIdx;
  final void Function(String) onSearch;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const _SearchBar({
    required this.controller,
    required this.hitCount,
    required this.hitIdx,
    required this.onSearch,
    required this.onPrev,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 14, color: c.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style:
                  GoogleFonts.dmMono(color: c.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search messages…',
                hintStyle:
                    GoogleFonts.dmMono(color: c.muted, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          if (hitCount > 0)
            Text(
              '${hitIdx + 1}/$hitCount',
              style: GoogleFonts.dmMono(color: c.muted, fontSize: 9.5),
            ),
          const SizedBox(width: 6),
          _SearchNavBtn(icon: Icons.keyboard_arrow_up, onTap: onPrev),
          _SearchNavBtn(icon: Icons.keyboard_arrow_down, onTap: onNext),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 16, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _SearchNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SearchNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: c.muted),
      ),
    );
  }
}

// ── Streaming bubble ───────────────────────────────────────────────────────────

class _StreamingBubble extends StatelessWidget {
  final String text;
  const _StreamingBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return MessageBubble(
      message: Message(
        id: 'streaming',
        role: MessageRole.assistant,
        content: text,
      ),
      isStreaming: true,
      streamingText: text,
    );
  }
}
