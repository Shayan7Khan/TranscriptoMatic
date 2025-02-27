//Packages
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

//Services
import '../services/navigation_service.dart';

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
    _registerServices();
  }

  void _registerServices() {
    // Registering navigation service

    GetIt.instance.registerSingleton<NavigationService>(NavigationService());
  }
}
