import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/saved_note.dart';
import '../providers/reading_provider.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes =
        ref.watch(readingNotifierProvider.select((s) => s.savedNotes));

    // Group notes by document name for the new UI
    final Map<String, List<SavedNote>> groupedNotes = {};
    for (var note in notes) {
      (groupedNotes[note.documentName] ??= []).add(note);
    }

    // Sort documents by the most recent note within them
    final sortedDocNames = groupedNotes.keys.toList()
      ..sort((a, b) {
        final lastNoteA = groupedNotes[a]!
          ..sort((na, nb) => nb.createdAt.compareTo(na.createdAt));
        final lastNoteB = groupedNotes[b]!
          ..sort((na, nb) => nb.createdAt.compareTo(na.createdAt));
        return lastNoteB.first.createdAt.compareTo(lastNoteA.first.createdAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Notes'),
      ),
      body: notes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add_outlined,
                        size: 100, color: Colors.grey[700]),
                    const SizedBox(height: 24),
                    const Text('No Notes Yet',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Select text in a document and save the explanation to see your notes here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          // Build the new list of document groups
          : ListView.builder(
              itemCount: sortedDocNames.length,
              itemBuilder: (context, index) {
                final docName = sortedDocNames[index];
                final docNotes = groupedNotes[docName]!;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document Name Header
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 12.0, left: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(docName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // List of notes for this document
                        ...docNotes
                            .map((note) => _buildNoteTile(context, ref, note)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Builds a single, compact tile for a note in the main list.
  Widget _buildNoteTile(BuildContext context, WidgetRef ref, SavedNote note) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      title:
          Text(note.term, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        note.explanation,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
      ),
      trailing: IconButton(
        icon:
            const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
        onPressed: () => _showDeleteConfirmation(context, ref, note.id),
      ),
      onTap: () => _showNoteDetailsDialog(context, note),
    );
  }

  /// Shows the new, scrollable dialog with styled content when a note is tapped.
  void _showNoteDetailsDialog(BuildContext context, SavedNote note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          // We don't need a title, the content is more expressive.
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            // **CRASH FIX**: This makes the content scrollable if it's too long.
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **UI REDESIGN**: The term, styled as requested.
                  Text(
                    note.term,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration: TextDecoration.underline, // Underline added
                      decorationThickness: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // The full explanation
                  Text(note.explanation, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CLOSE"),
            ),
          ],
        );
      },
    );
  }

  /// Shows the standard confirmation dialog for deleting a note.
  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, String noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: const Text(
              'Are you sure you want to delete this note? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
              onPressed: () {
                ref.read(readingNotifierProvider.notifier).deleteNote(noteId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
