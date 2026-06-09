import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/folders_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/recording_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/db_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDatabaseFactory();
  await initializeDateFormatting('fr_FR', null);
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env is optional; cloud transcription will simply be disabled.
  }
  runApp(const VoiceNotesApp());
}

class VoiceNotesApp extends StatelessWidget {
  const VoiceNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => FoldersProvider()),
        ChangeNotifierProvider(create: (_) => RecordingProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Voxnote',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const _AuthGate(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF6C8EF5);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: Color(0xFF1F2330),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Decides between the login screen and the home screen based on auth state.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _syncedUserId;
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().tryAutoLogin();
    });
  }

  /// Loads (or clears) the active user's notes and folders whenever the
  /// authenticated user changes. Runs after the frame to avoid mutating
  /// providers during build.
  void _syncProviders(String? userId) {
    _syncedUserId = userId;
    _hasSynced = true;
    context.read<NotesProvider>().setUser(userId);
    context.read<FoldersProvider>().setUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = auth.currentUser?.id;
    if (!_hasSynced || userId != _syncedUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncProviders(userId);
      });
    }

    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
