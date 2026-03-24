import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:photo_view/photo_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/message.dart';
import '../../data/models/attachment.dart';
import '../theme/app_theme.dart';
import 'streaming_cursor.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;
  final String streamingText;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final void Function(String text)? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.streamingText = '',
    this.onCopy,
    this.onRegenerate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Avatar + bubble row
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _Avatar(isUser: false),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: isUser
                    ? _UserBubble(
                        message: message,
                        onEdit: onEdit,
                      )
                    : _AIBubble(
                        message: message,
                        isStreaming: isStreaming,
                        streamingText: streamingText,
                      ),
              ),
              if (isUser) ...[
                const SizedBox(width: 10),
                _Avatar(isUser: true),
              ],
            ],
          ),
          // Action buttons
          const SizedBox(height: 4),
          _ActionRow(
            message: message,
            isUser: isUser,
            onCopy: onCopy,
            onRegenerate: onRegenerate,
            onEdit: onEdit,
          ),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: isUser ? c.gold : c.panel,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Center(
        child: Text(
          isUser ? 'U' : 'AI',
          style: TextStyle(
            fontSize: isUser ? 12 : 9,
            fontWeight: FontWeight.w600,
            color: isUser ? Colors.black : c.gold,
            fontFamily: isUser ? 'serif' : null,
          ),
        ),
      ),
    );
  }
}

// ── User Bubble ────────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final Message message;
  final void Function(String)? onEdit;

  const _UserBubble({required this.message, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.userBubble,
        border: Border.all(color: c.border.withOpacity(0.6), width: 0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attachments
          for (final att in message.attachments) ...[
            _AttachmentWidget(attachment: att),
            const SizedBox(height: 6),
          ],
          // Text content
          if (message.content.isNotEmpty)
            SelectableText(
              message.content,
              style: GoogleFonts.dmMono(
                color: c.text,
                fontSize: 13.5,
                height: 1.7,
              ),
            ),
        ],
      ),
    );
  }
}

// ── AI Bubble ──────────────────────────────────────────────────────────────────

class _AIBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;
  final String streamingText;

  const _AIBubble({
    required this.message,
    required this.isStreaming,
    required this.streamingText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).appColors;
    final displayText =
        isStreaming ? streamingText : message.content;

    final markdownStyle = MarkdownStyleSheet(
      p: GoogleFonts.dmMono(color: c.text, fontSize: 13.5, height: 1.78),
      code: GoogleFonts.dmMono(
        color: c.blue,
        fontSize: 11.5,
        backgroundColor: c.panel,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0E14) : const Color(0xFFF7F6F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border, width: 0.5),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: c.gold, width: 3),
        ),
      ),
      blockquotePadding:
          const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      h1: GoogleFonts.instrumentSerif(
          color: c.gold, fontSize: 21, height: 1.3),
      h2: GoogleFonts.instrumentSerif(
          color: c.gold, fontSize: 17, height: 1.3),
      h3: GoogleFonts.instrumentSerif(
          color: c.gold, fontSize: 14.5, height: 1.3),
      strong: GoogleFonts.dmMono(
          color: c.gold, fontWeight: FontWeight.w500, fontSize: 13.5),
      em: GoogleFonts.dmMono(
          color: const Color(0xFFB0AEAD),
          fontStyle: FontStyle.italic,
          fontSize: 13.5),
      a: GoogleFonts.dmMono(
          color: c.blue,
          decoration: TextDecoration.underline,
          fontSize: 13.5),
      tableHead: GoogleFonts.dmMono(color: c.gold, fontSize: 12),
      tableBody: GoogleFonts.dmMono(color: c.text, fontSize: 12),
      tableBorder: TableBorder.all(
        color: c.border,
        width: 0.5,
      ),
      tableHeadAlign: TextAlign.left,
      blockSpacing: 12,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: displayText.isEmpty ? ' ' : displayText,
            styleSheet: markdownStyle,
            selectable: true,
            builders: {
              'code': _SyntaxHighlightBuilder(isDark: isDark, appColors: c),
            },
            onTapLink: (text, href, title) {
              // Link tap handled here
            },
          ),
          if (isStreaming) ...[
            const SizedBox(height: 4),
            const StreamingCursor(),
          ],
        ],
      ),
    );
  }
}

// ── Syntax Highlight Builder ───────────────────────────────────────────────────

class _SyntaxHighlightBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final AppColors appColors;

  _SyntaxHighlightBuilder({required this.isDark, required this.appColors});

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final lang = element.attributes['class']
            ?.replaceFirst('language-', '') ??
        '';

    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              code,
              style: GoogleFonts.dmMono(
                fontSize: 12,
                height: 1.7,
                color: isDark
                    ? const Color(0xFFE8E6DF)
                    : const Color(0xFF1B1A1F),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: _CopyCodeBtn(code: code),
        ),
      ],
    );
  }
}

class _CopyCodeBtn extends StatefulWidget {
  final String code;
  const _CopyCodeBtn({required this.code});

  @override
  State<_CopyCodeBtn> createState() => _CopyCodeBtnState();
}

class _CopyCodeBtnState extends State<_CopyCodeBtn> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.code));
        setState(() => _copied = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.panel,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          _copied ? 'copied!' : 'copy',
          style: GoogleFonts.dmMono(
            fontSize: 9.5,
            color: _copied ? c.gold : c.muted,
          ),
        ),
      ),
    );
  }
}

// ── Attachment Widget ──────────────────────────────────────────────────────────

class _AttachmentWidget extends StatelessWidget {
  final Attachment attachment;
  const _AttachmentWidget({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;

    if (attachment.isImage) {
      return GestureDetector(
        onTap: () => _openLightbox(context, attachment),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            attachment.bytes,
            width: 260,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 14, color: c.blue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmMono(fontSize: 11, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }

  void _openLightbox(BuildContext context, Attachment att) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Material(
          color: Colors.black.withOpacity(0.92),
          child: Center(
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(att.bytes),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action Row ─────────────────────────────────────────────────────────────────

class _ActionRow extends StatefulWidget {
  final Message message;
  final bool isUser;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final void Function(String)? onEdit;

  const _ActionRow({
    required this.message,
    required this.isUser,
    this.onCopy,
    this.onRegenerate,
    this.onEdit,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    final ts = _formatTime(widget.message.createdAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _visible = true),
      onExit: (_) => setState(() => _visible = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _visible ? 1.0 : 0.0,
        child: Row(
          mainAxisAlignment: widget.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(ts,
                style: GoogleFonts.dmMono(fontSize: 9, color: c.muted)),
            const SizedBox(width: 8),
            _ActBtn(
              label: 'Copy',
              onTap: widget.onCopy,
              color: c.muted,
            ),
            if (!widget.isUser) ...[
              const SizedBox(width: 4),
              _ActBtn(
                label: 'Regenerate',
                onTap: widget.onRegenerate,
                color: c.green,
              ),
            ],
            if (widget.isUser) ...[
              const SizedBox(width: 4),
              _ActBtn(
                label: 'Edit',
                onTap: () => _showEditDialog(context),
                color: c.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(text: widget.message.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).appColors.surface,
        title: const Text('Edit message'),
        content: TextField(
          controller: ctrl,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onEdit?.call(ctrl.text.trim());
            },
            child: const Text('Save & Regenerate'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ActBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActBtn({required this.label, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmMono(fontSize: 9, color: color),
        ),
      ),
    );
  }
}
