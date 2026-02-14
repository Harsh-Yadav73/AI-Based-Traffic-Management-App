import 'package:flutter/material.dart';
import 'package:my_project/screen/splash_screen.dart';
import 'package:my_project/screen/login_page.dart';
import 'package:my_project/screen/signup_page.dart';
import 'package:my_project/screen/home_page.dart';
import 'services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// Global navigator key (needed for navigation & snackbars)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ INIT SUPABASE
  await SupabaseManager.init();

  // 2️⃣ INIT ONESIGNAL (Replace with your real OneSignal App ID)
  OneSignal.initialize("YOUR_ONESIGNAL_APP_ID_HERE");

  // Ask for notification permission (Android 13+ / iOS)
  OneSignal.Notifications.requestPermission(true);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Required for navigation anywhere in app
      title: 'Smart Traffic App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
