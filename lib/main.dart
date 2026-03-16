import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_entry_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/categories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCigxjHdYfYNDizaSKDGUPCaBs39Ff-awM",
      authDomain: "asraful-704b9.firebaseapp.com",
      projectId: "asraful-704b9",
      storageBucket: "asraful-704b9.firebasestorage.app",
      messagingSenderId: "418467079550",
      appId: "1:418467079550:web:9454a5851d477e3ad4bf2f",
    ),
  );
  
  runApp(const TallyKhataApp());
}

class TallyKhataApp extends StatelessWidget {
  const TallyKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Health Care',
      debugShowCheckedModeBanner: false,
      locale: const Locale('bn', 'BD'),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.hindSiliguri().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/add': (context) => const AddEntryScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/categories': (context) => const CategoriesScreen(),
      },
    );
  }
}