import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/attachment.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class InputRow extends ConsumerStatefulWidget {
  const InputRow({super.key});

  @override
  ConsumerState<InputRow> createState() => _InputRowState();
}

class _InputRowState extends ConsumerState<InputRow> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _speechToText = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _ctrl.addListener(() {
      setState(() => _charCount = _ctrl.text.length);
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _speechToText.stop();
    super.dispose();
  }

  // ── Send ────────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    final attachments = ref.read(pendingAttachmentsProvider);
    if (text.isEmpty && attachments.isEmpty) return;
    if (ref.read(chatProvider).isStreaming) return;

    _ctrl.clear();
    ref.read(pendingAttachmentsProvider.notifier).clear();
    setState(() => _charCount = 0);

    await ref.read(chatProvider.notifier).sendMessage(
          text: text,
          attachments: attachments,
        );
  }

  // ── Image picker ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    for (final f in files) {
      final bytes = await f.readAsBytes();
      ref.read(pendingAttachmentsProvider.notifier).add(
            Attachment(
              id: _uuid.v4(),
              type: AttachmentType.image,
              name: f.name,
              mimeType: 'image/${f.name.split('.').last.toLowerCase()}',
              bytes: bytes,
            ),
          );
    }
  }

  // ── File picker ─────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'txt', 'md', 'csv', 'json', 'js', 'ts', 'jsx', 'tsx',
        'py', 'html', 'css', 'xml', 'yaml', 'yml', 'log',
        'sh', 'sql', 'c', 'cpp', 'java', 'rs', 'go', 'rb',
        'php', 'swift', 'kt', 'dart',
      ],
    );
    if (result == null) return;
    for (final f in result.files) {
      if (f.bytes == null) continue;
      final text = String.fromCharCodes(f.bytes!).substring(
        0,
        f.bytes!.length.clamp(0, 50000),
      );
      ref.read(pendingAttachmentsProvider.notifier).add(
            Attachment(
              id: _uuid.v4(),
              type: AttachmentType.file,
              name: f.name,
              mimeType: 'text/plain',
              bytes: f.bytes!,
              text: text,
            ),
          );
    }
  }

  // ── Voice ───────────────────────────────────────────────────────────────────

  Future<void> _toggleVoice() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice not available on this device')),
      );
      return;
    }
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          _ctrl.text = result.recognizedWords;
          _ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _ctrl.text.length),
          );
          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        },
        onSoundLevelChange: (_) {},
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final chatState = ref.watch(chatProvider);
    final attachments = ref.watch(pendingAttachmentsProvider);
    final isStreaming = chatState.isStreaming;
    final canSend =
        (!isStreaming && (_ctrl.text.trim().isNotEmpty || attachments.isNotEmpty));

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 13,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment previews
          if (attachments.isNotEmpty)
            _AttachmentPreviews(
              attachments: attachments,
              onRemove: (id) =>
                  ref.read(pendingAttachmentsProvider.notifier).remove(id),
            ),

          // Input box
          Container(
            decoration: BoxDecoration(
              color: c.panel,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Tool buttons
                    _ToolBtn(
                      icon: Icons.image_outlined,
                      onTap: _pickImage,
                      color: c.muted,
                    ),
                    _ToolBtn(
                      icon: Icons.attach_file_rounded,
                      onTap: _pickFile,
                      color: c.muted,
                    ),
                    _ToolBtn(
                      icon: _isListening
                          ? Icons.mic
                          : Icons.mic_none_outlined,
                      onTap: _toggleVoice,
                      color: _isListening ? c.danger : c.muted,
                    ),

                    // Text field
                    Expanded(
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey ==
                                  LogicalKeyboardKey.enter &&
                              !HardwareKeyboard.instance.isShiftPressed) {
                            _send();
                          }
                        },
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          style: GoogleFonts.dmMono(
                            color: c.text,
                            fontSize: 13,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message AI…',
                            hintStyle: GoogleFonts.dmMono(
                              color: c.muted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Send / Stop button
                    Padding(
                      padding: const EdgeInsets.all(7),
                      child: isStreaming
                          ? _StopBtn(
                              onTap: () => ref
                                  .read(chatProvider.notifier)
                                  .stopStreaming(),
                            )
                          : _SendBtn(
                              enabled: canSend,
                              onTap: _send,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer
          const SizedBox(height: 6),
          _InputFooter(
            charCount: _charCount,
            chatState: chatState,
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _ToolBtn(
      {required this.icon, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendBtn({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE8C97A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.send_rounded, size: 16, color: Colors.black),
        ),
      ),
    );
  }
}

class _StopBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _StopBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: c.danger, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.stop_rounded, size: 16, color: c.danger),
      ),
    );
  }
}

class _AttachmentPreviews extends StatelessWidget {
  final List<Attachment> attachments;
  final void Function(String id) onRemove;

  const _AttachmentPreviews(
      {required this.attachments, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: attachments
            .map((att) => _AttPreview(att: att, onRemove: onRemove))
            .toList(),
      ),
    );
  }
}

class _AttPreview extends StatelessWidget {
  final Attachment att;
  final void Function(String id) onRemove;

  const _AttPreview({required this.att, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;

    return Stack(
      children: [
        if (att.isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(att.bytes,
                width: 54, height: 54, fit: BoxFit.cover),
          )
        else
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file_outlined,
                    size: 12, color: c.blue),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(att.name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmMono(
                          fontSize: 10, color: c.muted)),
                ),
              ],
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => onRemove(att.id),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputFooter extends StatelessWidget {
  final int charCount;
  final ChatState chatState;

  const _InputFooter(
      {required this.charCount, required this.chatState});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final params = chatState.lastParams;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Enter to send · Shift+Enter newline',
          style: GoogleFonts.dmMono(fontSize: 9, color: c.muted),
        ),
        if (params != null && chatState.isStreaming)
          Text(
            '✦ ${params.tempLabel} · ${params.tokLabel}',
            style: GoogleFonts.dmMono(fontSize: 9, color: c.muted),
          )
        else
          Text(
            '$charCount',
            style: GoogleFonts.dmMono(
              fontSize: 9,
              color: charCount > 3000 ? c.gold : c.muted,
            ),
          ),
      ],
    );
  }
}
