import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'conversation_service.dart';

/// Wraps [FlutterSecureStorage] for prospectId and bankerId persistence.
class ProspectStorage {
  static const _prospectIdKey = 'launchpad_prospect_id';
  static const _bankerIdKey = 'launchpad_active_banker_id';
  static const _bankerJsonKey = 'launchpad_active_banker_json';

  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'launchpad_secure', publicKey: 'launchpad_key'),
  );

  /// Persist [prospectId] to secure storage.
  Future<void> saveProspectId(String prospectId) async {
    try {
      html.window.localStorage[_prospectIdKey] = prospectId;
    } catch (_) {}
    await _storage.write(key: _prospectIdKey, value: prospectId);
  }

  /// Returns the stored prospectId, or `null` if none is saved.
  Future<String?> getProspectId() async {
    try {
      final val = html.window.localStorage[_prospectIdKey];
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return _storage.read(key: _prospectIdKey);
  }

  /// Removes the stored prospectId.
  Future<void> clearProspectId() async {
    try {
      html.window.localStorage.remove(_prospectIdKey);
    } catch (_) {}
    await _storage.delete(key: _prospectIdKey);
  }

  /// Persist [bankerId] to secure storage.
  Future<void> saveActiveBankerId(String bankerId) async {
    try {
      html.window.localStorage[_bankerIdKey] = bankerId;
    } catch (_) {}
    await _storage.write(key: _bankerIdKey, value: bankerId);
  }

  /// Returns the stored bankerId, or `null` if none is saved.
  Future<String?> getActiveBankerId() async {
    try {
      final val = html.window.localStorage[_bankerIdKey];
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return _storage.read(key: _bankerIdKey);
  }

  /// Removes the stored bankerId.
  Future<void> clearActiveBankerId() async {
    try {
      html.window.localStorage.remove(_bankerIdKey);
      html.window.localStorage.remove(_bankerJsonKey);
    } catch (_) {}
    await _storage.delete(key: _bankerIdKey);
  }

  /// Persist [banker] to local storage.
  void saveActiveBanker(Banker banker) {
    try {
      final map = {
        'banker_id': banker.bankerId,
        'email': banker.email,
        'name': banker.name,
        'position': banker.position,
      };
      html.window.localStorage[_bankerJsonKey] = jsonEncode(map);
      html.window.localStorage[_bankerIdKey] = banker.bankerId;
    } catch (_) {}
    // Also do secure storage write in background (async)
    _storage.write(key: _bankerIdKey, value: banker.bankerId);
  }

  /// Returns the stored banker, or `null` if none is saved.
  Banker? getActiveBankerSync() {
    try {
      final val = html.window.localStorage[_bankerJsonKey];
      if (val != null && val.isNotEmpty) {
        final map = jsonDecode(val) as Map<String, dynamic>;
        return Banker.fromJson(map);
      }
    } catch (_) {}
    return null;
  }
}

