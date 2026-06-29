import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/haptic_service.dart';
import '../feature_flags/feature_flags_provider.dart';
import '../models/user_model.dart';
import '../providers/billing_provider.dart';
import '../providers/current_user_provider.dart';
import '../providers/google_auth_provider.dart';
import 'error_snackbar.dart';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen>
    with SingleTickerProviderStateMixin {
  bool _purchasing = false;
  bool _restoring = false;
  bool _showSuccess = false;
  late final AnimationController _successController;
  late final Animation<double> _successScale;

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
  ];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  void _showSuccessOverlay() {
    setState(() => _showSuccess = true);
    _successController.forward(from: 0.0);
  }

  void _dismissSuccessOverlay() {
    _successController.stop();
    if (mounted) {
      setState(() => _showSuccess = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final flags = ref.watch(featureFlagsProvider);
    final isVip = flags.maxAccounts != 3;
    final googleUserAsync = ref.watch(googleCurrentUserProvider);
    final googleUser = googleUserAsync.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, s, colorScheme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildHeroBanner(context, s, colorScheme, isVip),
                        const SizedBox(height: 20),
                        _buildFeatureList(context, s, colorScheme),
                        const SizedBox(height: 16),
                        if (isVip) ...[
                          _buildProActiveSection(context, s, colorScheme, googleUser),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(context, s, colorScheme, isVip),
              ],
            ),
          ),
        ),
        if (_showSuccess) _buildSuccessOverlay(context, s, colorScheme),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
    bool isVip,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.proTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isVip ? s.proActive : s.proSubtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: isVip ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: _dismissSuccessOverlay,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: _dismissSuccessOverlay,
            child: AnimatedBuilder(
              animation: _successController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _successScale.value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.primary,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      s.proPurchaseSuccess,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.proTapToClose,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
  ) {
    final features = [
      (Icons.cloud_sync_rounded, s.proFeatureCloudSync, s.proFeatureCloudSyncDesc),
      (Icons.analytics_rounded, s.proFeatureAnalytics, s.proFeatureAnalyticsDesc),
      (Icons.palette_rounded, s.proFeatureCustomization, s.proFeatureCustomizationDesc),
      (Icons.fingerprint_rounded, s.proFeatureBiometric, s.proFeatureBiometricDesc),
      (Icons.account_balance_wallet_rounded, s.proFeatureAccounts, s.proFeatureAccountsDesc),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  f.$1,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$2,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.$3,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProActiveSection(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
    dynamic googleUser,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (googleUser != null) ...[
            Row(
              children: [
                Icon(Icons.email_outlined, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    googleUser.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.sync_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.proSyncEnabled,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.backup_outlined, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  '${s.proLastBackup}: —',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleGoogleSignOut,
                    icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                    label: Text(s.proSignOut),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              s.proSignInForSync,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: Icon(Icons.login_rounded, color: colorScheme.primary),
                label: Text(s.proSignInGoogle),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    AppStrings s,
    ColorScheme colorScheme,
    bool isVip,
  ) {
    if (isVip) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _purchasing ? null : _handlePurchase,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _purchasing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      s.proBuy,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _restoring ? null : _handleRestore,
              child: _restoring
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Text(s.proRestorePurchases),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    HapticService.light();
    setState(() => _purchasing = true);
    try {
      final billing = ref.read(billingServiceProvider);
      final success = await billing.purchasePro();
      if (success) {
        await ref.read(currentUserProvider.notifier).setPlan(UserPlan.vip);
        if (mounted) {
          _showSuccessOverlay();
          HapticService.medium();
        }
      } else {
        if (mounted) {
          showErrorSnackbar(context, ref.read(stringsProvider).proPurchaseFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _handleRestore() async {
    HapticService.light();
    setState(() => _restoring = true);
    try {
      final billing = ref.read(billingServiceProvider);
      final success = await billing.restorePurchases();
      if (success) {
        await ref.read(currentUserProvider.notifier).setPlan(UserPlan.vip);
        if (mounted) {
          _showSuccessOverlay();
          HapticService.medium();
        }
      } else {
        if (mounted) {
          showWarningSnackbar(context, ref.read(stringsProvider).proRestoreNotFound);
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

  Future<void> _handleGoogleSignIn() async {
    HapticService.light();
    try {
      final service = ref.read(googleAuthProvider);
      await service.signIn();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    }
  }

  Future<void> _handleGoogleSignOut() async {
    HapticService.light();
    try {
      final service = ref.read(googleAuthProvider);
      await service.signOut();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    }
  }
}
