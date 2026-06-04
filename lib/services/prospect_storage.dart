import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] for prospectId and bankerId persistence.
class ProspectStorage {
  static const _prospectIdKey = 'launchpad_prospect_id';
  static const _bankerIdKey = 'launchpad_active_banker_id';

  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'launchpad_secure', publicKey: 'launchpad_key'),
  );

  /// Persist [prospectId] to secure storage.
  Future<void> saveProspectId(String prospectId) async {
    await _storage.write(key: _prospectIdKey, value: prospectId);
  }

  /// Returns the stored prospectId, or `null` if none is saved.
  Future<String?> getProspectId() async {
    return _storage.read(key: _prospectIdKey);
  }

  /// Removes the stored prospectId.
  Future<void> clearProspectId() async {
    await _storage.delete(key: _prospectIdKey);
  }

  /// Persist [bankerId] to secure storage.
  Future<void> saveActiveBankerId(String bankerId) async {
    await _storage.write(key: _bankerIdKey, value: bankerId);
  }

  /// Returns the stored bankerId, or `null` if none is saved.
  Future<String?> getActiveBankerId() async {
    return _storage.read(key: _bankerIdKey);
  }

  /// Removes the stored bankerId.
  Future<void> clearActiveBankerId() async {
    await _storage.delete(key: _bankerIdKey);
  }
}
