import 'package:flutter/material.dart';
import '../../auth/models/user_role.dart';
import '../controllers/course_details_controller.dart';
import '../models/student_course_overview.dart';
import 'course_details_screen.dart';

class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final CourseDetailsController _controller = CourseDetailsController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Force available courses view (not "My Courses")
    if (_controller.showOnlyMyCourses) {
      _controller.toggleMyCourses(false);
    } else {
      _controller.loadInitial();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Discover Courses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: _controller.onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search course code or title...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.refresh,
                  child: _buildContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoadingInitial) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF58220)));
    }

    if (_controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_controller.error!, style: const TextStyle(color: Colors.white)),
            TextButton(onPressed: _controller.refresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_controller.courses.isEmpty) {
      return const Center(
        child: Text('No courses found for your major.', style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _controller.courses.length + (_controller.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _controller.courses.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _controller.isLoadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(onPressed: _controller.loadMore, child: const Text('Load More')),
            ),
          );
        }

        final course = _controller.courses[index];
        return _SearchCourseCard(
          course: course,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailsScreen(
                  role: UserRole.student,
                  initialCourseId: course.id,
                ),
              ),
            );
          },
          onEnroll: () => _controller.enroll(course),
          isWorking: _controller.isWorking && _controller.selectedCourse?.id == course.id,
        );
      },
    );
  }
}

class _SearchCourseCard extends StatelessWidget {
  const _SearchCourseCard({
    required this.course,
    required this.onTap,
    required this.onEnroll,
    required this.isWorking,
  });

  final StudentCourseOverview course;
  final VoidCallback onTap;
  final VoidCallback onEnroll;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF58220).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.code,
                        style: const TextStyle(
                          color: Color(0xFFF58220),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (course.isEnrolled)
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Enrolled',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course.lecturer,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                if (!course.isEnrolled) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isWorking ? null : onEnroll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF58220),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isWorking
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Enroll Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
