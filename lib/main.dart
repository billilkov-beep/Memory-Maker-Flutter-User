import 'package:flutter/material.dart';
import 'services/repository_provider.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

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
      title: 'MemoryMaker',
      theme: buildMemoryMakerTheme(),
      home: signedIn ? const MainShell() : const LoginScreen(),
    );
  }
}
