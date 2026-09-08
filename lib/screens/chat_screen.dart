import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../providers/content_provider.dart';
import '../providers/ui_provider.dart';
import '../services/voice_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/mascot_widget.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../services/chat_to_studio_generator.dart';
import 'mind_map_screen.dart';
import 'flashcards_screen.dart';
import 'slide_deck_screen.dart';
import 'quiz_screen.dart';
import 'audio_overview_screen.dart';
import 'profile_setup_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;
  const ChatScreen({super.key, this.showBottomNav = false});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();

  bool _isModelLoading = true;
  bool _hasError = false;
  bool _isIngestingFile = false;
  bool _showCelebration = false;
  Timer? _celebrationTimer;

  Future<void> _pickAndAttachFile() async {
    final processor = ref.read(contentProcessorServiceProvider);
    final extensions = [
      'pdf',
      'txt',
      if (processor.supportsOcr) ...['jpg', 'jpeg', 'png'],
    ];

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _isIngestingFile = true);
      final content = await ref.read(contentNotifierProvider.notifier).ingestFile(result.files.first);
      if (!mounted) return;
      setState(() => _isIngestingFile = false);

      ref.read(currentContentIdProvider.notifier).state = content.id;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attached "${content.title}". Echo will use this file for answers.'),
          backgroundColor: AppColors.lightTeal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isIngestingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not attach file: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: AppColors.lightDestructive,
        ),
      );
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (pickedFile == null) return;

      setState(() => _isIngestingFile = true);

      final processor = ref.read(contentProcessorServiceProvider);
      String recognizedText = '';

      if (processor.supportsOcr && pickedFile.path.isNotEmpty) {
        recognizedText = await processor.extractTextFromImagePath(pickedFile.path);
      }

      if (!mounted) return;
      setState(() => _isIngestingFile = false);

      if (recognizedText.trim().isNotEmpty) {
        final cleanText = recognizedText.trim();
        final current = _textController.text.trim();
        if (current.isEmpty) {
          _textController.text = 'Here are my notes captured with the camera:\n\n$cleanText\n\nCould you please explain this concept and solve any problems in it?';
        } else {
          _textController.text = '$current\n\n[Captured Notes]:\n$cleanText';
        }
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Notes extracted via OCR and inserted into chat!'),
            backgroundColor: AppColors.lightTeal,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final bytes = await pickedFile.readAsBytes();
        final pFile = PlatformFile(
          name: pickedFile.name,
          size: bytes.length,
          bytes: bytes,
          path: kIsWeb ? null : pickedFile.path,
        );
        final content = await ref.read(contentNotifierProvider.notifier).ingestFile(pFile);
        if (!mounted) return;
        ref.read(currentContentIdProvider.notifier).state = content.id;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo attached as "${content.title}". Echo will use it for answers.'),
            backgroundColor: AppColors.lightTeal,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isIngestingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera capture: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: AppColors.lightDestructive,
        ),
      );
    }
  }

  void _showStudioGenerationSheet(BuildContext context, List messages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatMessages = messages.cast<ChatMessage>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF142225) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_mosaic_rounded,
                      color: AppColors.lightTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Echo Studio • Convert Chat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightForeground,
                          ),
                        ),
                        Text(
                          'Transform active discussion into interactive study artifacts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : AppColors.lightMutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. 2D Visual Mind Map
              _buildStudioOptionTile(
                icon: Icons.hub_rounded,
                iconColor: const Color(0xFF14B8A6),
                title: '2D Visual Mind Map',
                description: 'Canvas graph with organic Bezier curves & drill-down nodes',
                onTap: () {
                  Navigator.pop(sheetContext);
                  final deck = ChatToStudioGenerator.generateMindMap(chatMessages);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MindMapScreen(initialDeck: deck)),
                  );
                },
                isDark: isDark,
              ),

              // 2. Flashcards
              _buildStudioOptionTile(
                icon: Icons.style_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Active-Recall Flashcards',
                description: '3D flipping cards, hints & spaced retention scoring',
                onTap: () {
                  Navigator.pop(sheetContext);
                  final deck = ChatToStudioGenerator.generateFlashcards(chatMessages);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FlashcardsScreen(initialDeck: deck)),
                  );
                },
                isDark: isDark,
              ),

              // 3. Slide Deck
              _buildStudioOptionTile(
                icon: Icons.slideshow_rounded,
                iconColor: const Color(0xFFF97316),
                title: 'Executive Slide Deck',
                description: 'Presentation slides with formulas, axioms & takeaways',
                onTap: () {
                  Navigator.pop(sheetContext);
                  final deck = ChatToStudioGenerator.generateSlideDeck(chatMessages);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SlideDeckScreen(initialDeck: deck)),
                  );
                },
                isDark: isDark,
              ),

              // 4. Practice Quiz
              _buildStudioOptionTile(
                icon: Icons.quiz_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Practice Quiz & Assessment',
                description: 'Multiple-choice test with immediate feedback & answers',
                onTap: () {
                  Navigator.pop(sheetContext);
                  final deck = ChatToStudioGenerator.generateQuiz(chatMessages);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuizScreen(initialDeck: deck)),
                  );
                },
                isDark: isDark,
              ),

              // 5. Audio Overview Podcast
              _buildStudioOptionTile(
                icon: Icons.podcasts_rounded,
                iconColor: const Color(0xFF6366F1),
                title: 'Audio Overview Podcast',
                description: 'Two-host back-and-forth deep dive conversational show',
                onTap: () {
                  Navigator.pop(sheetContext);
                  final track = ChatToStudioGenerator.generatePodcast(chatMessages);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AudioOverviewScreen(initialTrack: track)),
                  );
                },
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudioOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2C30) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF263D42) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white60 : AppColors.lightMutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeModelSilently();
    _voiceService.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialText')) {
        _textController.text = args['initialText'];
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    _textController.dispose();
    _scrollController.dispose();
    _celebrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeModelSilently() async {
    try {
      final llmService = ref.read(llmServiceProvider);
      await llmService.loadModel();
      if (mounted) {
        setState(() => _isModelLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI initialization failed: ${e.toString()}'),
            backgroundColor: AppColors.lightDestructive,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isModelLoading = true;
                  _hasError = false;
                });
                _initializeModelSilently();
              },
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    if (_isModelLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI is warming up... Ready in just a moment!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI failed to load. Tap to retry.'),
          backgroundColor: AppColors.chart4,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _isModelLoading = true;
                _hasError = false;
              });
              _initializeModelSilently();
            },
          ),
        ),
      );
      return;
    }

    final llmService = ref.read(llmServiceProvider);
    if (!llmService.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI is not ready. Tap to retry loading.'),
          backgroundColor: AppColors.chart4,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _isModelLoading = true;
                _hasError = false;
              });
              _initializeModelSilently();
            },
          ),
        ),
      );
      return;
    }

    ref.read(chatProvider.notifier).addMessage(text, 'user');
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pulse a happy mascot reaction for a moment whenever a response
    // finishes streaming in, then let it settle back to idle.
    ref.listen<bool>(isGeneratingProvider, (previous, isGenerating) {
      if (previous == true && isGenerating == false) {
        _celebrationTimer?.cancel();
        setState(() => _showCelebration = true);
        _celebrationTimer = Timer(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _showCelebration = false);
        });
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                borderRadius: AppRadii.smRadius,
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(3),
              child: Image.asset('assets/mascot/idle/frame_000.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            Text(
              'Echo Tutor',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showStudioGenerationSheet(context, messages),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadii.smRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_mosaic_rounded,
                color: AppColors.lightTeal,
                size: 18,
              ),
            ),
            tooltip: 'Echo Studio (Convert Chat)',
          ),
          IconButton(
            onPressed: () {
              ref.read(chatProvider.notifier).startNewChat();
            },
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadii.smRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 18,
              ),
            ),
            tooltip: 'New Chat',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSetupScreen(isEditMode: true),
              ),
            ),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
              child: Icon(
                Icons.person_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 16,
              ),
            ),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildGroundingBanner(isDark),
              Expanded(
                child: messages.isEmpty ? _buildEmptyState(isDark) : _buildMessageList(messages, isDark),
              ),
              _buildInputArea(context, isDark),
            ],
          ),
          if (_showCelebration)
            Positioned(
              right: 12,
              bottom: 84,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showCelebration ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
                    ),
                    child: const MascotWidget(state: MascotState.correct, size: 56),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroundingBanner(bool isDark) {
    final contentId = ref.watch(currentContentIdProvider);
    if (contentId == null) return const SizedBox.shrink();

    final contentBox = ref.watch(contentBoxProvider);
    final content = contentBox.get(contentId);
    if (content == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 16, color: isDark ? AppColors.darkTeal : AppColors.lightTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Grounded in "${content.title}"',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkForeground : AppColors.lightPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => ref.read(currentContentIdProvider.notifier).state = null,
            child: Icon(Icons.close, size: 16, color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List messages, bool isDark) {
    final isGenerating = ref.watch(isGeneratingProvider);
    final isThinking = isGenerating && messages.isNotEmpty && messages.last.role == 'user';

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (isThinking && index == messages.length) {
          return _buildThinkingIndicator(context, isDark);
        }

        final message = messages[index];
        final isUser = message.role == 'user';
        final isLastAiMessage = !isUser && index == messages.length - 1 && !isGenerating;
        final messageId = message.timestamp.toIso8601String();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageBubble(context, message.content, isUser, isDark, messageId),
            if (isLastAiMessage) ...[
              const SizedBox(height: 8),
              _buildEducationalActionChips(context, isDark, messages),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildThinkingIndicator(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2, right: 10),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: const MascotWidget(state: MascotState.thinking, size: 32),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(4),
                  topRight: Radius.circular(AppRadii.card),
                  bottomLeft: Radius.circular(AppRadii.card),
                  bottomRight: Radius.circular(AppRadii.card),
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProgressiveThinkingIndicator(
                    color: AppColors.lightTeal,
                    textColor: AppColors.lightTeal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 4),
          const MascotWidget(state: MascotState.idle, size: 120),
          const SizedBox(height: 12),

          // Greeting
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              final name = snapshot.data?.getString('user_name') ?? 'Student';
              return Column(
                children: [
                  Text(
                    'Hello, $name!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'What would you like to learn?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Text(
            'Ask me any question or choose an educational shortcut below to get started.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Shortcuts 2x2 Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: [
              _buildShortcutTile('Homework Help', Icons.school_outlined, isDark, () {
                _textController.text = 'Help with Homework: ';
              }),
              _buildShortcutTile('Explain Concept', Icons.lightbulb_outline_rounded, isDark, () {
                _textController.text = 'Explain a Concept: ';
              }),
              _buildShortcutTile('Take a Quiz', Icons.quiz_outlined, isDark, () {
                _textController.text = 'Take a Quiz on: ';
              }),
              _buildShortcutTile('Summarize', Icons.auto_stories_outlined, isDark, () {
                _textController.text = 'Summarize: ';
              }),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShortcutTile(String label, IconData icon, bool isDark, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: () {
          onTap();
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.lightTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    String content,
    bool isUser,
    bool isDark, [
    String? messageId,
  ]) {
    if (isUser) {
      // User Message Bubble
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSecondary : AppColors.lightPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadii.card),
              topRight: const Radius.circular(4),
              bottomLeft: Radius.circular(AppRadii.card),
              bottomRight: Radius.circular(AppRadii.card),
            ),
            boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
          ),
          child: Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: isDark ? AppColors.darkForeground : Colors.white,
            ),
          ),
        ),
      );
    } else {
      // AI Message Bubble
      final isThinking = content == '...';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sprite Avatar Motif
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(2),
              child: Image.asset('assets/mascot/idle/frame_000.png', fit: BoxFit.contain),
            ),

            // Bubble
            Flexible(
              child: Container(
                padding: isThinking
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(4),
                    topRight: Radius.circular(AppRadii.card),
                    bottomLeft: Radius.circular(AppRadii.card),
                    bottomRight: Radius.circular(AppRadii.card),
                  ),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                  boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageContent(content, isUser, isDark, context),
                    if (!isThinking && content.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ValueListenableBuilder<String?>(
                          valueListenable: _voiceService.currentlySpeakingIdNotifier,
                          builder: (context, speakingId, _) {
                            final isSpeaking = speakingId == messageId;
                            return InkWell(
                              borderRadius: AppRadii.smRadius,
                              onTap: () => _voiceService.speakText(
                                content,
                                messageId: messageId,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                                      size: 16,
                                      color: isSpeaking ? AppColors.lightDestructive : AppColors.lightTeal,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSpeaking ? 'Stop' : 'Listen',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSpeaking ? AppColors.lightDestructive : AppColors.lightTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEducationalActionChips(BuildContext context, bool isDark, List messages) {
    final actions = [
      '✨ Convert to Studio Artifacts',
      'Try a similar problem',
      'Explain it simpler',
      'Give me a quiz',
      'Show another example',
      'Continue learning',
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 38.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: actions.map((action) {
          final isStudioAction = action.contains('Studio Artifacts');
          return ActionChip(
            label: Text(
              action,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isStudioAction
                    ? AppColors.lightTeal
                    : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              ),
            ),
            backgroundColor: isStudioAction
                ? AppColors.lightTeal.withValues(alpha: isDark ? 0.18 : 0.12)
                : (isDark ? AppColors.darkCard : AppColors.lightSecondary),
            side: BorderSide(
              color: isStudioAction
                  ? AppColors.lightTeal
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.pillRadius,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            onPressed: () {
              if (isStudioAction) {
                _showStudioGenerationSheet(context, messages);
              } else {
                _handleSubmitted(action);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageContent(
    String content,
    bool isUser,
    bool isDark,
    BuildContext context,
  ) {
    if (!isUser && content == '...') {
      return const _ProgressiveThinkingIndicator(
        color: AppColors.lightTeal,
        textColor: AppColors.lightTeal,
      );
    }

    final scale = ref.watch(fontSizeProvider);

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.plusJakartaSans(
          fontSize: (14 * scale).toDouble(),
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
        ),
        strong: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          fontSize: (14 * scale).toDouble(),
        ),
        listBullet: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTeal,
          fontSize: (14 * scale).toDouble(),
          fontWeight: FontWeight.bold,
        ),
        h1: GoogleFonts.plusJakartaSans(
          fontSize: (18 * scale).toDouble(),
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
        ),
        h2: GoogleFonts.plusJakartaSans(
          fontSize: (16 * scale).toDouble(),
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
        ),
        code: GoogleFonts.firaCode(
          backgroundColor: isDark ? AppColors.darkInput : AppColors.lightMuted,
          color: AppColors.lightTeal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isDark) {
    final isGenerating = ref.watch(isGeneratingProvider);

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50, maxHeight: 140),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.featureRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // + Add File Button
            if (_isIngestingFile)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.lightTeal,
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Attach study files (.pdf, .txt, images)',
                icon: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
                onPressed: _pickAndAttachFile,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 2),
            // Camera OCR Button
            IconButton(
              tooltip: 'Scan Notes / Textbook with Camera (OCR)',
              icon: Icon(
                Icons.camera_alt_outlined,
                size: 20,
                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              ),
              onPressed: _captureFromCamera,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ask Echo anything...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            // Microphone Button
            ValueListenableBuilder<bool>(
              valueListenable: _voiceService.isListeningNotifier,
              builder: (context, isListening, _) {
                return IconButton(
                  tooltip: isListening ? 'Listening... Tap to stop' : 'Voice Input',
                  icon: Icon(
                    isListening ? Icons.mic : Icons.mic_none_outlined,
                    size: 20,
                    color: isListening ? AppColors.lightDestructive : AppColors.lightTeal,
                  ),
                  onPressed: () async {
                    if (isListening) {
                      await _voiceService.stopListening();
                    } else {
                      final messenger = ScaffoldMessenger.of(context);
                      final started = await _voiceService.startListening(
                        onResult: (words) {
                          if (!mounted) return;
                          setState(() {
                            _textController.text = words;
                            _textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: words.length),
                            );
                          });
                        },
                      );
                      if (!started && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Microphone permission or speech recognition unavailable.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
            // Send / Stop Button
            Container(
              decoration: BoxDecoration(
                color: isGenerating
                    ? AppColors.lightDestructive
                    : (_textController.text.trim().isEmpty
                        ? (isDark ? AppColors.darkMuted : AppColors.lightMuted)
                        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                borderRadius: AppRadii.buttonRadius,
              ),
              child: IconButton(
                onPressed: isGenerating
                    ? () => ref.read(chatProvider.notifier).cancelCurrentGeneration()
                    : (_textController.text.trim().isEmpty
                        ? null
                        : () => _handleSubmitted(_textController.text)),
                icon: Icon(
                  isGenerating ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  size: 18,
                  color: isGenerating
                      ? Colors.white
                      : (_textController.text.trim().isEmpty
                          ? (isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground)
                          : (isDark ? AppColors.darkPrimaryForeground : Colors.white)),
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressiveThinkingIndicator extends StatefulWidget {
  final Color color;
  final Color textColor;

  const _ProgressiveThinkingIndicator({
    required this.color,
    required this.textColor,
  });

  @override
  State<_ProgressiveThinkingIndicator> createState() => _ProgressiveThinkingIndicatorState();
}

class _ProgressiveThinkingIndicatorState extends State<_ProgressiveThinkingIndicator> {
  String _currentMessage = 'Thinking';
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds >= 5) {
          _currentMessage = 'Preparing explanation';
        } else if (_elapsedSeconds >= 2) {
          _currentMessage = 'Analyzing concept';
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentMessage,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: widget.textColor,
          ),
        ),
        const SizedBox(width: 6),
        _BouncingDot(color: widget.color, delay: 0),
        const SizedBox(width: 3),
        _BouncingDot(color: widget.color, delay: 150),
        const SizedBox(width: 3),
        _BouncingDot(color: widget.color, delay: 300),
      ],
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final Color color;
  final int delay;

  const _BouncingDot({required this.color, required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            width: 3.5,
            height: 3.5,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.7 + 0.3 * _animation.value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
