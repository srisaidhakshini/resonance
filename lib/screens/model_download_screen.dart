import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/download_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/echo_intro_widget.dart';
import '../widgets/mascot_widget.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  Future<void> _showExitDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        title: Text(
          'Exit Setup?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'The AI model setup is required for 100% offline learning. Are you sure you want to stop?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();
            },
            child: Text(
              'Exit',
              style: TextStyle(color: AppColors.lightDestructive),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(downloadProgressProvider);
    final isDownloading = ref.watch(isDownloadingProvider);
    final error = ref.watch(downloadErrorProvider);
    final isReady = ref.watch(isModelReadyProvider);
    final speed = ref.watch(downloadSpeedProvider);
    final downloadedBytes = ref.watch(downloadedBytesProvider);
    final totalBytes = ref.watch(totalBytesProvider);
    final phaseLabel = ref.watch(downloadPhaseLabelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isReady && !isDownloading && error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/profile_setup');
      });
    }

    String formatBytes(int bytes) {
      if (bytes <= 0) return "0 MB";
      const int mb = 1024 * 1024;
      return "${(bytes / mb).toStringAsFixed(1)}MB";
    }

    // While setup is still in progress, loop the "Sprite jumps into the
    // logo" cinematic as a booting animation; once we land on a terminal
    // state (ready or errored), swap to the reactive mascot to react to it.
    final setupInProgress = !isReady && error == null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive mascot size keeps the layout from ever needing more
            // vertical space than the screen actually has.
            final mascotSize = (constraints.maxHeight * 0.26).clamp(
              120.0,
              220.0,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                // Guarantees the action button still pins to the bottom on
                // tall screens, while letting the column grow (and this
                // scroll view take over) instead of overflowing on short
                // ones — the animation's varying frame sizes can no longer
                // trigger a RenderFlex overflow.
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkForeground
                                : AppColors.lightForeground,
                          ),
                          onPressed: _showExitDialog,
                        ),
                      ),
                      Text(
                        'AI MODEL SETUP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.lightMutedForeground,
                        ),
                      ),
                      const SizedBox(height: 20),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: setupInProgress
                            ? EchoIntroWidget(
                                key: const ValueKey('intro'),
                                size: mascotSize,
                                loop: true,
                              )
                            : MascotWidget(
                                key: const ValueKey('reactive'),
                                state: error != null
                                    ? MascotState.wrong
                                    : MascotState.correct,
                                size: mascotSize,
                              ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        error != null
                            ? 'Oops, that hiccuped!'
                            : (isReady
                                  ? "You're all set!"
                                  : (isDownloading
                                        ? 'Sprite is fetching your tutor...'
                                        : 'One-Time Offline Setup')),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.lightForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error != null
                            ? 'Something went wrong during the download. Give it another try below.'
                            : (isReady
                                  ? 'The AI model is ready on your device. Taking you to your profile...'
                                  : 'Downloading the on-device AI model weights so Echo can tutor you 100% offline with zero latency.'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.lightMutedForeground,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Progress Section Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: AppRadii.cardRadius,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 1,
                          ),
                          boxShadow: isDark
                              ? AppShadows.darkCard
                              : AppShadows.card,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isDownloading
                                      ? (phaseLabel.isNotEmpty
                                            ? 'Downloading $phaseLabel...'
                                            : 'Downloading AI Weights...')
                                      : (isReady
                                            ? 'Model Ready'
                                            : 'Ready to Download'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkForeground
                                        : AppColors.lightForeground,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.lightTeal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress > 0 ? progress : null,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.lightTeal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${formatBytes(downloadedBytes)} / ${formatBytes(totalBytes)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkMutedForeground
                                        : AppColors.lightMutedForeground,
                                  ),
                                ),
                                if (speed.isNotEmpty)
                                  Text(
                                    speed,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightTeal,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightDestructive.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: AppRadii.cardRadius,
                          ),
                          child: Text(
                            error,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.lightDestructive,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Action button
                      if (!isDownloading && !isReady) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(downloadControllerProvider.notifier)
                                  .startDownload();
                            },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text(
                              'Download Offline Model (~900MB)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/profile_setup',
                            );
                          },
                          child: Text(
                            'Skip for now (Use Mock AI engine)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.lightMutedForeground,
                            ),
                          ),
                        ),
                      ] else if (isDownloading) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(downloadControllerProvider.notifier)
                                  .cancelDownload();
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Cancel Download'),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
