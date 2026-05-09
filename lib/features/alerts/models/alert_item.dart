import 'package:flutter/material.dart';

enum AlertType { assignment, ca, exam, notice }

AlertType alertTypeFromDb(String value) {
  switch (value.trim().toLowerCase()) {
    case 'assignment':
      return AlertType.assignment;
    case 'ca':
      return AlertType.ca;
    case 'exam':
      return AlertType.exam;
    default:
      return AlertType.notice;
  }
}

String alertTypeToDb(AlertType type) {
  switch (type) {
    case AlertType.assignment:
      return 'assignment';
    case AlertType.ca:
      return 'ca';
    case AlertType.exam:
      return 'exam';
    case AlertType.notice:
      return 'notice';
  }
}

String alertTypeLabel(AlertType type) {
  switch (type) {
    case AlertType.assignment:
      return 'Assignment';
    case AlertType.ca:
      return 'CA';
    case AlertType.exam:
      return 'Exam';
    case AlertType.notice:
      return 'Notice';
  }
}

Color alertTypeTint(AlertType type) {
  switch (type) {
    case AlertType.assignment:
      return const Color(0x1ADC2626);
    case AlertType.ca:
      return const Color(0x1AFBBF24);
    case AlertType.exam:
      return const Color(0x1A7C3AED);
    case AlertType.notice:
      return const Color(0x1A2E75B6);
  }
}

Color alertTypeAccent(AlertType type) {
  switch (type) {
    case AlertType.assignment:
      return const Color(0xFFDC2626);
    case AlertType.ca:
      return const Color(0xFFFBBF24);
    case AlertType.exam:
      return const Color(0xFF7C3AED);
    case AlertType.notice:
      return const Color(0xFF2E75B6);
  }
}

String getDeadlineText(DateTime deadline) {
  final DateTime now = DateTime.now();
  final Duration difference = deadline.difference(now);

  if (difference.isNegative) {
    final Duration overdue = now.difference(deadline);
    if (overdue.inDays > 0) {
      return 'Overdue by ${overdue.inDays} days';
    }
    if (overdue.inHours > 0) {
      return 'Overdue by ${overdue.inHours} hours';
    }
    return 'Overdue by ${overdue.inMinutes} minutes';
  }

  if (difference.inDays > 0) {
    return 'Due in ${difference.inDays} days';
  }
  if (difference.inHours > 0) {
    return 'Due in ${difference.inHours} hours';
  }
  return 'Due in ${difference.inMinutes} minutes';
}

Color getDeadlineColor(DateTime deadline) {
  final Duration difference = deadline.difference(DateTime.now());
  if (difference.isNegative) {
    return const Color(0xFFDC2626);
  }
  if (difference.inDays <= 1) {
    return const Color(0xFFFBBF24);
  }
  return const Color(0xFF94A3B8);
}

class AlertItem {
  const AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.courseCode,
    required this.createdAt,
    this.deadline,
    this.requirements = const <String>[],
    this.submissionLink,
  });

  final String id;
  final String title;
  final String description;
  final AlertType type;
  final String courseCode;
  final DateTime createdAt;
  final DateTime? deadline;
  final List<String> requirements;
  final String? submissionLink;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    final dynamic requirementsRaw = json['requirements'];
    final List<String> requirements = requirementsRaw is List<dynamic>
        ? requirementsRaw.map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];

    return AlertItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: alertTypeFromDb((json['type'] ?? 'notice').toString()),
      courseCode: (json['course_code'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      deadline: DateTime.tryParse((json['deadline'] ?? '').toString()),
      requirements: requirements,
      submissionLink: json['submission_link']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': alertTypeToDb(type),
      'course_code': courseCode,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'requirements': requirements,
      'submission_link': submissionLink,
    };
  }
}

