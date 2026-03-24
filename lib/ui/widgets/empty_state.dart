import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

const _suggestions = [
  (label: 'Explain', text: 'Explain quantum entanglement using a simple analogy from everyday life.'),
  (label: 'Write', text: 'Write a compelling noir detective story opening set in a rainy 1940s city.'),
  (label: 'Code', text: 'Write a Python function using the Sieve of Eratosthenes to find all primes up to n.'),
  (label: 'Analyse', text: 'Compare the trade-offs between microservices and monolithic architectures.'),
];

class EmptyState extends StatelessWidget {
  final void Function(String text) onSuggestion;

  const EmptyState({super.key, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo mark
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.panel,
                border: Border.all(color: c.border, width: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: GoogleFonts.instrumentSerif(
                    color: c.gold,
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'How can I help?',
              style: GoogleFonts.syne(
                color: c.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 22,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Chat · attach images & files · voice input · 200+ models',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmMono(
                color: c.muted,
                fontSize: 11,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 28),

            // Suggestions grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => _SuggestionChip(
                        label: s.label,
                        text: s.text,
                        onTap: () => onSuggestion(s.text),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String label;
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.text,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).appColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hover ? c.userBubble : c.panel,
            border: Border.all(
              color: _hover ? c.gold : c.border,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: GoogleFonts.dmMono(
                  color: c.gold,
                  fontSize: 9,
                  letterSpacing: 0.06 * 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmMono(
                  color: c.text,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
