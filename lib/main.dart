import 'package:flutter/material.dart';
import 'services/repository_provider.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'widgets/mm_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RepositoryProvider.initialize();
  final signedIn = await RepositoryProvider.instance.isSignedIn;
  runApp(MemoryMakerApp(signedIn: signedIn));
}

class MemoryMakerApp extends StatelessWidget {
  final bool signedIn;
  const MemoryMakerApp({super.key, required this.signedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Maker',
      theme: buildMemoryMakerTheme(),
      home: SplashGate(signedIn: signedIn),
    );
  }
}

class SplashGate extends StatefulWidget {
  final bool signedIn;
  const SplashGate({super.key, required this.signedIn});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, animation, __) => widget.signedIn ? const MainShell() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MmGradientBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', width: 230),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
