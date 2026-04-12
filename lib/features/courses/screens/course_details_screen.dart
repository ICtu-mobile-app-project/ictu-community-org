import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../controllers/course_details_controller.dart';
import '../models/student_course_overview.dart';
import 'course_notes_list_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key, this.role = UserRole.student});

  final UserRole role;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final CourseDetailsController _controller = CourseDetailsController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final StudentCourseOverview? selectedCourse =
            _controller.selectedCourse;
        return Container(
          color: const Color(0xFF0A0C10),
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                const Text(
                  'Course Tracker',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track your ICTU courses and keep up with key deadlines.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _controller.onSearchChanged,
                  style: const TextStyle(color: Color(0xFFF1F5F9)),
                  decoration: InputDecoration(
                    hintText: 'Search by ICTU course code or title',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_controller.isLoadingInitial)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF58220),
                      ),
                    ),
                  )
                else if (_controller.error != null)
                  _ErrorCard(
                    message: _controller.error!,
                    onRetry: _controller.loadInitial,
                  )
                else if (_controller.courses.isEmpty)
                  const _EmptyCoursesCard()
                else ...[
                  ..._controller.courses.map((StudentCourseOverview item) {
                    return _CourseProgressCard(
                      title: item.title,
                      code: item.code,
                      progress: item.progress,
                      lecturer: item.lecturer,
                      isSelected: selectedCourse?.id == item.id,
                      onTap: () => _controller.selectCourse(item),
                    );
                  }),
                  if (_controller.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _controller.isLoadingMore
                              ? null
                              : _controller.loadMore,
                          icon: _controller.isLoadingMore
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more_rounded),
                          label: Text(
                            _controller.isLoadingMore
                                ? 'Loading more...'
                                : 'Load more courses',
                          ),
                        ),
                      ),
                    ),
                  if (selectedCourse != null) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Course Materials',
                      style: TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...selectedCourse.materials.map((CourseMaterialItem item) {
                      return _MaterialTile(name: item.name, size: item.size);
                    }),
                    const SizedBox(height: 8),
                    _OpenNotesTile(course: selectedCourse, role: widget.role),
                    const SizedBox(height: 18),
                    const Text(
                      'Exams & Deadlines',
                      style: TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...selectedCourse.deadlines.map((CourseDeadlineItem item) {
                      return _DeadlineTile(
                        title: item.title,
                        due: item.due,
                        color: Color(item.colorHex),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OpenNotesTile extends StatelessWidget {
  const _OpenNotesTile({required this.course, required this.role});

  final StudentCourseOverview course;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CourseNotesListScreen(
              courseId: course.id,
              courseCode: course.code,
              role: role,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0x1AF58220),
          border: Border.all(color: const Color(0x33F58220)),
        ),
        child: const Row(
          children: [
            Icon(Icons.note_rounded, color: Color(0xFFF58220)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Open course notes list',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({
    required this.title,
    required this.code,
    required this.progress,
    required this.lecturer,
    required this.onTap,
    required this.isSelected,
  });

  final String title;
  final String code;
  final double progress;
  final String lecturer;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: isSelected ? 0.08 : 0.04),
          border: Border.all(
            color: isSelected
                ? const Color(0x66F59E0B)
                : Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              code,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              lecturer,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).round()}% completed',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x1AF87171),
        border: Border.all(color: const Color(0x66F87171)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Color(0xFFFECACA), fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyCoursesCard extends StatelessWidget {
  const _EmptyCoursesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Text(
        'No courses found. Try another search keyword.',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.name, required this.size});

  final String name;
  final String size;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x1AF59E0B),
            ),
            child: const Icon(
              Icons.file_present_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            size,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.title,
    required this.due,
    required this.color,
  });

  final String title;
  final String due;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  due,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
