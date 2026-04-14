import 'package:flutter_test/flutter_test.dart';
import 'package:ictu_community_org/features/courses/data/in_memory_lecturer_courses_repository.dart';

void main() {
  test('repository paginates my courses and supports search', () async {
    final repo = InMemoryLecturerCoursesRepository.instance;

    final firstPage = await repo.getMyCourses(
      lecturerId: 'lecturer-1',
      page: 0,
      limit: 2,
      searchQuery: '',
    );

    expect(firstPage.items.length, 2);
    expect(firstPage.hasMore, isTrue);

    final filtered = await repo.getMyCourses(
      lecturerId: 'lecturer-1',
      page: 0,
      limit: 20,
      searchQuery: 'Artificial',
    );

    expect(filtered.items.length, 1);
    expect(filtered.items.first.courseCode, 'CSC4121');
  });
}
