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
    Future.delayed(Duration(seconds: 2)).then((_) {
      _setup().then((_) {
        widget.onInitializationComplete();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transcriptomatic',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 90, 79, 255),
      ),
      home: Scaffold(
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
      ),
    );
  }

  Future<void> _setup() async {
    //will be initalising firebase her.....
    _registerServices();
  }

  void _registerServices() {
    //registring navigation service
    GetIt.instance.registerSingleton<NavigationService>(NavigationService());
  }
}
