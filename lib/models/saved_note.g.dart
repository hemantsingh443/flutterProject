// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedNoteAdapter extends TypeAdapter<SavedNote> {
  @override
  final int typeId = 1;

  @override
  SavedNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedNote(
      id: fields[0] as String,
      term: fields[1] as String,
      explanation: fields[2] as String,
      createdAt: fields[3] as DateTime,
      documentName: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SavedNote obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.term)
      ..writeByte(2)
      ..write(obj.explanation)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.documentName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
