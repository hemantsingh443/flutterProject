import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reading_provider.dart';

class DocumentViewerScreen extends ConsumerWidget {
  const DocumentViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the full document text from the provider
    final documentText =
        ref.watch(readingNotifierProvider.select((s) => s.documentText));
    final explanationState =
        ref.watch(readingNotifierProvider.select((s) => s.explanation));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Viewer'),
      ),
      body: Column(
        children: [
          // Top part: The interactive text viewer
          Expanded(
            flex: 3, // Takes 3/4 of the screen height
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: SelectableText(
                  documentText,
                  style: const TextStyle(fontSize: 18, height: 1.6),
                  // This is where the magic happens!
                  // We define a custom toolbar that appears when text is selected.
                  toolbarOptions: const ToolbarOptions(
                    copy: true,
                    selectAll: true,
                  ),
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: [
                        ...editableTextState.contextMenuButtonItems,
                        ContextMenuButtonItem(
                          onPressed: () {
                            // Get the selected text and call the provider
                            final selection =
                                editableTextState.textEditingValue.selection;
                            final selectedText = editableTextState
                                .textEditingValue.text
                                .substring(selection.start, selection.end);
                            ref
                                .read(readingNotifierProvider.notifier)
                                .getExplanationForSelection(term: selectedText);
                            // Hide the toolbar
                            editableTextState.hideToolbar();
                          },
                          label: 'Explain',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Bottom part: The explanation box
          Expanded(
            flex: 2, // Takes 2/4 of the screen height
            child: Container(
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explanation:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    explanationState.when(
                      data: (text) =>
                          Text(text, style: const TextStyle(fontSize: 16)),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text(
                        'An error occurred: $e',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
