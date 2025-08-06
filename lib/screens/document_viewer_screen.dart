import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../providers/reading_provider.dart';
import '../utils/debouncer.dart';
import 'notes_screen.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({super.key});

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  late final PdfViewerController _pdfViewerController;
  String _fullDocumentText = '';
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        });
        return const AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 60),
              SizedBox(height: 16),
              Text("Note Saved",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ],
          ),
        );
      },
    );
  }

  void _showExplanationSheet(String selectedText) {
    ref.read(readingNotifierProvider.notifier).hideAiBubble();

    ref.read(readingNotifierProvider.notifier).getExplanationForSelection(
          term: selectedText,
          fullText: _fullDocumentText,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              return Consumer(
                builder: (context, ref, child) {
                  final explanationState = ref.watch(
                      readingNotifierProvider.select((s) => s.explanation));
                  final isEli5 = ref.watch(
                      readingNotifierProvider.select((s) => s.isEli5Mode));
                  final currentTerm = ref.watch(
                      readingNotifierProvider.select((s) => s.currentTerm));

                  return Container(
                    padding: const EdgeInsets.all(24.0),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explanation for: "$selectedText"',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const Divider(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: explanationState.when(
                              data: (text) => Text(text,
                                  style: const TextStyle(fontSize: 16)),
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, st) => Text('Error: $e',
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FilterChip(
                              label: const Text("Explain Like I'm 5"),
                              selected: isEli5,
                              onSelected: (selected) {
                                ref
                                    .read(readingNotifierProvider.notifier)
                                    .toggleEli5Mode();
                                if (currentTerm != null) {
                                  ref
                                      .read(readingNotifierProvider.notifier)
                                      .getExplanationForSelection(
                                          term: currentTerm,
                                          fullText: _fullDocumentText);
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              onPressed: explanationState is AsyncData
                                  ? () {
                                      // This call is correct. The notifier internally uses the
                                      // document name stored in its state.
                                      ref
                                          .read(
                                              readingNotifierProvider.notifier)
                                          .saveCurrentExplanation();
                                      _showSaveConfirmationDialog();
                                    }
                                  : null,
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showSummary() {
    ref
        .read(readingNotifierProvider.notifier)
        .generateSummary(fullText: _fullDocumentText);
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(builder: (context, ref, _) {
          final summaryState = ref
              .watch(readingNotifierProvider.select((s) => s.documentSummary));
          return AlertDialog(
            title: const Text('Document Summary'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: summaryState.when(
                  data: (text) => text.isEmpty
                      ? const Center(
                          child: Text("Click generate to see summary"))
                      : Text(text),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'))
            ],
          );
        });
      },
    );
  }

  Widget _buildAiBubble() {
    final rect =
        ref.watch(readingNotifierProvider.select((s) => s.textSelectionRect));
    final selectedText = ref
        .watch(readingNotifierProvider.select((s) => s.selectedTextForBubble));

    if (rect == null || selectedText == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: rect.top - 55,
      left: rect.left,
      child: GestureDetector(
        onTap: () {
          _showExplanationSheet(selectedText);
        },
        child: Material(
          elevation: 6.0,
          borderRadius: BorderRadius.circular(20.0),
          child: Chip(
            avatar: const Icon(Icons.auto_awesome, size: 18),
            label: const Text("Explain with AI"),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer),
            onDeleted: () =>
                ref.read(readingNotifierProvider.notifier).hideAiBubble(),
            deleteIcon: const Icon(Icons.close, size: 18),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfFile =
        ref.watch(readingNotifierProvider.select((s) => s.pickedPdfFile));

    if (pdfFile == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text("No PDF file selected.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize_outlined),
            tooltip: 'Summarize Document',
            onPressed: _fullDocumentText.isNotEmpty ? _showSummary : null,
          ),
          IconButton(
            icon: const Icon(Icons.notes_outlined),
            tooltip: 'View Saved Notes',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotesScreen())),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          _pdfViewerController.clearSelection();
          ref.read(readingNotifierProvider.notifier).hideAiBubble();
        },
        child: Stack(
          children: [
            SfPdfViewer.file(
              pdfFile,
              controller: _pdfViewerController,
              canShowTextSelectionMenu: false,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) async {
                _fullDocumentText =
                    PdfTextExtractor(details.document).extractText();
                ref.read(readingNotifierProvider.notifier).state = ref
                    .read(readingNotifierProvider.notifier)
                    .state
                    .copyWith(documentSummary: const AsyncData(''));
              },
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                if (details.selectedText != null &&
                    details.selectedText!.trim().isNotEmpty) {
                  _debouncer.run(() {
                    ref.read(readingNotifierProvider.notifier).showAiBubble(
                        rect: details.globalSelectedRegion!,
                        text: details.selectedText!);
                  });
                } else {
                  ref.read(readingNotifierProvider.notifier).hideAiBubble();
                }
              },
            ),
            _buildAiBubble(),
          ],
        ),
      ),
    );
  }
}
