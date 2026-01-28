import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageProvider {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  // Boolean operations
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs!.getBool(key);
  }

  // Integer operations
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  int? getInt(String key) {
    _ensureInitialized();
    return _prefs!.getInt(key);
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    _ensureInitialized();
    return await _prefs!.setDouble(key, value);
  }

  double? getDouble(String key) {
    _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  // String List operations
  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _prefs!.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  // JSON operations
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final value = getString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Remove operations
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs!.remove(key);
  }

  Future<bool> clear() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }

  // Check operations
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    _ensureInitialized();
    return _prefs!.getKeys();
  }

  void _ensureInitialized() {
    if (_prefs == null) {
      throw StateError('StorageProvider not initialized. Call init() first.');
    }
  }

  void dispose() {
    _prefs = null;
  }

  // ==================== APP-SPECIFIC STORAGE METHODS ====================

  // Storage keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDefaultModelId = 'default_model_id';
  static const String _keyDefaultModelName = 'default_model_name';
  static const String _keyActiveWorkspaceId = 'active_workspace_id';
  static const String _keyLanguage = 'language';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingMode = 'onboarding_mode';

  // Theme preferences
  Future<bool> setThemeMode(String mode) async {
    return await setString(_keyThemeMode, mode);
  }

  String? getThemeMode() {
    return getString(_keyThemeMode);
  }

  // Default model preferences
  Future<bool> setDefaultModel(String modelId, String modelName) async {
    final success1 = await setString(_keyDefaultModelId, modelId);
    final success2 = await setString(_keyDefaultModelName, modelName);
    return success1 && success2;
  }

  String? getDefaultModelId() {
    return getString(_keyDefaultModelId);
  }

  String? getDefaultModelName() {
    return getString(_keyDefaultModelName);
  }

  // Workspace preferences
  Future<bool> setActiveWorkspace(String workspaceId) async {
    return await setString(_keyActiveWorkspaceId, workspaceId);
  }

  String? getActiveWorkspaceId() {
    return getString(_keyActiveWorkspaceId);
  }

  Future<bool> clearActiveWorkspace() async {
    return await remove(_keyActiveWorkspaceId);
  }

  // Language preferences
  Future<bool> setLanguage(String languageCode) async {
    return await setString(_keyLanguage, languageCode);
  }

  String? getLanguage() {
    return getString(_keyLanguage);
  }

  // Onboarding completion
  Future<bool> setOnboardingCompleted(bool completed) async {
    return await setBool(_keyOnboardingCompleted, completed);
  }

  bool isOnboardingCompleted() {
    return getBool(_keyOnboardingCompleted) ?? false;
  }

  // Onboarding mode
  Future<bool> setOnboardingMode(String mode) async {
    return await setString(_keyOnboardingMode, mode);
  }

  String? getOnboardingMode() {
    return getString(_keyOnboardingMode);
  }

  // Clear all app-specific preferences (keeps SharedPreferences for other uses)
  Future<void> clearAppPreferences() async {
    await remove(_keyThemeMode);
    await remove(_keyDefaultModelId);
    await remove(_keyDefaultModelName);
    await remove(_keyActiveWorkspaceId);
    await remove(_keyLanguage);
    await remove(_keyOnboardingCompleted);
    await remove(_keyOnboardingMode);
  }
}
