import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/branding/branding_provider.dart';
import 'conversation_service.dart';

/// Wraps [FlutterSecureStorage] for prospectId and bankerId persistence.
class ProspectStorage {
  static const _legacyProspectIdKey = 'launchpad_prospect_id';
  static const _legacyBankerIdKey = 'launchpad_active_banker_id';
  static const _legacyBankerJsonKey = 'launchpad_active_banker_json';

  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'launchpad_secure', publicKey: 'launchpad_key'),
  );

  String _getProspectKey() => '${_legacyProspectIdKey}_$dynamicMyBankId';
  String _getBankerIdKey() => '${_legacyBankerIdKey}_$dynamicMyBankId';
  String _getBankerJsonKey() => '${_legacyBankerJsonKey}_$dynamicMyBankId';

  /// Persist [prospectId] to secure storage.
  Future<void> saveProspectId(String prospectId) async {
    final key = _getProspectKey();
    try {
      html.window.localStorage[key] = prospectId;
    } catch (_) {}
    await _storage.write(key: key, value: prospectId);
  }

  /// Returns the stored prospectId, or `null` if none is saved.
  Future<String?> getProspectId() async {
    final key = _getProspectKey();
    try {
      // 1. Try bank-specific local storage key
      final val = html.window.localStorage[key];
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}

    // 2. Try bank-specific secure storage
    final secVal = await _storage.read(key: key);
    if (secVal != null && secVal.isNotEmpty) return secVal;

    // 3. Fallback: Check legacy key
    try {
      final legacyVal = html.window.localStorage[_legacyProspectIdKey];
      if (legacyVal != null && legacyVal.isNotEmpty) {
        // Only treat legacy session as belonging to JPMC
        if (dynamicMyBankId == dynamicJpmcId) {
          // Migrate legacy session to JPMC key
          await saveProspectId(legacyVal);
          return legacyVal;
        }
      }
    } catch (_) {}

    final legacySecVal = await _storage.read(key: _legacyProspectIdKey);
    if (legacySecVal != null && legacySecVal.isNotEmpty) {
      if (dynamicMyBankId == dynamicJpmcId) {
        await saveProspectId(legacySecVal);
        return legacySecVal;
      }
    }

    return null;
  }

  /// Removes the stored prospectId.
  Future<void> clearProspectId() async {
    final key = _getProspectKey();
    try {
      html.window.localStorage.remove(key);
      html.window.localStorage.remove(_legacyProspectIdKey);
    } catch (_) {}
    await _storage.delete(key: key);
    await _storage.delete(key: _legacyProspectIdKey);
  }

  /// Persist [bankerId] to secure storage.
  Future<void> saveActiveBankerId(String bankerId) async {
    final key = _getBankerIdKey();
    try {
      html.window.localStorage[key] = bankerId;
    } catch (_) {}
    await _storage.write(key: key, value: bankerId);
  }

  /// Returns the stored bankerId, or `null` if none is saved.
  Future<String?> getActiveBankerId() async {
    final key = _getBankerIdKey();
    try {
      final val = html.window.localStorage[key];
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}

    final secVal = await _storage.read(key: key);
    if (secVal != null && secVal.isNotEmpty) return secVal;

    // Fallback: Check legacy key
    try {
      final legacyVal = html.window.localStorage[_legacyBankerIdKey];
      if (legacyVal != null && legacyVal.isNotEmpty) {
        if (dynamicMyBankId == dynamicJpmcId) {
          await saveActiveBankerId(legacyVal);
          return legacyVal;
        }
      }
    } catch (_) {}

    final legacySecVal = await _storage.read(key: _legacyBankerIdKey);
    if (legacySecVal != null && legacySecVal.isNotEmpty) {
      if (dynamicMyBankId == dynamicJpmcId) {
        await saveActiveBankerId(legacySecVal);
        return legacySecVal;
      }
    }

    return null;
  }

  /// Removes the stored bankerId.
  Future<void> clearActiveBankerId() async {
    final idKey = _getBankerIdKey();
    final jsonKey = _getBankerJsonKey();
    try {
      html.window.localStorage.remove(idKey);
      html.window.localStorage.remove(jsonKey);
      html.window.localStorage.remove(_legacyBankerIdKey);
      html.window.localStorage.remove(_legacyBankerJsonKey);
    } catch (_) {}
    await _storage.delete(key: idKey);
    await _storage.delete(key: _legacyBankerIdKey);
  }

  /// Persist [banker] to local storage.
  void saveActiveBanker(Banker banker) {
    final idKey = _getBankerIdKey();
    final jsonKey = _getBankerJsonKey();
    try {
      final map = {
        'banker_id': banker.bankerId,
        'email': banker.email,
        'name': banker.name,
        'position': banker.position,
        'role': banker.role,
      };
      html.window.localStorage[jsonKey] = jsonEncode(map);
      html.window.localStorage[idKey] = banker.bankerId;
    } catch (_) {}
    _storage.write(key: idKey, value: banker.bankerId);
  }

  /// Returns the stored banker, or `null` if none is saved.
  Banker? getActiveBankerSync() {
    final jsonKey = _getBankerJsonKey();
    try {
      final val = html.window.localStorage[jsonKey];
      if (val != null && val.isNotEmpty) {
        final map = jsonDecode(val) as Map<String, dynamic>;
        return Banker.fromJson(map);
      }
    } catch (_) {}

    // Fallback: Check legacy key
    try {
      final legacyVal = html.window.localStorage[_legacyBankerJsonKey];
      if (legacyVal != null && legacyVal.isNotEmpty) {
        if (dynamicMyBankId == dynamicJpmcId) {
          final map = jsonDecode(legacyVal) as Map<String, dynamic>;
          final banker = Banker.fromJson(map);
          saveActiveBanker(banker);
          return banker;
        }
      }
    } catch (_) {}

    return null;
  }
}
