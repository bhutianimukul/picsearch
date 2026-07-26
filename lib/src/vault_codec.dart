import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import 'models.dart';

/// Encrypts/decrypts the record list at rest. Pure Dart (pointycastle), so the
/// serialization + crypto round-trip is unit-testable with a fixed key — no
/// device, secure storage, or filesystem.
///
/// Wire format: [16-byte IV][AES-CBC ciphertext].
class VaultCodec {
  VaultCodec(this._key);
  final Key _key;

  // ponytail: AES-256-CBC gives confidentiality at rest, which is the point
  // (the file is already app-private). Switch to GCM if tamper-detection matters.
  Encrypter get _enc => Encrypter(AES(_key, mode: AESMode.cbc));

  Uint8List encode(List<ScreenshotRecord> records) {
    final json = jsonEncode(records.map((r) => r.toJson()).toList());
    final iv = IV.fromSecureRandom(16);
    final ct = _enc.encrypt(json, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...ct.bytes]);
  }

  List<ScreenshotRecord> decode(Uint8List bytes) {
    final iv = IV(Uint8List.fromList(bytes.sublist(0, 16)));
    final ct = Encrypted(Uint8List.fromList(bytes.sublist(16)));
    final json = _enc.decrypt(ct, iv: iv);
    final list = jsonDecode(json) as List;
    return list
        .map((e) => ScreenshotRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
