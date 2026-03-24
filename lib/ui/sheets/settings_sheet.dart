import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late TextEditingController _sysCtrl;
  late TextEditingController _orKeyCtrl;
  late TextEditingController _anthropicKeyCtrl;
  bool _showOrKey = false;
  bool _showAnthropicKey = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _sysCtrl = TextEditingController(text: s.systemPrompt);
    _orKeyCtrl = TextEditingController(text: s.orApiKey);
    _anthropicKeyCtrl = TextEditingController(text: s.anthropicApiKey);
  }

  @override
  void dispose() {
    _sysCtrl.dispose();
    _orKeyCtrl.dispose();
    _anthropicKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final s = ref.watch(settingsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('⚙️ Settings',
                      style: GoogleFonts.syne(
                        color: c.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      )),
                  IconButton(
                    icon: Icon(Icons.close, color: c.muted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // ── AI Behaviour ─────────────────────────────────────────
                  _SectionTitle('AI Behaviour'),
                  _SettingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Response Mode',
                                    style: GoogleFonts.dmMono(
                                        color: c.text, fontSize: 12)),
                                Text('Auto picks best settings per message',
                                    style: GoogleFonts.dmMono(
                                        color: c.muted, fontSize: 10)),
                              ],
                            ),
                            _ModeToggle(
                              mode: s.mode,
                              onChanged: (m) => ref
                                  .read(settingsProvider.notifier)
                                  .setMode(m),
                            ),
                          ],
                        ),
                        if (s.mode == 'manual') ...[
                          const SizedBox(height: 16),
                          // Temperature
                          _SliderRow(
                            emoji: '🎨',
                            label: 'Creativity',
                            value: s.temperature,
                            min: 0,
                            max: 2,
                            divisions: 40,
                            display: _tempLabel(s.temperature),
                            marks: const ['Precise', 'Balanced', 'Creative'],
                            onChanged: (v) => ref
                                .read(settingsProvider.notifier)
                                .setTemperature(v),
                          ),
                          const SizedBox(height: 12),
                          // Max tokens
                          _SliderRow(
                            emoji: '📏',
                            label: 'Response Length',
                            value: s.maxTokens.toDouble(),
                            min: 512,
                            max: 64000,
                            divisions: 125,
                            display: _tokLabel(s.maxTokens),
                            marks: const ['Short', 'Medium', 'Long', 'Max'],
                            onChanged: (v) => ref
                                .read(settingsProvider.notifier)
                                .setMaxTokens(v.round()),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── System Prompt ─────────────────────────────────────────
                  _SectionTitle('System Prompt'),
                  _SettingCard(
                    child: TextField(
                      controller: _sysCtrl,
                      maxLines: 4,
                      style: GoogleFonts.dmMono(
                          color: c.text, fontSize: 11, height: 1.6),
                      decoration: InputDecoration(
                        hintText:
                            'You are a helpful assistant. Be concise and clear.',
                        hintStyle: GoogleFonts.dmMono(
                            color: c.muted, fontSize: 11),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setSystemPrompt(v),
                    ),
                  ),

                  // ── API Keys ──────────────────────────────────────────────
                  _SectionTitle('API Keys'),
                  _SettingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OpenRouter
                        _ApiKeyLabel(
                          label: 'OpenRouter API Key',
                          hint: 'sk-or-v1-...',
                          link: 'openrouter.ai/keys',
                          controller: _orKeyCtrl,
                          show: _showOrKey,
                          onToggleShow: () =>
                              setState(() => _showOrKey = !_showOrKey),
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setOrApiKey(v),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        // Anthropic
                        _ApiKeyLabel(
                          label: 'Anthropic API Key',
                          hint: 'sk-ant-...',
                          link: 'console.anthropic.com/keys',
                          controller: _anthropicKeyCtrl,
                          show: _showAnthropicKey,
                          onToggleShow: () => setState(
                              () => _showAnthropicKey = !_showAnthropicKey),
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setAnthropicApiKey(v),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.gold.withOpacity(0.06),
                            border: Border.all(
                                color: c.gold.withOpacity(0.2), width: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔒 Keys are stored encrypted on this device using the system keychain. Never sent to any server except the AI provider you choose.',
                            style: GoogleFonts.dmMono(
                                color: c.muted, fontSize: 9, height: 1.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Theme ─────────────────────────────────────────────────
                  _SectionTitle('Appearance'),
                  _SettingCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Theme',
                            style: GoogleFonts.dmMono(
                                color: c.text, fontSize: 12)),
                        GestureDetector(
                          onTap: () => ref
                              .read(settingsProvider.notifier)
                              .toggleTheme(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: c.panel,
                              border:
                                  Border.all(color: c.border, width: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  s.theme == 'dark'
                                      ? Icons.dark_mode
                                      : Icons.light_mode,
                                  size: 14,
                                  color: c.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.theme == 'dark' ? 'Dark' : 'Light',
                                  style: GoogleFonts.dmMono(
                                      color: c.text, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── About ─────────────────────────────────────────────────
                  _SectionTitle('About'),
                  _SettingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AboutRow('Version', '1.0.0'),
                        _AboutRow('Providers', 'OpenRouter · Anthropic'),
                        _AboutRow('Models', '200+ via OpenRouter'),
                        _AboutRow('Storage', 'SQLite + Encrypted Keychain'),
                        _AboutRow('Backend', 'None — direct API calls'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    return 'Maximum';
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: GoogleFonts.dmMono(
              color: c.muted,
              fontSize: 10,
              letterSpacing: 0.1 * 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Theme.of(context).appColors.border)),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String mode;
  final void Function(String) onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOpt(
              label: 'Auto ✦',
              active: mode == 'auto',
              onTap: () => onChanged('auto')),
          _ToggleOpt(
              label: 'Manual',
              active: mode == 'manual',
              onTap: () => onChanged('manual')),
        ],
      ),
    );
  }
}

class _ToggleOpt extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleOpt(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmMono(
            color: active ? Colors.black : c.muted,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String emoji;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final List<String> marks;
  final void Function(double) onChanged;

  const _SliderRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.marks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$emoji $label',
                style: GoogleFonts.dmMono(color: c.text, fontSize: 11)),
            Text(display,
                style: GoogleFonts.dmMono(color: c.gold, fontSize: 10)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: c.gold,
            inactiveTrackColor: c.border,
            thumbColor: c.gold,
            overlayColor: c.gold.withOpacity(0.15),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: marks
              .map((m) => Text(m,
                  style: GoogleFonts.dmMono(
                      color: c.muted, fontSize: 8.5)))
              .toList(),
        ),
      ],
    );
  }
}

class _ApiKeyLabel extends StatelessWidget {
  final String label;
  final String hint;
  final String link;
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggleShow;
  final void Function(String) onChanged;

  const _ApiKeyLabel({
    required this.label,
    required this.hint,
    required this.link,
    required this.controller,
    required this.show,
    required this.onToggleShow,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.dmMono(
                    color: c.text, fontSize: 11)),
            Text(link,
                style: GoogleFonts.dmMono(
                    color: c.blue, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !show,
          style: GoogleFonts.dmMono(color: c.text, fontSize: 11),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmMono(color: c.muted, fontSize: 11),
            suffixIcon: GestureDetector(
              onTap: onToggleShow,
              child: Icon(
                show ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: c.muted,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  GoogleFonts.dmMono(color: c.muted, fontSize: 11)),
          Text(value,
              style:
                  GoogleFonts.dmMono(color: c.text, fontSize: 11)),
        ],
      ),
    );
  }
}
