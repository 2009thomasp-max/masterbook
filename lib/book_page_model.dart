import 'package:hive/hive.dart';

part 'book_page_model.g.dart';

@HiveType(typeId: 0)
class BookPageModel extends HiveObject {
  @HiveField(0)
  final String chapter;

  @HiveField(1)
  final String subheading;

  @HiveField(2)
  final String english;

  @HiveField(3)
  final String malayalam;

  @HiveField(4)
  final String reference;

  BookPageModel({
    required this.chapter,
    required this.subheading,
    required this.english,
    required this.malayalam,
    required this.reference,
  });

  Map<String, dynamic> toMap() {
    return {
      'chapter': chapter,
      'subheading': subheading,
      'english': english,
      'malayalam': malayalam,
      'reference': reference,
    };
  }

  factory BookPageModel.fromMap(Map<dynamic, dynamic> map) {
    return BookPageModel(
      chapter: map['chapter'] ?? '',
      subheading: map['subheading'] ?? '',
      english: map['english'] ?? '',
      malayalam: map['malayalam'] ?? '',
      reference: map['reference'] ?? '',
    );
  }
}