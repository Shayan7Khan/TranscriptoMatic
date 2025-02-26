// Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Pages
import 'package:transcriptomatic/screens/splash_screen.dart';
import 'package:transcriptomatic/screens/home_screen.dart';
import 'package:transcriptomatic/screens/transcription_page.dart';
import 'package:transcriptomatic/screens/analytics_dashboard_screen.dart';

// Services
import 'package:transcriptomatic/services/navigation_service.dart';

//  Provider
import 'package:transcriptomatic/provider/theme_provider.dart';

void main() {
  runApp(
    SplashPage(
      onInitializationComplete: () {
        runApp(
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: MainApp(),
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
        '/transcription':
            (BuildContext context) => TranscriptionPage(audioId: 'audioid'),
        '/dashboard': (BuildContext context) => AnalyticsDashboard(),
      },
    );
  }

  // Light Theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
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
        margin: EdgeInsets.all(16.0),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[800]),
        titleMedium: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }

  // Dark Theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
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
        color: Colors.grey[850],
        margin: EdgeInsets.all(16.0),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
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
