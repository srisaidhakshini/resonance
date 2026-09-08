import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/chat_message.dart';
import 'models/chat_session.dart';
import 'models/content_chunk.dart';
import 'models/study_content.dart';
import 'providers/chat_provider.dart';
import 'providers/download_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/content_library_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/model_download_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/native_loader.dart';
import 'theme/app_theme.dart';
import 'widgets/mascot_widget.dart';
import 'package:flutter/foundation.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      loadNativeLibraries();

      await Hive.initFlutter();
      Hive.registerAdapter(ChatMessageAdapter());
      Hive.registerAdapter(ChatSessionAdapter());
      Hive.registerAdapter(ContentChunkAdapter());
      Hive.registerAdapter(StudyContentAdapter());
      Hive.registerAdapter(ContentSourceTypeAdapter());
      final chatBox = await Hive.openBox<ChatSession>('chat_sessions');
      final contentBox = await Hive.openBox<StudyContent>('study_content');

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('❌ [FLUTTER ERROR]: ${details.exception}');
        if (details.stack != null) debugPrint('Stack: ${details.stack}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('❌ [PLATFORM ERROR]: $error\n$stack');
        return true;
      };

      runApp(
        ProviderScope(
          overrides: [
            chatBoxProvider.overrideWithValue(chatBox),
            contentBoxProvider.overrideWithValue(contentBox),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('❌ [ZONED ERROR]: $error\n$stack');
    },
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final llmService = ref.read(llmServiceProvider);

    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('📱 [LIFECYCLE] App paused - Cancelling active generation');
        llmService.cancelGeneration();
        break;

      case AppLifecycleState.inactive:
        debugPrint('📱 [LIFECYCLE] App inactive (keyboard or transition)');
        break;

      case AppLifecycleState.detached:
        debugPrint('📱 [LIFECYCLE] App detached - Unloading model');
        llmService.unloadModel();
        break;

      case AppLifecycleState.resumed:
        debugPrint('📱 [LIFECYCLE] App resumed');
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Pocket Tutor (Echo)',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Consumer(
        builder: (context, ref, _) {
          final downloadService = ref.watch(modelDownloadServiceProvider);

          Future<String> checkInitialRoute() async {
            final isDownloaded = await downloadService.isReady();
            if (!isDownloaded) return '/onboarding';

            final prefs = await SharedPreferences.getInstance();
            final isProfileComplete = prefs.getBool('is_profile_completed') ?? false;
            if (!isProfileComplete) return '/profile_setup';

            return '/home';
          }

          return FutureBuilder<String>(
            future: checkInitialRoute(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SplashScreen();
              }

              final route = snapshot.data ?? '/onboarding';

              if (route == '/home') {
                return const MainNavigationShell();
              }
              if (route == '/profile_setup') return const ProfileSetupScreen();
              return const OnboardingScreen();
            },
          );
        },
      ),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MainNavigationShell(),
        '/chat': (context) => const ChatScreen(),
        '/learn': (context) => const MainNavigationShell(initialIndex: 1),
        '/progress': (context) => const MainNavigationShell(initialIndex: 3),
        '/download': (context) => const ModelDownloadScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/library': (context) => const ContentLibraryScreen(),
      },
    );
  }
}

/// Splash screen shown while checking download/profile state at launch.
/// Uses the Sprite mascot instead of a bare spinner for a Duolingo-style
/// first impression.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotWidget(state: MascotState.idle, size: 160),
            const SizedBox(height: 24),
            Text(
              'Echo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.lightTeal),
            ),
          ],
        ),
      ),
    );
  }
}
