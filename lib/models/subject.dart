import 'dart:convert';
import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final int colorValue;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
  });

  IconData get icon {
    if (iconCodePoint == Icons.calculate_outlined.codePoint) return Icons.calculate_outlined;
    if (iconCodePoint == Icons.science_outlined.codePoint) return Icons.science_outlined;
    if (iconCodePoint == Icons.menu_book_rounded.codePoint) return Icons.menu_book_rounded;
    if (iconCodePoint == Icons.public_rounded.codePoint) return Icons.public_rounded;
    if (iconCodePoint == Icons.auto_stories.codePoint) return Icons.auto_stories;
    if (iconCodePoint == Icons.biotech.codePoint) return Icons.biotech;
    if (iconCodePoint == Icons.computer.codePoint) return Icons.computer;
    if (iconCodePoint == Icons.psychology.codePoint) return Icons.psychology;
    if (iconCodePoint == Icons.history_edu.codePoint) return Icons.history_edu;
    if (iconCodePoint == Icons.menu_book.codePoint) return Icons.menu_book;
    return Icons.school;
  }
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      iconCodePoint: map['iconCodePoint'] as int? ?? Icons.school.codePoint,
      colorValue: map['colorValue'] as int? ?? 0xFF159A8C,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Subject.fromJson(String source) =>
      Subject.fromMap(json.decode(source) as Map<String, dynamic>);
}
