import '../data/models/message.dart';
import '../data/models/attachment.dart';

class AutoDetectParams {
  final double temperature;
  final int maxTokens;
  final String tempLabel;
  final String tokLabel;

  const AutoDetectParams({
    required this.temperature,
    required this.maxTokens,
    required this.tempLabel,
    required this.tokLabel,
  });
}

class AutoDetectService {
  static AutoDetectParams detect(
    List<Message> history,
    String userText,
    List<Attachment> attachments,
  ) {
    final t = userText.toLowerCase();
    final hasImg = attachments.any((a) => a.isImage);
    final hasFile = attachments.any((a) => a.isFile);
    final fileChars = attachments
        .where((a) => a.isFile)
        .fold<int>(0, (sum, a) => sum + (a.text?.length ?? 0));
    final histLen = history.length;

    // ── Max tokens heuristic ──
    int maxTok;
    if (fileChars > 80000) {
      maxTok = 64000;
    } else if (fileChars > 30000) {
      maxTok = 32000;
    } else if (fileChars > 8000) {
      maxTok = 16384;
    } else if (_rx(r'\b(rewrite|refactor|convert|translate the (entire|whole|full)|generate (a|the) (full|complete|entire))\b', t)) {
      maxTok = 32000;
    } else if (_rx(r'\b(write (a|the|an) (full|complete|long|detailed|entire)|build (a|an|the) (full|complete))\b', t)) {
      maxTok = 16384;
    } else if (_rx(r'\b(code|function|class|component|script|program|implement|algorithm|api|backend|frontend)\b', t) && t.length > 60) {
      maxTok = 12288;
    } else if (_rx(r'\b(story|essay|article|blog post|report|thesis|document|draft|chapter)\b', t)) {
      maxTok = 8192;
    } else if (_rx(r'\b(explain|describe|analyze|compare|summarize|review|discuss|elaborate)\b', t) && t.length > 60) {
      maxTok = 6144;
    } else if (_rx(r'\b(list|enumerate|pros and cons|steps|plan|roadmap|outline)\b', t)) {
      maxTok = 4096;
    } else if (hasImg) {
      maxTok = 2048;
    } else if (t.length < 40) {
      maxTok = 1024;
    } else if (t.length < 120) {
      maxTok = 2048;
    } else {
      maxTok = 4096;
    }

    // History scaling
    if (histLen > 20 && maxTok < 8192) {
      maxTok = (maxTok * 1.5).clamp(0, 8192).toInt();
    }
    if (histLen > 40 && maxTok < 12288) {
      maxTok = (maxTok * 1.5).clamp(0, 12288).toInt();
    }
    maxTok = ((maxTok / 256).round() * 256).clamp(512, 64000);

    // ── Temperature heuristic ──
    double temp;
    if (_rx(r'\b(poem|poetry|song|lyrics|story|fiction|creative|imagine|fantasy|novel|screenplay|joke|humor|fun|roleplay|character|narrative)\b', t)) {
      temp = 0.9;
    } else if (_rx(r'\b(code|debug|fix (the |this |my )|error|bug|function|script|regex|query|sql|json|math|calculate|formula|algorithm|syntax)\b', t)) {
      temp = 0.2;
    } else if (_rx(r'\b(fact|accurate|correct|verify|truth|is it true|what is|who is|when|where|definition|explain exactly)\b', t)) {
      temp = 0.3;
    } else if (_rx(r'\b(analyze|compare|review|summarize|pros and cons|evaluate|assess|critique)\b', t)) {
      temp = 0.5;
    } else if (hasImg) {
      temp = 0.4;
    } else if (hasFile) {
      temp = 0.3;
    } else {
      temp = 0.7;
    }

    return AutoDetectParams(
      temperature: temp,
      maxTokens: maxTok,
      tempLabel: _tempLabel(temp),
      tokLabel: _tokLabel(maxTok),
    );
  }

  static bool _rx(String pattern, String input) =>
      RegExp(pattern).hasMatch(input);

  static String _tempLabel(double t) {
    if (t < 0.3) return 'Precise';
    if (t < 0.6) return 'Focused';
    if (t < 0.9) return 'Balanced';
    if (t < 1.3) return 'Creative';
    return 'Wild';
  }

  static String _tokLabel(int t) {
    if (t <= 1024) return 'Short reply';
    if (t <= 4096) return 'Medium reply';
    if (t <= 12288) return 'Long reply';
    if (t <= 32000) return 'Detailed reply';
    return 'Max reply';
  }
}
