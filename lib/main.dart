import 'package:ai_reading_companion/models/saved_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/reading_screen.dart';

Future<void> main() async {
  // 1. Ensure that Flutter's widget binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load the .env file to make the API key available.
  await dotenv.load(fileName: ".env");

  // 3. Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(SavedNoteAdapter());
  await Hive.openBox<SavedNote>('notes');

  // 4. Run the app, wrapped in a ProviderScope.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Reading Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
        // Add a nice bottom sheet theme
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      home: const ReadingScreen(),
    );
  }
}
