import 'package:flutter/material.dart';
import 'package:ictu_community_org/features/alerts/screens/alert_details_screen.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/courses/controllers/course_details_controller.dart';
import 'package:ictu_community_org/features/courses/models/course_note.dart';
import 'package:ictu_community_org/features/courses/models/student_course_overview.dart';
import 'package:ictu_community_org/features/courses/screens/note_details_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({
    super.key,
    this.role = UserRole.student,
    this.initialCourseId,
  });

  final UserRole role;
  final String? initialCourseId;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final CourseDetailsController _controller = CourseDetailsController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadInitial(initialCourseId: widget.initialCourseId);
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

        if (_controller.isLoadingInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0C10),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFF58220))),
          );
        }

        if (_controller.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0C10),
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: _ErrorCard(
              message: _controller.error!,
              onRetry: _controller.loadInitial,
            ),
          );
        }

        if (selectedCourse == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0C10),
            body: Center(child: Text('Course not found', style: TextStyle(color: Colors.white))),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0C10),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              selectedCourse.code,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              children: [
                Text(
                  selectedCourse.title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                _LecturerInfoCard(
                  name: selectedCourse.lecturer,
                  courseTitle: selectedCourse.title,
                  description: selectedCourse.description,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Course Content',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                if (_controller.isWorking)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  if (selectedCourse.materials.isEmpty &&
                      selectedCourse.deadlines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_rounded, color: Colors.white10, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'No notes or assignments uploaded yet for this course.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  if (selectedCourse.materials.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Lecturer Notes',
                        style: TextStyle(
                          color: Color(0xFFF58220),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...selectedCourse.materials.map((item) => _MaterialTile(
                          item: item,
                          courseCode: selectedCourse.code,
                          role: widget.role,
                        )),
                    const SizedBox(height: 12),
                  ],
                  if (selectedCourse.deadlines.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child: Text(
                        'Assessments & Exams',
                        style: TextStyle(
                          color: Color(0xFFF58220),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...selectedCourse.deadlines.map((item) => _DeadlineTile(
                          title: item.title,
                          due: item.due,
                          type: item.type,
                          color: Color(item.colorHex),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AlertDetailsScreen(alertId: item.id),
                              ),
                            );
                          },
                        )),
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

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.isSelected,
    required this.onEnroll,
    required this.isWorking,
  });

  final StudentCourseOverview course;
  final VoidCallback onTap;
  final VoidCallback onEnroll;
  final bool isSelected;
  final bool isWorking;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.code,
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (course.isEnrolled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x1A22C55E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x3322C55E)),
                    ),
                    child: const Text(
                      'Enrolled',
                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              course.lecturer,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            if (!course.isEnrolled && isSelected) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isWorking ? null : onEnroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isWorking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enroll in Course', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnrollPromotionCard extends StatelessWidget {
  const _EnrollPromotionCard({
    required this.course,
    required this.onEnroll,
    required this.isLoading,
  });

  final StudentCourseOverview course;
  final VoidCallback onEnroll;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF58220).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF58220).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 48, color: Color(0xFFF58220)),
          const SizedBox(height: 16),
          Text(
            'Enroll in ${course.code}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Enroll to access lecturer notes, assignments, and exam schedules for this course.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onEnroll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF58220),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enroll Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
  const _EmptyCoursesCard({this.isMyCourses = false});

  final bool isMyCourses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(
            isMyCourses ? Icons.school_outlined : Icons.search_off_rounded,
            size: 48,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isMyCourses
                ? 'You haven\'t enrolled in any courses yet.'
                : 'No courses found. Try another search keyword.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChanged});

  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabItem(
          label: 'Available',
          isSelected: !selected,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 8),
        _TabItem(
          label: 'My Courses',
          isSelected: selected,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? const Color(0xFFF58220) : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: isSelected ? const Color(0xFFF58220) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _LecturerInfoCard extends StatelessWidget {
  const _LecturerInfoCard({
    required this.name,
    required this.courseTitle,
    required this.description,
  });

  final String name;
  final String courseTitle;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF58220).withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFFF58220),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Course Lecturer',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            courseTitle,
            style: const TextStyle(
              color: Color(0xFFF58220),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.item,
    required this.courseCode,
    required this.role,
  });

  final CourseMaterialItem item;
  final String courseCode;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoteDetailsScreen(
              note: CourseNote(
                id: item.id,
                courseId: '', // Filled by backend when needed
                courseCode: courseCode,
                title: item.name,
                description: '',
                contentUrl: item.path,
                fileName: item.name,
                fileSizeBytes: 0,
                uploadedBy: '',
                uploadedByName: '',
                createdAt: DateTime.now(),
              ),
              role: role,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0x1AF58220),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Color(0xFFF58220),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.title,
    required this.due,
    required this.type,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String due;
  final String type;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                type.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    due,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}
