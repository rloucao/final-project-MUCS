import 'package:flutter/material.dart';
import 'package:mobile/pages/authenticated/auth_home_page.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/signup_page.dart';
import 'package:mobile/providers/selected_hotel_provider.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/arduino_service.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        // Auth state (with auto-login)
        ChangeNotifierProvider(create: (_) => AuthService()..autoLogin()),
        // Other providers (e.g., hotel selection)
        ChangeNotifierProvider(create: (_) => SelectedHotelProvider()),
        // Add more providers here as needed
        //ChangeNotifierProvider(create: (_) =>  AuthService()),
        ChangeNotifierProvider(create: (_) => ArduinoService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florever',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
         // return const AuthenticatedHome();
         return authService.isAuthenticated
          ? const AuthenticatedHome()
              : const HomePage();
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            //image: AssetImage('assets/green-plant-with-roots.jpg'),
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLandscape ? screenSize.width * 0.5 : screenSize.width * 0.85,
              maxHeight: screenSize.height * 0.7,
            ),
            child: Container(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Florever',
                      style: TextStyle(
                        color: Colors.lightGreen,
                        fontFamily: 'Gidole',
                        fontSize: screenSize.width * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Text(
                      'Welcome to Florever, the best tracking app for your plants!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenSize.width * 0.04,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => SignInPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.02,
                          ),
                        ),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.04,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.015),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => SignUpPage()                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.02,
                          ),
                          side: BorderSide(color: Colors.green),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.lightGreen,
                            fontSize: screenSize.width * 0.04,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}