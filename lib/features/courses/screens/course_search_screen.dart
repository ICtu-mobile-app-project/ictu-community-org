import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/app_top_bar.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';
import 'package:ictu_community_org/core/widgets/glass_input.dart';
import 'package:ictu_community_org/core/widgets/primary_button.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/courses/controllers/course_details_controller.dart';
import 'package:ictu_community_org/features/courses/models/student_course_overview.dart';
import 'package:ictu_community_org/features/courses/screens/course_details_screen.dart';

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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: const AppTopBar(showBack: true, title: 'Discover Courses'),
      body: AmbientBackground(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: GlassInput(
                      label: 'Search',
                      controller: _searchController,
                      icon: Icons.search_rounded,
                      placeholder: 'Search course code or title...',
                      onChanged: _controller.onSearchChanged,
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _controller.refresh,
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoadingInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryContainer),
      );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderRadius: 20,
        padding: EdgeInsets.zero,
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
                          color: AppColors.primaryContainer.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.code,
                          style: const TextStyle(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (course.isEnrolled)
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Color(0xFF22C55E), size: 16),
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
                    PrimaryButton(
                      label: 'Enroll now',
                      onTap: isWorking ? null : onEnroll,
                      isLoading: isWorking,
                      height: 44,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
