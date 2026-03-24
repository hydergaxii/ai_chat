import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/theme/app_theme.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait + portrait-up on phones; allow landscape on tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: AiChatApp()));
}

class AiChatApp extends ConsumerWidget {
  const AiChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Initialize settings on first load
    ref.listen(settingsRepositoryProvider, (_, next) {
      next.whenData(
        (repo) => ref.read(settingsProvider.notifier).init(repo),
      );
    });

    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends ConsumerWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show loading while settings and DB initialise
    final settingsAsync = ref.watch(settingsRepositoryProvider);

    return settingsAsync.when(
      loading: () => const _SplashScreen(),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('Failed to initialize: $e'),
        ),
      ),
      data: (_) => const ChatScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE8C97A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE8C97A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
