import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/message.dart';
import 'ai_service.dart';

const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

class OpenRouterService implements AiService {
  @override
  String get displayName => 'OpenRouter';

  @override
  String get providerId => 'openrouter';

  @override
  Stream<String> streamChat({
    required List<Message> messages,
    required String model,
    required double temperature,
    required int maxTokens,
    String? systemPrompt,
    required String apiKey,
  }) async* {
    if (apiKey.isEmpty) {
      throw Exception('OpenRouter API key is required. Add it in Settings.');
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://aichat.app',
        'X-Title': 'AI Chat',
      });

      request.body = jsonEncode({
        'model': model,
        'messages': _buildMessages(messages, systemPrompt),
        'stream': true,
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        String errMsg = 'OpenRouter ${streamedResponse.statusCode}';
        try {
          final j = jsonDecode(body);
          errMsg = j['error']?['message'] ?? errMsg;
        } catch (_) {}
        throw Exception(errMsg);
      }

      String buffer = '';
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete line

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          try {
            final j = jsonDecode(data) as Map<String, dynamic>;
            final content =
                j['choices']?[0]?['delta']?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<String> complete({
    required String prompt,
    required String model,
    required String apiKey,
    int maxTokens = 30,
  }) async {
    if (apiKey.isEmpty) return '';
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://aichat.app',
        'X-Title': 'AI Chat',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': maxTokens,
        'temperature': 0.3,
      }),
    );
    if (res.statusCode != 200) return '';
    final j = jsonDecode(res.body);
    return (j['choices']?[0]?['message']?['content'] as String?)?.trim() ??
        '';
  }

  List<Map<String, dynamic>> _buildMessages(
    List<Message> history,
    String? systemPrompt,
  ) {
    final result = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      result.add({'role': 'system', 'content': systemPrompt});
    }

    for (final msg in history) {
      if (msg.isAssistant) {
        result.add({'role': 'assistant', 'content': msg.content});
        continue;
      }

      final images = msg.attachments.where((a) => a.isImage).toList();
      final files = msg.attachments.where((a) => a.isFile).toList();

      String text = msg.content;
      if (files.isNotEmpty) {
        text += files
            .map((f) =>
                '\n\n--- File: ${f.name} ---\n${f.text ?? ''}\n--- End: ${f.name} ---')
            .join('');
      }

      if (images.isNotEmpty) {
        final content = <Map<String, dynamic>>[
          for (final img in images) img.toOpenAIImageBlock(),
          {'type': 'text', 'text': text.isEmpty ? 'Describe this image.' : text},
        ];
        result.add({'role': 'user', 'content': content});
      } else {
        result.add({'role': 'user', 'content': text});
      }
    }

    return result;
  }
}
