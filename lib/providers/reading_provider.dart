import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_service.dart';

// The state now holds the file path instead of the extracted text.
class ReadingState {
  final AsyncValue<String> explanation;
  final File? pickedPdfFile;
  final bool isLoadingDocument;

  ReadingState({
    this.explanation =
        const AsyncData("Select text from the PDF to get an explanation."),
    this.pickedPdfFile,
    this.isLoadingDocument = false,
  });

  ReadingState copyWith({
    AsyncValue<String>? explanation,
    File? pickedPdfFile,
    bool? isLoadingDocument,
  }) {
    return ReadingState(
      explanation: explanation ?? this.explanation,
      pickedPdfFile: pickedPdfFile ?? this.pickedPdfFile,
      isLoadingDocument: isLoadingDocument ?? this.isLoadingDocument,
    );
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

class ReadingNotifier extends StateNotifier<ReadingState> {
  final GeminiService _geminiService;

  ReadingNotifier(this._geminiService) : super(ReadingState());

  // This function now just picks the file and stores its path.
  Future<void> pickPdf() async {
    state = state.copyWith(isLoadingDocument: true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        state = state.copyWith(pickedPdfFile: file, isLoadingDocument: false);
      } else {
        state = state.copyWith(isLoadingDocument: false);
      }
    } catch (e) {
      state = state.copyWith(
        explanation: AsyncError("Failed to load PDF: $e", StackTrace.current),
        isLoadingDocument: false,
      );
    }
  }

  // This function is now called from the viewer with the selected text.
  Future<void> getExplanationForSelection(
      {required String term, required String fullText}) async {
    if (term.isEmpty) return;

    state = state.copyWith(explanation: const AsyncLoading());
    try {
      // We pass the full document text here for context.
      final result =
          await _geminiService.getExplanation(mainText: fullText, term: term);
      state = state.copyWith(explanation: AsyncData(result));
    } catch (e, st) {
      state = state.copyWith(explanation: AsyncError(e, st));
    }
  }
}

final readingNotifierProvider =
    StateNotifierProvider<ReadingNotifier, ReadingState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return ReadingNotifier(geminiService);
});
