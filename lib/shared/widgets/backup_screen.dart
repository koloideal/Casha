import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/haptic_service.dart';
import '../providers/backup_provider.dart';
import '../providers/google_drive_provider.dart';
import '../providers/premium_provider.dart';
import 'error_snackbar.dart';
import '../services/backup_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _backingUp = false;
  bool _restoring = false;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
  }

  Future<void> _loadLastBackupTime() async {
    final service = ref.read(googleDriveServiceProvider);
    final time = await service.getLastBackupTime();
    if (mounted) {
      setState(() => _lastBackupTime = time);
    }
  }

  Future<void> _handleBackup() async {
    final s = ref.read(stringsProvider);
    final driveService = ref.read(googleDriveServiceProvider);

    if (driveService.currentUser == null) {
      showErrorSnackbar(context, s.backupRequiresSignIn);
      return;
    }

    HapticService.light();
    setState(() => _backingUp = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final payload = <String, dynamic>{
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
      };
      final data = backupService.createBackup(payload);
      final result = await driveService.uploadBackup(data);

      if (result.success) {
        setState(() => _lastBackupTime = result.modifiedTime);
        HapticService.medium();
        if (mounted) {
          showSuccessSnackbar(context, s.backupSuccess);
        }
      } else {
        if (mounted) {
          showErrorSnackbar(context, result.error ?? s.backupRestoreFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _handleRestore() async {
    final s = ref.read(stringsProvider);
    final driveService = ref.read(googleDriveServiceProvider);

    if (driveService.currentUser == null) {
      showErrorSnackbar(context, s.backupRequiresSignIn);
      return;
    }

    HapticService.light();
    setState(() => _restoring = true);

    try {
      final raw = await driveService.downloadBackup();
      if (raw == null) {
        if (mounted) {
          showWarningSnackbar(context, s.backupNoFileFound);
        }
        return;
      }

      final backupService = ref.read(backupServiceProvider);
      final (result, data) = backupService.verifyAndParse(raw);

      switch (result) {
        case BackupVerifyResult.ok:
          HapticService.medium();
          if (mounted) {
            showSuccessSnackbar(context, s.backupRestoreSuccess);
          }
        case BackupVerifyResult.tokenMismatch:
          if (mounted) {
            showErrorSnackbar(context, s.backupTokenMismatch);
          }
        case BackupVerifyResult.noToken:
          if (mounted) {
            showErrorSnackbar(context, s.backupNoToken);
          }
        case BackupVerifyResult.invalidFormat:
          if (mounted) {
            showErrorSnackbar(context, s.backupInvalidFormat);
          }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final driveUserAsync = ref.watch(googleDriveUserProvider);
    final driveUser = driveUserAsync.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    s.backupTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isPremium) ...[
                      _buildLockedState(context, s, colorScheme),
                    ] else ...[
                      _buildSyncStatus(context, s, colorScheme, driveUser),
                      const SizedBox(height: 20),
                      _buildBackupActions(context, s, colorScheme, driveUser),
                      const SizedBox(height: 20),
                      _buildLastBackup(context, s, colorScheme),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline_rounded, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            s.backupRequiresPremium,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/pro'),
            child: Text(s.proBuy),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
    dynamic driveUser,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                driveUser != null
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                color: driveUser != null ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  driveUser != null
                      ? s.proSyncEnabled
                      : s.backupRequiresSignIn,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (driveUser != null) ...[
            const SizedBox(height: 8),
            Text(
              driveUser.email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupActions(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
    dynamic driveUser,
  ) {
    final disabled = driveUser == null;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (disabled || _backingUp) ? null : _handleBackup,
            icon: _backingUp
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.backup_outlined),
            label: Text(_backingUp ? s.backupCreating : s.backupCreate),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (disabled || _restoring) ? null : _handleRestore,
            icon: _restoring
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.restore_rounded),
            label: Text(_restoring ? s.backupRestoring : s.backupRestore),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastBackup(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 18,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          '${s.backupLastBackup}: ${_lastBackupTime != null ? _formatDate(_lastBackupTime!) : s.backupNever}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
