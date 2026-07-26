import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'vault_codec.dart';

/// Persists the vault: the AES key lives in the Android Keystore (via
/// flutter_secure_storage), the encrypted records live in app-private storage.
/// Nothing leaves the device.
class VaultStore {
  static const _keyName = 'picsearch_vault_key_v1';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<VaultCodec> _codec() async {
    var b64 = await _secure.read(key: _keyName);
    if (b64 == null) {
      b64 = Key.fromSecureRandom(32).base64; // AES-256, generated once
      await _secure.write(key: _keyName, value: b64);
    }
    return VaultCodec(Key.fromBase64(b64));
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/vault.enc');
  }

  Future<List<ScreenshotRecord>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final codec = await _codec();
      return codec.decode(await f.readAsBytes());
    } catch (_) {
      // Corrupt/undecryptable file → start clean rather than crash.
      return [];
    }
  }

  Future<void> save(List<ScreenshotRecord> records) async {
    final codec = await _codec();
    final f = await _file();
    await f.writeAsBytes(codec.encode(records), flush: true);
  }

  // --- BYOK Gemini key (also Keystore-held) ---
  static const _geminiKeyName = 'picsearch_gemini_key';

  Future<String?> geminiKey() => _secure.read(key: _geminiKeyName);

  Future<void> setGeminiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _secure.delete(key: _geminiKeyName);
    } else {
      await _secure.write(key: _geminiKeyName, value: key.trim());
    }
  }
}
