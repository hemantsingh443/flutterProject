import 'dart:io';
import 'dart:ui';
import 'package:ai_reading_companion/models/saved_note.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/gemini_service.dart';

class ReadingState {
  final AsyncValue<String> explanation;
  final File? pickedPdfFile;
  final bool isLoadingDocument;
  final List<SavedNote> savedNotes;
  final String? currentTerm;
  final bool isEli5Mode;
  final AsyncValue<String> documentSummary;
  final Rect? textSelectionRect;
  final String? selectedTextForBubble;

  // *** NEW FIELD ***
  final String? pickedPdfName;

  ReadingState({
    this.explanation =
        const AsyncData("Select text from the PDF to get an explanation."),
    this.pickedPdfFile,
    this.isLoadingDocument = false,
    this.savedNotes = const [],
    this.currentTerm,
    this.isEli5Mode = false,
    this.documentSummary = const AsyncData(''),
    this.textSelectionRect,
    this.selectedTextForBubble,
    this.pickedPdfName, // Add to constructor
  });

  ReadingState copyWith({
    AsyncValue<String>? explanation,
    File? pickedPdfFile,
    bool? isLoadingDocument,
    List<SavedNote>? savedNotes,
    String? currentTerm,
    bool? isEli5Mode,
    AsyncValue<String>? documentSummary,
    Rect? textSelectionRect,
    String? selectedTextForBubble,
    String? pickedPdfName,
    bool clearTextSelection = false,
  }) {
    return ReadingState(
      explanation: explanation ?? this.explanation,
      pickedPdfFile: pickedPdfFile ?? this.pickedPdfFile,
      isLoadingDocument: isLoadingDocument ?? this.isLoadingDocument,
      savedNotes: savedNotes ?? this.savedNotes,
      currentTerm: currentTerm ?? this.currentTerm,
      isEli5Mode: isEli5Mode ?? this.isEli5Mode,
      documentSummary: documentSummary ?? this.documentSummary,
      textSelectionRect: clearTextSelection
          ? null
          : textSelectionRect ?? this.textSelectionRect,
      selectedTextForBubble: clearTextSelection
          ? null
          : selectedTextForBubble ?? this.selectedTextForBubble,
      pickedPdfName: pickedPdfName ?? this.pickedPdfName,
    );
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
const uuid = Uuid();

class ReadingNotifier extends StateNotifier<ReadingState> {
  final GeminiService _geminiService;
  final Box<SavedNote> _notesBox;

  ReadingNotifier(this._geminiService, this._notesBox) : super(ReadingState()) {
    _loadNotes();
  }

  void _loadNotes() {
    state = state.copyWith(savedNotes: _notesBox.values.toList());
  }

  Future<void> pickPdf() async {
    state = state.copyWith(isLoadingDocument: true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name; // Get the file name
        // *** UPDATE STATE WITH FILE AND NAME ***
        state = state.copyWith(
          pickedPdfFile: file,
          pickedPdfName: fileName, // Store the name
          isLoadingDocument: false,
        );
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

  Future<void> saveCurrentExplanation() async {
    final explanationValue = state.explanation;
    final term = state.currentTerm;
    final docName = state.pickedPdfName; // Get the doc name from state

    if (explanationValue is AsyncData<String> &&
        term != null &&
        docName != null) {
      final newNote = SavedNote(
        id: uuid.v4(),
        term: term,
        explanation: explanationValue.value,
        createdAt: DateTime.now(),
        documentName: docName, // Pass the name to the model
      );
      await _notesBox.put(newNote.id, newNote);
      _loadNotes();
    }
  }

  // --- Other methods remain the same ---
  // ... showAiBubble, hideAiBubble, getExplanationForSelection, etc. ...
  void showAiBubble({required Rect rect, required String text}) {
    state =
        state.copyWith(textSelectionRect: rect, selectedTextForBubble: text);
  }

  void hideAiBubble() {
    state = state.copyWith(clearTextSelection: true);
  }

  Future<void> getExplanationForSelection(
      {required String term, required String fullText}) async {
    if (term.isEmpty) return;
    hideAiBubble();
    state =
        state.copyWith(explanation: const AsyncLoading(), currentTerm: term);
    try {
      final result = await _geminiService.getExplanation(
          mainText: fullText, term: term, isEli5: state.isEli5Mode);
      state = state.copyWith(explanation: AsyncData(result));
    } catch (e, st) {
      state = state.copyWith(explanation: AsyncError(e, st));
    }
  }

  Future<void> generateSummary({required String fullText}) async {
    state = state.copyWith(documentSummary: const AsyncLoading());
    try {
      final result = await _geminiService.getSummary(mainText: fullText);
      state = state.copyWith(documentSummary: AsyncData(result));
    } catch (e, st) {
      state = state.copyWith(documentSummary: AsyncError(e, st));
    }
  }

  void toggleEli5Mode() {
    state = state.copyWith(isEli5Mode: !state.isEli5Mode);
  }

  Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
    _loadNotes();
  }
}

final readingNotifierProvider =
    StateNotifierProvider<ReadingNotifier, ReadingState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  final notesBox = Hive.box<SavedNote>('notes');
  return ReadingNotifier(geminiService, notesBox);
});
