import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/study_content.dart';
import '../providers/chat_provider.dart';
import '../providers/content_provider.dart';
import '../services/video_script_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/mascot_widget.dart';
import 'video_overview_screen.dart';

const _kSamples = [
  ('assets/sample_content/photosynthesis.txt', 'Photosynthesis'),
  (
    'assets/sample_content/newtons_laws_of_motion.txt',
    "Newton's Laws of Motion",
  ),
];

class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  ConsumerState<ContentLibraryScreen> createState() =>
      _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {
  bool _isIngesting = false;

  Future<void> _pickAndIngest() async {
    final processor = ref.read(contentProcessorServiceProvider);
    final extensions = [
      'pdf',
      'txt',
      if (processor.supportsOcr) ...['jpg', 'jpeg', 'png'],
    ];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    await _runIngest(
      () => ref.read(contentNotifierProvider.notifier).ingestFile(result.files.first),
    );
  }

  Future<void> _ingestSample(String assetPath, String title) async {
    await _runIngest(
      () => ref
          .read(contentNotifierProvider.notifier)
          .ingestSampleAsset(assetPath, title),
    );
  }

  Future<void> _runIngest(Future<StudyContent> Function() run) async {
    setState(() => _isIngesting = true);
    try {
      final content = await run();
      if (!mounted) return;
      setState(() => _isIngesting = false);
      _activateAndOpenChat(content);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isIngesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _activateAndOpenChat(StudyContent content) {
    ref.read(chatProvider.notifier).startNewChat(contentId: content.id);
    Navigator.pushReplacementNamed(context, '/chat');
  }

  /// Generates a kinetic-typography video overview of an ingested chapter
  Future<void> _generateVideoOverview(StudyContent content) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotWidget(state: MascotState.thinking, size: 96),
              const SizedBox(height: 16),
              Text(
                'Generating Video Overview...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightForeground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Summarizing concepts and kinetic script with AI',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final script = await VideoScriptGenerator.generateFromStudyContent(
      content,
      ref.read(llmServiceProvider),
    );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading dialog
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoOverviewScreen(initialScript: script)),
    );
  }

  Future<void> _deleteContent(StudyContent content) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
          ),
        ),
        title: Text(
          'Remove Chapter',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.lightForeground,
          ),
        ),
        content: Text(
          'Remove "${content.title}"? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(contentNotifierProvider.notifier).deleteContent(content.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myChapters = ref.watch(contentNotifierProvider);

    final textPrimary = isDark ? Colors.white : AppColors.lightForeground;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.055) : Colors.white.withValues(alpha: 0.90);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: AmbientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Top Navigation Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(21),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.lightBorder,
                                      width: 1.0,
                                    ),
                                    boxShadow: isDark
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Study Materials',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'Grounded Document Intelligence',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Offline Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF00F5A0).withValues(alpha: 0.12)
                                  : const Color(0xFF0D9488).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF00F5A0).withValues(alpha: 0.3)
                                    : const Color(0xFF0D9488).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Offline RAG',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildUploadCard(isDark),
                        const SizedBox(height: 28),
                        _buildSectionHeader('SAMPLE CHAPTERS', isDark),
                        const SizedBox(height: 12),
                        for (final sample in _kSamples)
                          _buildSampleTile(sample.$1, sample.$2, isDark, cardBg, borderCol, textPrimary),
                        const SizedBox(height: 28),
                        if (myChapters.isNotEmpty) ...[
                          _buildSectionHeader('MY CHAPTERS', isDark),
                          const SizedBox(height: 12),
                          for (final chapter in myChapters)
                            _buildChapterTile(chapter, isDark, cardBg, borderCol, textPrimary, textSecondary),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
              if (_isIngesting) _buildIngestOverlay(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
      ),
    );
  }

  Widget _buildUploadCard(bool isDark) {
    return InkWell(
      onTap: _isIngesting ? null : _pickAndIngest,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0D9488).withValues(alpha: 0.35),
                    const Color(0xFF1E293B).withValues(alpha: 0.70),
                  ]
                : [
                    const Color(0xFF0D9488),
                    const Color(0xFF14B8A6),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF2DD4BF).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFF0D9488).withValues(alpha: 0.20)
                  : const Color(0xFF0D9488).withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload a Chapter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'PDF, textbook photo, or text file',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleTile(
    String assetPath,
    String title,
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2DD4BF).withValues(alpha: 0.15)
                  : const Color(0xFF0D9488).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: isDark ? const Color(0xFF26F0B5) : const Color(0xFF0D9488),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          trailing: InkWell(
            onTap: _isIngesting ? null : () => _ingestSample(assetPath, title),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF26F0B5).withValues(alpha: 0.15)
                    : const Color(0xFF0D9488).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF26F0B5).withValues(alpha: 0.35)
                      : const Color(0xFF0D9488).withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Load',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF26F0B5) : const Color(0xFF0D9488),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTile(
    StudyContent content,
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Dismissible(
      key: Key(content.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteContent(content);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderCol),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2DD4BF).withValues(alpha: 0.15)
                    : const Color(0xFF0D9488).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                color: isDark ? const Color(0xFF26F0B5) : const Color(0xFF0D9488),
                size: 20,
              ),
            ),
            title: Text(
              content.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${content.chunks.length} sections',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.movie_filter_rounded,
                    color: isDark ? const Color(0xFF26F0B5) : const Color(0xFF0D9488),
                    size: 22,
                  ),
                  tooltip: 'Generate video overview',
                  onPressed: () => _generateVideoOverview(content),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
            onTap: () => _activateAndOpenChat(content),
          ),
        ),
      ),
    );
  }

  Widget _buildIngestOverlay(bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: isDark ? const Color(0xFF26F0B5) : const Color(0xFF0D9488),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Reading and understanding your chapter…',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightForeground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Extracting offline text layers & indexing chunks',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
