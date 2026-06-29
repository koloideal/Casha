import 'dart:convert';
import 'dart:typed_data';

class BackupData {
  final String ownerPurchaseToken;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const BackupData({
    required this.ownerPurchaseToken,
    required this.createdAt,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'owner_purchase_token': ownerPurchaseToken,
        'created_at': createdAt.toIso8601String(),
        'payload': payload,
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      ownerPurchaseToken: json['owner_purchase_token'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }
}

enum BackupVerifyResult { ok, tokenMismatch, noToken, invalidFormat }

class BackupService {
  String _currentPurchaseToken;

  BackupService(this._currentPurchaseToken);

  void updatePurchaseToken(String token) {
    _currentPurchaseToken = token;
  }

  String get currentPurchaseToken => _currentPurchaseToken;

  Uint8List createBackup(Map<String, dynamic> payload) {
    final data = BackupData(
      ownerPurchaseToken: _currentPurchaseToken,
      createdAt: DateTime.now(),
      payload: payload,
    );
    final json = jsonEncode(data.toJson());
    return Uint8List.fromList(utf8.encode(json));
  }

  (BackupVerifyResult, BackupData?) verifyAndParse(Uint8List raw) {
    try {
      final json = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      final data = BackupData.fromJson(json);

      if (data.ownerPurchaseToken.isEmpty) {
        return (BackupVerifyResult.noToken, null);
      }

      if (data.ownerPurchaseToken != _currentPurchaseToken) {
        return (BackupVerifyResult.tokenMismatch, null);
      }

      return (BackupVerifyResult.ok, data);
    } catch (e) {
      return (BackupVerifyResult.invalidFormat, null);
    }
  }
}
