// Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages
import 'package:transcriptomatic/screens/splash_screen.dart';
import 'package:transcriptomatic/screens/home_screen.dart';
import 'package:transcriptomatic/screens/transcription_page.dart';
import 'package:transcriptomatic/screens/analytics_dashboard_screen.dart';

// Services
import 'package:transcriptomatic/services/navigation_service.dart';

// Provider
import 'package:transcriptomatic/provider/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initializing Supabase
  await Supabase.initialize(
    url: 'https://mvkjujnfpofbwuasrpjb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12a2p1am5mcG9mYnd1YXNycGpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NDIxMTMsImV4cCI6MjA1NjIxODExM30.qdbTvcDUd6M3wLgrmv1rBhl4NY0A_hU1fseNPliFgkg',
  );
  print('Supabase initialized');

  runApp(
    SplashPage(
      onInitializationComplete: () {
        runApp(
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: const MainApp(),
          ),
        );
      },
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TranscriptoMatic',
      theme: themeProvider.isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: '/home',
      routes: {
        '/home': (BuildContext context) => HomePage(),
        '/transcription': (BuildContext context) =>
            TranscriptionPage(audioId: 'audioid'),
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
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
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
        color: Colors.grey[850],
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
      ),
    );
  }
}
