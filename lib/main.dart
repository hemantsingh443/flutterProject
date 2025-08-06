import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/reading_screen.dart';

Future<void> main() async {
  // 1. Ensure that Flutter's widget binding is initialized.
  // This is required before you can call platform-specific code or use async in main.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load the .env file to make the API key available.
  await dotenv.load(fileName: ".env");

  // 3. Run the app, wrapped in a ProviderScope.
  // ProviderScope is what allows all the widgets in your app to read the providers.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Reading Companion',
      // Hides the "debug" banner in the top-right corner.
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ReadingScreen(),
    );
  }
}
