import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/services/card_color_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/models/account.dart';
import '../../provider.dart';
import './panel_tab.dart';
import './utils.dart' as utils;

class AccountColorPanel extends StatelessWidget {
  final dynamic dashboardState;
  final BuildContext dashboardContext;
  final double panelHeight;
  final bool Function(List<Account>, String) isDuplicateName;
  final VoidCallback onDuplicateError;

  const AccountColorPanel({
    super.key,
    required this.dashboardState,
    required this.dashboardContext,
    required this.panelHeight,
    required this.isDuplicateName,
    required this.onDuplicateError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: panelHeight,
      decoration: BoxDecoration(
        color: Theme.of(dashboardContext).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            dashboardContext,
          ).colorScheme.onSurface.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: StatefulBuilder(
        builder: (ctx, setPanelState) {
          final s = AppStrings(
            ProviderScope.containerOf(dashboardContext).read(localeProvider),
          );

          void onHSVChanged(HSVColor hsv) {
            setPanelState(() {});
            dashboardState.setState(() {
              if (dashboardState.editingPrimary) {
                dashboardState.tempPrimaryHSV = hsv;
                dashboardState.tempPrimary = hsv.toColor();
              } else {
                dashboardState.tempSecondaryHSV = hsv;
                dashboardState.tempSecondary = hsv.toColor();
              }
            });
            dashboardState.overlayEntry?.markNeedsBuild();
          }

          final activeGradientType =
              Theme.of(dashboardContext).brightness == Brightness.dark
                  ? dashboardState.tempDarkGradientType
                  : dashboardState.tempLightGradientType;
          final isSolid = activeGradientType == GradientType.solid;
          final currentHSV = (isSolid || dashboardState.editingPrimary)
              ? dashboardState.tempPrimaryHSV
              : dashboardState.tempSecondaryHSV;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: PanelTab(
                          label: s.colorPrimary,
                          isSelected:
                              dashboardState.editingPrimary && !isSolid,
                          color: isSolid
                              ? Theme.of(dashboardContext)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.12)
                              : dashboardState.tempPrimary,
                          isDimmed: isSolid,
                          onTap: () {
                            dashboardState.setState(() {
                              if (isSolid)
                                if (Theme.of(dashboardContext).brightness ==
                                    Brightness.dark) {
                                  dashboardState.tempDarkGradientType =
                                      CardColorService.defaultGradientDark;
                                } else {
                                  dashboardState.tempLightGradientType =
                                      CardColorService.defaultGradientLight;
                                }
                              dashboardState.editingPrimary = true;
                            });
                            setPanelState(() {});
                            dashboardState.overlayEntry?.markNeedsBuild();
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: PanelTab(
                          label: s.colorSecondary,
                          isSelected:
                              !dashboardState.editingPrimary && !isSolid,
                          color: dashboardState.tempSecondary,
                          isDimmed: isSolid,
                          onTap: () {
                            dashboardState.setState(() {
                              if (isSolid)
                                if (Theme.of(dashboardContext).brightness ==
                                    Brightness.dark) {
                                  dashboardState.tempDarkGradientType =
                                      CardColorService.defaultGradientDark;
                                } else {
                                  dashboardState.tempLightGradientType =
                                      CardColorService.defaultGradientLight;
                                }
                              dashboardState.editingPrimary = false;
                            });
                            setPanelState(() {});
                            dashboardState.overlayEntry?.markNeedsBuild();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 1,
                          color: Theme.of(
                            dashboardContext,
                          ).colorScheme.onSurface.withOpacity(0.15),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: isSolid
                              ? null
                              : () {
                                  dashboardState.setState(() {
                                    if (Theme.of(dashboardContext).brightness ==
                                        Brightness.dark) {
                                      dashboardState.tempDarkGradientType =
                                          GradientType.solid;
                                    } else {
                                      dashboardState.tempLightGradientType =
                                          GradientType.solid;
                                    }
                                    dashboardState.editingPrimary = true;
                                  });
                                  setPanelState(() {});
                                  dashboardState.overlayEntry?.markNeedsBuild();
                                },
                          child: Container(
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSolid
                                  ? const Color(0xFF7C6DED).withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSolid
                                    ? const Color(0xFF7C6DED)
                                    : Theme.of(
                                        dashboardContext,
                                      ).colorScheme.onSurface.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: dashboardState.tempPrimary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(dashboardContext)
                                                  .brightness ==
                                              Brightness.dark
                                          ? Colors.white30
                                          : Colors.black12,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    s.colorSolid,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSolid
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSolid
                                          ? const Color(0xFF7C6DED)
                                          : Theme.of(dashboardContext)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (lbCtx, constraints) {
                      const reservedBelow = 78.0;
                      final spectrumH = (constraints.maxHeight - reservedBelow)
                          .clamp(40.0, double.infinity);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: spectrumH,
                              child: ColorPickerArea(
                                currentHSV,
                                onHSVChanged,
                                PaletteType.hsvWithHue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 36,
                            child: ColorPickerSlider(
                              TrackType.hue,
                              currentHSV,
                              onHSVChanged,
                              displayThumbColor: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          IgnorePointer(
                            ignoring: isSolid,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isSolid ? 0.4 : 1.0,
                              child: SizedBox(
                                height: 26,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        dashboardState.setState(
                                          () => dashboardState.editingPrimary =
                                              true,
                                        );
                                        setPanelState(() {});
                                        dashboardState.overlayEntry
                                            ?.markNeedsBuild();
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: dashboardState.tempPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border:
                                                  dashboardState.editingPrimary
                                                  ? Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    )
                                                  : Border.all(
                                                      color: Colors.transparent,
                                                      width: 2,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '#${utils.colorToHex(dashboardState.tempPrimary)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              fontWeight:
                                                  dashboardState.editingPrimary
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: Theme.of(dashboardContext)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(
                                                    dashboardState
                                                            .editingPrimary
                                                        ? 0.8
                                                        : 0.4,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!isSolid)
                                      GestureDetector(
                                        onTap: () {
                                          dashboardState.setState(
                                            () =>
                                                dashboardState.editingPrimary =
                                                    false,
                                          );
                                          setPanelState(() {});
                                          dashboardState.overlayEntry
                                              ?.markNeedsBuild();
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '#${utils.colorToHex(dashboardState.tempSecondary)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                                fontWeight:
                                                    !dashboardState
                                                        .editingPrimary
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: Theme.of(dashboardContext)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(
                                                      !dashboardState
                                                              .editingPrimary
                                                          ? 0.8
                                                          : 0.4,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: dashboardState
                                                    .tempSecondary,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border:
                                                    !dashboardState
                                                        .editingPrimary
                                                    ? Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      )
                                                    : Border.all(
                                                        color:
                                                            Colors.transparent,
                                                        width: 2,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                IgnorePointer(
                  ignoring: isSolid,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSolid ? 0.3 : 1.0,
                    child: Row(
                      children: GradientType.values
                          .where((t) => t != GradientType.solid)
                          .map((type) {
                            final isSelected = activeGradientType == type;
                            final label = switch (type) {
                              GradientType.linear => s.gradientLinear,
                              GradientType.linearReverse => s.gradientReverse,
                              GradientType.radial => s.gradientRadial,
                              GradientType.sweep => s.gradientSweep,
                              GradientType.solid => '',
                            };
                            final icon = switch (type) {
                              GradientType.linear =>
                                Icons.trending_flat_rounded,
                              GradientType.linearReverse =>
                                Icons.swap_horiz_rounded,
                              GradientType.radial =>
                                Icons.blur_circular_rounded,
                              GradientType.sweep => Icons.rotate_right_rounded,
                              GradientType.solid => Icons.square_rounded,
                            };
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () {
                                    dashboardState.setState(
                                      () {
                                        if (Theme.of(dashboardContext)
                                                .brightness ==
                                            Brightness.dark) {
                                          dashboardState.tempDarkGradientType =
                                              type;
                                        } else {
                                          dashboardState.tempLightGradientType =
                                              type;
                                        }
                                      },
                                    );
                                    setPanelState(() {});
                                    dashboardState.overlayEntry
                                        ?.markNeedsBuild();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF7C6DED,
                                            ).withOpacity(0.15)
                                          : Theme.of(dashboardContext)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF7C6DED)
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 15,
                                          color: isSelected
                                              ? const Color(0xFF7C6DED)
                                              : Theme.of(dashboardContext)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.45),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? const Color(0xFF7C6DED)
                                                : Theme.of(dashboardContext)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final isDarkTheme =
                              Theme.of(dashboardContext).brightness ==
                              Brightness.dark;
                          final defP = isDarkTheme
                              ? CardColorService.defaultPrimary
                              : CardColorService.defaultPrimaryLight;
                          final defS = isDarkTheme
                              ? CardColorService.defaultSecondary
                              : CardColorService.defaultSecondaryLight;
                          dashboardState.setState(() {
                            dashboardState.tempPrimary = defP;
                            dashboardState.tempSecondary = defS;
                            dashboardState.tempPrimaryHSV = HSVColor.fromColor(
                              defP,
                            );
                            dashboardState.tempSecondaryHSV =
                                HSVColor.fromColor(defS);
                          dashboardState.tempLightGradientType =
                              CardColorService.defaultGradientLight;
                          dashboardState.tempDarkGradientType =
                              CardColorService.defaultGradientDark;
                          });
                          setPanelState(() {});
                          dashboardState.overlayEntry?.markNeedsBuild();
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 15),
                        label: Text(
                          s.reset,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            dashboardContext,
                          ).colorScheme.onSurface.withOpacity(0.7),
                          side: BorderSide(
                            color: Theme.of(
                              dashboardContext,
                            ).colorScheme.onSurface.withOpacity(0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Consumer(
                        builder: (context, ref, _) {
                          return ElevatedButton(
                            onPressed:
                                dashboardState.tempAccountName.trim().isEmpty
                                ? null
                                : () {
                                    final accounts =
                                        ProviderScope.containerOf(
                                          dashboardContext,
                                        ).read(accountsProvider).valueOrNull ??
                                        [];

                                    if (isDuplicateName(
                                      accounts,
                                      dashboardState.tempAccountName,
                                    )) {
                                      onDuplicateError();
                                      return;
                                    }

                                    HapticService.light();
                                    dashboardState.closeAccountOverlay(
                                      apply: true,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C6DED),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Theme.of(
                                dashboardContext,
                              ).colorScheme.onSurface.withOpacity(0.12),
                              disabledForegroundColor: Theme.of(
                                dashboardContext,
                              ).colorScheme.onSurface.withOpacity(0.38),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              dashboardState.isAddingAccount
                                  ? s.addAccount
                                  : s.apply,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
