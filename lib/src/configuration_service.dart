import 'package:shared_preferences/shared_preferences.dart';

abstract class IConfigurationService {
  Future<void> setMnemonic(String? value);
  Future<void> setupDone(bool value);
  Future<void> setWIF(String? value);
  Future<void> setPIN(String? value);
  Future<void> setFingerprint(bool value);
  String? getMnemonic();
  String? getWIF();
  String? getPIN();
  bool getFingerprint();
  bool didSetupWallet();
}

class ConfigurationService implements IConfigurationService {
  const ConfigurationService(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<void> setMnemonic(String? value) async {
    await _preferences.setString('mnemonic', value ?? '');
  }

  @override
  Future<void> setWIF(String? value) async {
    await _preferences.setString('WIF', value ?? '');
  }

  @override
  Future<void> setPIN(String? value) async {
    await _preferences.setString('PIN', value ?? '');
  }

  @override
  Future<void> setFingerprint(bool value) async {
    await _preferences.setBool('fingerprint', value);
  }

  @override
  Future<void> setupDone(bool value) async {
    await _preferences.setBool('didSetupWallet', value);
  }

  // gets
  @override
  String? getMnemonic() {
    return _preferences.getString('mnemonic');
  }

  @override
  String? getWIF() {
    return _preferences.getString('WIF');
  }

  @override
  String? getPIN() {
    return _preferences.getString('PIN');
  }

  @override
  bool getFingerprint() {
    return _preferences.getBool('fingerprint') ?? false;
  }

  @override
  bool didSetupWallet() {
    return _preferences.getBool('didSetupWallet') ?? false;
  }
}
