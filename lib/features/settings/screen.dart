import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/haptic_service.dart';
import '../dashboard/provider.dart';
import 'provider.dart';
import 'widgets/theme_section.dart';
import 'widgets/haptic_section.dart';
import 'widgets/language_section.dart';
import 'widgets/currency_section.dart';
import 'widgets/amount_format_section.dart';
import 'widgets/budget_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearDataConfirm),
        content: Text(s.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: Text(s.areYouSure),
                  content: Text(s.allTransactionsWillBeDeleted),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: Text(s.noKeepThem),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).clearAll();
                        Navigator.pop(ctx2);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.allTransactionsDeleted)),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE05C6B),
                      ),
                      child: Text(s.yesDeleteEverything),
                    ),
                  ],
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE05C6B),
            ),
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.settings,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              s.managePreferences,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const ThemeSection(),
          const SizedBox(height: 16),
          const HapticSection(),
          const SizedBox(height: 16),
          const _BiometricSection(),
          const LanguageSection(),
          const SizedBox(height: 16),
          const CurrencySection(),
          const SizedBox(height: 16),
          const AmountFormatSection(),
          const SizedBox(height: 16),
          const BudgetSection(),
          const SizedBox(height: 24),
          Text(
            s.dangerZone,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: const Color(0xFFE05C6B).withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmClearData(context, ref),
              icon: const Icon(Icons.delete_forever, color: Color(0xFFE05C6B)),
              label: Text(
                s.clearAllTransactions,
                style: const TextStyle(color: Color(0xFFE05C6B)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFFE05C6B).withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const _FooterWidget(),
          const SizedBox(height: 32),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FooterWidget extends StatelessWidget {
  const _FooterWidget();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.25);
    final emphasisColor = isDark
        ? Colors.white.withOpacity(0.35)
        : Colors.black.withOpacity(0.35);

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: baseColor),
          children: [
            TextSpan(
              text: 'casha',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: emphasisColor,
              ),
            ),
            const TextSpan(
              text: ' powered with ❤️ by ',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            TextSpan(
              text: 'kolo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: emphasisColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricSection extends ConsumerStatefulWidget {
  const _BiometricSection();

  @override
  ConsumerState<_BiometricSection> createState() => _BiometricSectionState();
}

class _BiometricSectionState extends ConsumerState<_BiometricSection> {
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future _load() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future _onToggle(bool val) async {
    if (val) {
      final ok = await BiometricService.authenticate();
      if (!ok) return;
      HapticService.light();
    }
    await BiometricService.setEnabled(val);
    if (mounted) setState(() => _enabled = val);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Visibility(
      visible: !_loading && _available,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: isDark
                  ? null
                  : Border.all(color: const Color(0xFFDDDDEE), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.biometricLock,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        s.requireFingerprint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enabled,
                  onChanged: _onToggle,
                  activeThumbColor: const Color(0xFF7C6DED),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
