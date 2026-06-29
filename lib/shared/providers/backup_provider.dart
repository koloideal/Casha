import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';
import 'premium_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final token = ref.watch(purchaseTokenProvider) ?? '';
  return BackupService(token);
});
