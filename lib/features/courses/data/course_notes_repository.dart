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
    required String description,
    required String contentUrl,
    required String fileName,
    required int fileSizeBytes,
  });

  Future<CourseNote> updateNoteTitle({
    required String noteId,
    required String newTitle,
  });

  Future<void> deleteNote({required String noteId});

  Future<String> createDownloadUrl({required String noteId});
}
