import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/study_content.dart';
import '../providers/chat_provider.dart';
import '../providers/content_provider.dart';

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

  Future<void> _deleteContent(StudyContent content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove Chapter'),
        content: Text('Remove "${content.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
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
    final myChapters = ref.watch(contentNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                        ),
                        Text(
                          'Study Materials',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildUploadCard(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('SAMPLE CHAPTERS'),
                      const SizedBox(height: 12),
                      for (final sample in _kSamples)
                        _buildSampleTile(sample.$1, sample.$2),
                      const SizedBox(height: 32),
                      if (myChapters.isNotEmpty) ...[
                        _buildSectionHeader('MY CHAPTERS'),
                        const SizedBox(height: 12),
                        for (final chapter in myChapters)
                          _buildChapterTile(chapter),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
            if (_isIngesting) _buildIngestOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildUploadCard() {
    return InkWell(
      onTap: _isIngesting ? null : _pickAndIngest,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF8B7FD6),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7FD6).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
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
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PDF, text file, or a photo of a page',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleTile(String assetPath, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7), size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
          ),
          trailing: TextButton(
            onPressed: _isIngesting ? null : () => _ingestSample(assetPath, title),
            child: const Text('Load'),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTile(StudyContent content) {
    return Dismissible(
      key: Key(content.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteContent(content);
        return false; // deletion already handled via provider; keep list in sync
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Color(0xFFF3E8FF), shape: BoxShape.circle),
              child: const Icon(Icons.description_outlined, color: Color(0xFF8B7FD6), size: 20),
            ),
            title: Text(
              content.title,
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${content.chunks.length} sections',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
            ),
            onTap: () => _activateAndOpenChat(content),
          ),
        ),
      ),
    );
  }

  Widget _buildIngestOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF8B7FD6)),
              const SizedBox(height: 16),
              Text(
                'Reading and understanding your chapter…',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
