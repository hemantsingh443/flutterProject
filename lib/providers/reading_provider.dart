import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/gemini_service.dart';

// A new class to hold our state, which is more complex now.
// It tracks the explanation, the full document text, and the loading status.
class ReadingState {
  final AsyncValue<String> explanation;
  final String documentText;
  final bool isLoadingDocument;

  ReadingState({
    this.explanation = const AsyncData("Your explanation will appear here..."),
    this.documentText = "",
    this.isLoadingDocument = false,
  });

  // A helper method to create a copy of the state with updated values.
  // This is a good practice for immutability.
  ReadingState copyWith({
    AsyncValue<String>? explanation,
    String? documentText,
    bool? isLoadingDocument,
  }) {
    return ReadingState(
      explanation: explanation ?? this.explanation,
      documentText: documentText ?? this.documentText,
      isLoadingDocument: isLoadingDocument ?? this.isLoadingDocument,
    );
  }
}

// Provider for our GeminiService instance. No changes here.
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

// The Notifier class that holds our state logic.
class ReadingNotifier extends StateNotifier<ReadingState> {
  final GeminiService _geminiService;

  // It now starts with an initial, empty ReadingState object.
  ReadingNotifier(this._geminiService) : super(ReadingState());

  // --- NEW: This function handles picking a file and extracting its text ---
  Future<void> pickAndParsePdf() async {
    // Set loading state to true
    state = state.copyWith(isLoadingDocument: true);
    try {
      // Use the file_picker package to open the file selector
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        // Use the Syncfusion package to load the PDF and extract text
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        String text = PdfTextExtractor(document).extractText();
        document.dispose(); // Important to release memory

        // Update the state with the extracted document text
        state = state.copyWith(documentText: text, isLoadingDocument: false);
      } else {
        // User canceled the picker, so just stop loading.
        state = state.copyWith(isLoadingDocument: false);
      }
    } catch (e) {
      // If anything goes wrong, update the state with an error.
      state = state.copyWith(
        explanation: AsyncError("Failed to load PDF: $e", StackTrace.current),
        isLoadingDocument: false,
      );
    }
  }

  // --- UPDATED: This function now gets the main text from the state ---
  Future<void> getExplanationForSelection({required String term}) async {
    if (term.isEmpty) return;

    // The main text is now the document text we stored in our state.
    final mainText = state.documentText;
    if (mainText.isEmpty) {
      state = state.copyWith(
          explanation:
              AsyncError("No document is loaded.", StackTrace.current));
      return;
    }

    // Set the explanation part of the state to loading
    state = state.copyWith(explanation: const AsyncLoading());
    try {
      final result =
          await _geminiService.getExplanation(mainText: mainText, term: term);
      // Update the explanation with the successful result
      state = state.copyWith(explanation: AsyncData(result));
    } catch (e, st) {
      // Update the explanation with the error
      state = state.copyWith(explanation: AsyncError(e, st));
    }
  }
}

// The final provider that the UI will interact with.
// It now manages a ReadingState object instead of a simple string.
final readingNotifierProvider =
    StateNotifierProvider<ReadingNotifier, ReadingState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return ReadingNotifier(geminiService);
});
