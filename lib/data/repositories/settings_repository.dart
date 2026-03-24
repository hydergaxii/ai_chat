import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kProvider = 'provider';
const _kTheme = 'theme';
const _kMode = 'mode';
const _kTemp = 'temperature';
const _kMaxTokens = 'max_tokens';
const _kModel = 'model';
const _kSystemPrompt = 'system_prompt';
const _kActiveChatId = 'active_chat_id';
const _kOrApiKey = 'or_api_key';
const _kAnthropicApiKey = 'anthropic_api_key';

class SettingsRepository {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  SettingsRepository(this._prefs)
      : _secure = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  // Provider
  String get provider => _prefs.getString(_kProvider) ?? 'openrouter';
  Future<void> setProvider(String v) => _prefs.setString(_kProvider, v);

  // Theme
  String get theme => _prefs.getString(_kTheme) ?? 'dark';
  Future<void> setTheme(String v) => _prefs.setString(_kTheme, v);

  // Mode (auto / manual)
  String get mode => _prefs.getString(_kMode) ?? 'auto';
  Future<void> setMode(String v) => _prefs.setString(_kMode, v);

  // Temperature
  double get temperature => _prefs.getDouble(_kTemp) ?? 0.7;
  Future<void> setTemperature(double v) => _prefs.setDouble(_kTemp, v);

  // Max tokens
  int get maxTokens => _prefs.getInt(_kMaxTokens) ?? 8192;
  Future<void> setMaxTokens(int v) => _prefs.setInt(_kMaxTokens, v);

  // Model
  String get model =>
      _prefs.getString(_kModel) ?? 'anthropic/claude-sonnet-4-6';
  Future<void> setModel(String v) => _prefs.setString(_kModel, v);

  // System prompt
  String get systemPrompt => _prefs.getString(_kSystemPrompt) ?? '';
  Future<void> setSystemPrompt(String v) =>
      _prefs.setString(_kSystemPrompt, v);

  // Active chat
  String? get activeChatId => _prefs.getString(_kActiveChatId);
  Future<void> setActiveChatId(String? v) => v != null
      ? _prefs.setString(_kActiveChatId, v)
      : _prefs.remove(_kActiveChatId);

  // Secure: OpenRouter API key
  Future<String?> getOrApiKey() => _secure.read(key: _kOrApiKey);
  Future<void> setOrApiKey(String v) => _secure.write(key: _kOrApiKey, value: v);
  Future<void> deleteOrApiKey() => _secure.delete(key: _kOrApiKey);

  // Secure: Anthropic API key
  Future<String?> getAnthropicApiKey() =>
      _secure.read(key: _kAnthropicApiKey);
  Future<void> setAnthropicApiKey(String v) =>
      _secure.write(key: _kAnthropicApiKey, value: v);
  Future<void> deleteAnthropicApiKey() =>
      _secure.delete(key: _kAnthropicApiKey);
}
