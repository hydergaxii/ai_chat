import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/chat.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

// ── Model definitions ─────────────────────────────────────────────────────────

const _puterModels = [
  (id: 'claude-sonnet-4-6', label: 'Claude Sonnet 4.6 ✦', vision: true),
  (id: 'claude-opus-4-6', label: 'Claude Opus 4.6', vision: true),
  (id: 'claude-haiku-4-5', label: 'Claude Haiku 4.5 — Fast', vision: true),
  (id: 'claude-sonnet-4-5', label: 'Claude Sonnet 4.5', vision: true),
  (id: 'claude-3-7-sonnet', label: 'Claude 3.7 Sonnet', vision: true),
  (id: 'claude-3-5-sonnet', label: 'Claude 3.5 Sonnet', vision: true),
];

const _orModels = [
  (id: 'anthropic/claude-sonnet-4-6', label: 'Claude Sonnet 4.6 ✦', vision: true),
  (id: 'anthropic/claude-opus-4-6', label: 'Claude Opus 4.6', vision: true),
  (id: 'openai/gpt-4o', label: 'GPT-4o', vision: true),
  (id: 'openai/gpt-4o-mini', label: 'GPT-4o Mini', vision: true),
  (id: 'openai/o3-mini', label: 'o3 Mini', vision: false),
  (id: 'google/gemini-2.5-pro-preview', label: 'Gemini 2.5 Pro', vision: true),
  (id: 'google/gemini-2.0-flash-001', label: 'Gemini 2.0 Flash', vision: true),
  (id: 'meta-llama/llama-3.3-70b-instruct', label: 'Llama 3.3 70B', vision: false),
  (id: 'deepseek/deepseek-r1', label: 'DeepSeek R1', vision: false),
  (id: 'deepseek/deepseek-chat-v3-0324', label: 'DeepSeek v3', vision: false),
  (id: 'mistralai/mistral-large-2411', label: 'Mistral Large', vision: false),
  (id: 'x-ai/grok-3-mini-beta', label: 'Grok 3 Mini', vision: false),
];

const _anthropicModels = [
  (id: 'claude-sonnet-4-6-20250514', label: 'Claude Sonnet 4.6', vision: true),
  (id: 'claude-opus-4-6-20250514', label: 'Claude Opus 4.6', vision: true),
  (id: 'claude-haiku-4-5-20251001', label: 'Claude Haiku 4.5', vision: true),
];

class HistoryDrawer extends ConsumerWidget {
  const HistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).appColors;
    final settings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);
    final chatState = ref.watch(chatProvider);

    List<({String id, String label, bool vision})> models;
    if (settings.provider == 'anthropic') {
      models = _anthropicModels;
    } else if (settings.provider == 'openrouter') {
      models = _orModels;
    } else {
      models = _puterModels;
    }

    return Drawer(
      child: Column(
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 16,
              right: 16,
              bottom: 14,
            ),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: c.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Chat',
                      style: GoogleFonts.syne(
                        color: c.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02 * 14,
                      ),
                    ),
                    Text(
                      'Multi-model · No backend',
                      style: GoogleFonts.dmMono(
                          color: c.muted, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Provider Tabs ─────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: c.border, width: 0.5)),
            ),
            child: Row(
              children: [
                _ProvTab(
                  label: 'OpenRouter',
                  active: settings.provider == 'openrouter',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setProvider('openrouter'),
                ),
                const SizedBox(width: 5),
                _ProvTab(
                  label: 'Anthropic',
                  active: settings.provider == 'anthropic',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setProvider('anthropic'),
                ),
              ],
            ),
          ),

          // ── Model Select ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SbLabel('Model'),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.panel,
                    border: Border.all(color: c.border, width: 0.5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: DropdownButton<String>(
                    value: models.any((m) => m.id == settings.model)
                        ? settings.model
                        : models.first.id,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: c.panel,
                    style: GoogleFonts.dmMono(
                        color: c.text, fontSize: 11),
                    items: models
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.label,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setModel(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          const Divider(height: 1),

          // ── Chat History ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SbLabel('Conversations'),
                      const SizedBox(height: 6),
                      // New chat button
                      GestureDetector(
                        onTap: () async {
                          final chat = await ref
                              .read(historyProvider.notifier)
                              .createChat();
                          ref
                              .read(chatProvider.notifier)
                              .setActiveChat(chat);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: c.border, width: 0.5),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 12, color: c.muted),
                              const SizedBox(width: 7),
                              Text(
                                'New Conversation',
                                style: GoogleFonts.dmMono(
                                    fontSize: 10.5, color: c.text),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: history.length,
                    itemBuilder: (_, i) => _ChatItem(
                      chat: history[i],
                      isActive: chatState.activeChat?.id == history[i].id,
                      onTap: () {
                        ref
                            .read(chatProvider.notifier)
                            .loadChat(history[i].id);
                        Navigator.of(context).pop();
                      },
                      onDelete: () {
                        ref
                            .read(historyProvider.notifier)
                            .deleteChat(history[i].id);
                        if (chatState.activeChat?.id == history[i].id) {
                          ref
                              .read(chatProvider.notifier)
                              .setActiveChat(
                                history.length > 1 ? history[1] : Chat(id: 'new'),
                              );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Privacy notice ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.gold.withOpacity(0.06),
              border:
                  Border.all(color: c.gold.withOpacity(0.18), width: 0.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔒 Privacy',
                  style: GoogleFonts.dmMono(
                      color: c.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'API keys stored securely on-device (encrypted). Never shared. No backend — requests go directly to AI providers.',
                  style: GoogleFonts.dmMono(
                      color: c.muted, fontSize: 9, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SbLabel extends StatelessWidget {
  final String text;
  const _SbLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmMono(
        color: c.muted,
        fontSize: 9,
        letterSpacing: 0.12 * 9,
      ),
    );
  }
}

class _ProvTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ProvTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: active ? c.gold : Colors.transparent,
            border: Border.all(color: c.border, width: 0.5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmMono(
              color: active ? Colors.black : c.muted,
              fontSize: 9.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatItem extends StatefulWidget {
  final Chat chat;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatItem({
    required this.chat,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<_ChatItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final age = _formatAge(widget.chat.updatedAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isActive || _hover ? c.panel : Colors.transparent,
            border: Border.all(
              color: widget.isActive ? c.border : Colors.transparent,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c.bg,
                  border: Border.all(color: c.border, width: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text('💬',
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.title,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmMono(
                          color: c.text, fontSize: 10.5),
                    ),
                    Text(
                      '$age · ${widget.chat.messages.length} msgs',
                      style: GoogleFonts.dmMono(
                          color: c.muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (_hover)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete conversation?'),
                        content: Text(
                            'This will permanently delete "${widget.chat.title}".'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onDelete();
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: c.danger),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('×',
                      style: TextStyle(color: c.muted, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
