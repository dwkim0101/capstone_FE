import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/smartair_theme.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'models/device.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/fcm_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await getAndRegisterFcmToken();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => DeviceProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAir',
      theme: smartAirTheme,
      darkTheme: smartAirTheme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardTheme: const CardTheme(
          color: Color(0xFF23272F),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        textTheme: smartAirTheme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: smartAirTheme.colorScheme.copyWith(
          surface: const Color(0xFF23272F),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final keepLogin = prefs.getBool('keepLogin') ?? false;
    final accessToken = prefs.getString('accessToken');
    if (keepLogin && accessToken != null && accessToken.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SmartAirHome()),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
