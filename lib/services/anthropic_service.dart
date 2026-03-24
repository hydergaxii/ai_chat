import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/message.dart';
import 'ai_service.dart';

const _baseUrl = 'https://api.anthropic.com/v1/messages';
const _anthropicVersion = '2023-06-01';

class AnthropicService implements AiService {
  @override
  String get displayName => 'Anthropic';

  @override
  String get providerId => 'anthropic';

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
      throw Exception('Anthropic API key is required. Add it in Settings.');
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': _anthropicVersion,
        'content-type': 'application/json',
      });

      final body = <String, dynamic>{
        'model': model,
        'messages': _buildMessages(messages),
        'stream': true,
        'temperature': temperature,
        'max_tokens': maxTokens,
      };
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['system'] = systemPrompt;
      }

      request.body = jsonEncode(body);

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final b = await streamedResponse.stream.bytesToString();
        String errMsg = 'Anthropic ${streamedResponse.statusCode}';
        try {
          final j = jsonDecode(b);
          errMsg = j['error']?['message'] ?? errMsg;
        } catch (_) {}
        throw Exception(errMsg);
      }

      String buffer = '';
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          try {
            final j = jsonDecode(data) as Map<String, dynamic>;
            if (j['type'] == 'content_block_delta') {
              final text = j['delta']?['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
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
        'x-api-key': apiKey,
        'anthropic-version': _anthropicVersion,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': maxTokens,
      }),
    );
    if (res.statusCode != 200) return '';
    final j = jsonDecode(res.body);
    return (j['content']?[0]?['text'] as String?)?.trim() ?? '';
  }

  List<Map<String, dynamic>> _buildMessages(List<Message> history) {
    final result = <Map<String, dynamic>>[];
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
          for (final img in images) img.toAnthropicImageBlock(),
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
