//Packages
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Services
import '../services/navigation_service.dart';
import '../services/database_service.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onInitializationComplete;
  const SplashPage({super.key, required this.onInitializationComplete});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((_) async {
      await _setup();
      widget.onInitializationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: 200,
          width: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.contain,
              image: AssetImage('assets/images/splash-image.png'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setup() async {
    await _initializeSupabase();
    _registerServices();
  }

  Future<void> _initializeSupabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://mvkjujnfpofbwuasrpjb.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12a2p1am5mcG9mYnd1YXNycGpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NDIxMTMsImV4cCI6MjA1NjIxODExM30.qdbTvcDUd6M3wLgrmv1rBhl4NY0A_hU1fseNPliFgkg',
    );
    print('supabase initialized');
  }

  void _registerServices() {
    // Registering navigation service
    GetIt.instance.registerSingleton<NavigationService>(NavigationService());
    GetIt.instance.registerSingleton<DatabaseService>(DatabaseService());
  }
}
