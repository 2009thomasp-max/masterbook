// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_page_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookPageModelAdapter extends TypeAdapter<BookPageModel> {
  @override
  final int typeId = 0;

  @override
  BookPageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookPageModel(
      chapter: fields[0] as String,
      subheading: fields[1] as String,
      english: fields[2] as String,
      malayalam: fields[3] as String,
      reference: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BookPageModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.chapter)
      ..writeByte(1)
      ..write(obj.subheading)
      ..writeByte(2)
      ..write(obj.english)
      ..writeByte(3)
      ..write(obj.malayalam)
      ..writeByte(4)
      ..write(obj.reference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookPageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
