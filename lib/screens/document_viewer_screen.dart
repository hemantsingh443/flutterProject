import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../providers/reading_provider.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({super.key});

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  late final PdfViewerController _pdfViewerController;
  String _fullDocumentText = '';

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  // This function shows the explanation in a pop-up from the bottom.
  void _showExplanationSheet(String selectedText) {
    // We pass the full document text to the provider for better context.
    ref.read(readingNotifierProvider.notifier).getExplanationForSelection(
          term: selectedText,
          fullText: _fullDocumentText,
        );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final explanationState =
                ref.watch(readingNotifierProvider.select((s) => s.explanation));
            return Container(
              padding: const EdgeInsets.all(24.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explanation for: "$selectedText"',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      child: explanationState.when(
                        data: (text) =>
                            Text(text, style: const TextStyle(fontSize: 16)),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error: $e',
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfFile =
        ref.watch(readingNotifierProvider.select((s) => s.pickedPdfFile));

    if (pdfFile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No PDF file selected.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Viewer'),
      ),
      body: SfPdfViewer.file(
        pdfFile,
        controller: _pdfViewerController,
        // This is the key! It gets called when the document is fully loaded.
        onDocumentLoaded: (PdfDocumentLoadedDetails details) async {
          // We extract the text once here to use for context in our API calls.
          _fullDocumentText = PdfTextExtractor(details.document).extractText();
        },
        // And this gets called whenever the user selects text.
        onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
          if (details.selectedText != null &&
              details.selectedText!.trim().isNotEmpty) {
            // When text is selected, show our explanation sheet.
            _showExplanationSheet(details.selectedText!);
          }
        },
      ),
    );
  }
}
