// Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Pages
import 'package:transcriptomatic/screens/splash_screen.dart';
import 'package:transcriptomatic/screens/home_screen.dart';
import 'package:transcriptomatic/screens/transcription_screen.dart';
import 'package:transcriptomatic/screens/analytics_dashboard_screen.dart';

// Services
import 'package:transcriptomatic/services/navigation_service.dart';

// Provider
import 'package:transcriptomatic/provider/theme_provider.dart';

void main() {
  runApp(
    ProviderScope(
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider(
              create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  String? _initializationMessage;

  @override
  void initState() {
    super.initState();
    _initialized = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TranscriptoMatic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: !_initialized
          ? SplashPage(onInitializationComplete: _onInitializationComplete)
          : (_initializationMessage != null
              ? Scaffold(
                  body: Center(
                    child: Text(
                        'Supabase Initialization Failed: $_initializationMessage'),
                  ),
                )
              : const MainApp()),
    );
  }

  Future<void> _initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: 'Supabase-URL',
        anonKey:
            'Anon-Key',
      );
      print('Supabase initialized successfully');
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print('Supabase initialization error: $e');
      setState(() {
        _initializationMessage = e.toString();
      });
    }
  }

  void _onInitializationComplete() {
    _initializeSupabase();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = legacy_provider.Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TranscriptoMatic',
      theme: themeProvider.isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: '/home',
      routes: {
        '/home': (BuildContext context) => HomePage(),
        '/transcription': (BuildContext context) => TranscriptionScreen(),
        '/dashboard': (BuildContext context) => AnalyticsDashboard(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 2,
        color: Colors.white,
        margin: const EdgeInsets.all(16.0),
      ),
      textTheme: TextTheme(
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[800]),
        titleMedium: TextStyle(fontSize: 14, color: Colors.grey[600]),
        bodyLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.grey[900]!,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850]!,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 2,
        color: Colors.grey[850]!,
        margin: const EdgeInsets.all(16.0),
      ),
      textTheme: TextTheme(
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[300]),
          titleMedium: TextStyle(fontSize: 14, color: Colors.grey[400]),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          )),
    );
  }
}

class SplashPageLoading extends StatelessWidget {
  const SplashPageLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
