import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reading_provider.dart';
import 'document_viewer_screen.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for when a PDF file is successfully picked
    ref.listen<ReadingState>(readingNotifierProvider, (previous, next) {
      if (next.pickedPdfFile != null &&
          previous?.pickedPdfFile != next.pickedPdfFile) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DocumentViewerScreen()),
        );
      }
    });

    final isLoading =
        ref.watch(readingNotifierProvider.select((s) => s.isLoadingDocument));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Reading Companion'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Loading Document...", style: TextStyle(fontSize: 18)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        size: 100, color: Colors.indigo),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Call the updated function name
                        ref.read(readingNotifierProvider.notifier).pickPdf();
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
