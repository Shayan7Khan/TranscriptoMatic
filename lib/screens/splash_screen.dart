//Packages
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onInitializationComplete;
  const SplashPage({Key? key, required this.onInitializationComplete})
      : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Delay for 3 seconds and then call the callback
    Future.delayed(const Duration(seconds: 2), () {
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
}
