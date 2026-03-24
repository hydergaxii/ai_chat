import '../data/models/message.dart';

abstract class AiService {
  /// Returns a stream of text chunks (delta tokens).
  /// Throws on error, completes on [DONE].
  Stream<String> streamChat({
    required List<Message> messages,
    required String model,
    required double temperature,
    required int maxTokens,
    String? systemPrompt,
    required String apiKey,
  });

  /// Fire-and-forget non-streaming call for short tasks (auto-title).
  Future<String> complete({
    required String prompt,
    required String model,
    required String apiKey,
    int maxTokens = 30,
  });

  /// Human-readable name shown in settings
  String get displayName;

  /// Provider identifier stored in settings
  String get providerId;
}
