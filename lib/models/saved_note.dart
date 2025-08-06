import 'package:hive/hive.dart';

part 'saved_note.g.dart';

@HiveType(typeId: 1)
class SavedNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String term;

  @HiveField(2)
  final String explanation;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String documentName;

  SavedNote({
    required this.id,
    required this.term,
    required this.explanation,
    required this.createdAt,
    required this.documentName, // Add to constructor
  });
}
