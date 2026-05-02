import 'package:ictu_community_org/features/courses/models/course_note.dart';

abstract class CourseNotesRepository {
  Future<List<CourseNote>> listNotes({
    required String courseId,
    String searchQuery = '',
    String sort = 'newest',
  });

  Future<CourseNote> createNote({
    required String courseId,
    required String title,
    String? description,
    String? summary,
    String status = 'published',
    required String contentUrl,
    required String fileName,
    required int fileSizeBytes,
  });

  Future<CourseNote> updateNote({
    required String noteId,
    String? title,
    String? description,
    String? summary,
    String? status,
  });

  Future<void> deleteNote({required String noteId});

  Future<String> createDownloadUrl({required String noteId});
}
