import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'repositories/memory_store.dart';
import 'repositories/openrouter_repository.dart';
import 'repositories/prefs_store.dart';
import 'services/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts are bundled in assets/google_fonts/ — no network fetch needed.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Inter ships under the SIL Open Font License, which travels with the font.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Inter'],
      await rootBundle.loadString('assets/fonts/Inter-LICENSE.txt'),
    );
  });

  // Force portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Edge-to-edge on Android
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Android Keystore-backed, so the key is never in the APK or in plain text.
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final apiKey = await storage.read(key: apiKeyStorageKey);
  final model = await storage.read(key: modelStorageKey);
  final memories = await MemoryStore().load();

  // Load user preferences
  final prefs = PrefsStore();
  final fontSize = await prefs.getFontSize();
  final systemPrompt = await prefs.getSystemPrompt();
  final ttsVoice = await prefs.getTtsVoice();
  final disabledTools = await prefs.getDisabledTools();

  runApp(
    ProviderScope(
      overrides: [
        // Only override when Settings actually holds a key, so an empty
        // Keystore falls through to lib/secrets.dart.
        if (apiKey != null && apiKey.isNotEmpty)
          apiKeyProvider.overrideWith((ref) => apiKey),
        // A stored id is only honoured if it is still a free model, so a
        // stale or tampered value can't silently select a paid one.
        if (model != null && OpenRouterAiRepository.isFree(model))
          modelProvider.overrideWith((ref) => model),
        memoriesProvider.overrideWith((ref) => memories),
        fontSizeProvider.overrideWith((ref) => fontSize),
        if (systemPrompt.isNotEmpty)
          systemPromptProvider.overrideWith((ref) => systemPrompt),
        if (ttsVoice != null)
          ttsVoiceProvider.overrideWith((ref) => ttsVoice),
        if (disabledTools.isNotEmpty)
          disabledToolsProvider.overrideWith((ref) => disabledTools),
      ],
      child: const JarvisApp(),
    ),
  );
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'JARVIS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      // Every glass surface (cards, app bars, the nav) is a BackdropFilter.
      // Grouping them shares one backdrop snapshot instead of taking a
      // separate saveLayer per widget — the cost otherwise scales with the
      // number of cards on screen.
      builder: (context, child) => BackdropGroup(child: child ?? const SizedBox()),
    );
  }
}
