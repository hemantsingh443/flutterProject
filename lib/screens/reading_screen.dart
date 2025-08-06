import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reading_provider.dart';
import 'document_viewer_screen.dart'; // Import the new viewer screen

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the provider to know when a document is loaded or if there's an error.
    ref.listen<ReadingState>(readingNotifierProvider, (previous, next) {
      // If a document was successfully loaded (by checking if the text is not empty
      // and it has changed from the previous state), navigate to the viewer.
      if (next.documentText.isNotEmpty &&
          previous?.documentText != next.documentText) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DocumentViewerScreen()),
        );
      }
      // If there's an error loading the document, show a snackbar for feedback.
      if (next.explanation is AsyncError) {
        // This check ensures we only show errors related to document loading if needed
        // For now, it shows any error from the provider.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.explanation.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Watch the state to show a loading indicator while the document is being parsed.
    final isLoading =
        ref.watch(readingNotifierProvider.select((s) => s.isLoadingDocument));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Reading Companion'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Show a loading indicator if a document is being processed.
          child: isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Loading Document...", style: TextStyle(fontSize: 18)),
                  ],
                )
              // Otherwise, show the main upload button.
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.school_rounded,
                        size: 100, color: Colors.indigo),
                    const SizedBox(height: 20),
                    const Text(
                      'Start a new reading session',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Call the function in the provider to start the file picking process.
                        ref
                            .read(readingNotifierProvider.notifier)
                            .pickAndParsePdf();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload PDF Document'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
