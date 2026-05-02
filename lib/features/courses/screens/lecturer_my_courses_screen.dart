import 'package:flutter/material.dart';
import 'package:ictu_community_org/features/courses/screens/lecturer_course_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';
import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/glass_input.dart';
import 'package:ictu_community_org/features/courses/controllers/lecturer_courses_controller.dart';
import 'package:ictu_community_org/features/courses/data/in_memory_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/data/lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/data/supabase_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_overview.dart';
import 'package:ictu_community_org/features/courses/screens/create_course_screen.dart';

class LecturerMyCoursesScreen extends StatefulWidget {
  const LecturerMyCoursesScreen({super.key});

  @override
  State<LecturerMyCoursesScreen> createState() =>
      _LecturerMyCoursesScreenState();
}

class _LecturerMyCoursesScreenState extends State<LecturerMyCoursesScreen> {
  late final LecturerCoursesRepository _repository;
  late final LecturerCoursesController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String _lecturerId;
  late final String _lecturerName;

  @override
  void initState() {
    super.initState();

    _lecturerId = SupabaseBootstrap.isConfigured
        ? (Supabase.instance.client.auth.currentUser?.id ?? 'lecturer-1')
        : 'lecturer-1';
    _lecturerName = SupabaseBootstrap.isConfigured
        ? (Supabase.instance.client.auth.currentUser?.userMetadata?['full_name']
                  as String? ??
              'ICTU Lecturer')
        : 'Prof. Victor Mbarika';

    _repository = SupabaseBootstrap.isConfigured
        ? SupabaseLecturerCoursesRepository()
        : InMemoryLecturerCoursesRepository.instance;

    _controller = LecturerCoursesController(
      repository: _repository,
      lecturerId: _lecturerId,
    );
    _controller.initialize();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      _controller.loadMore();
    }
  }

  Future<void> _openCreateCourse() async {
    final LecturerCourse? created = await Navigator.of(context)
        .push<LecturerCourse>(
          MaterialPageRoute<LecturerCourse>(
            builder: (_) => const CreateCourseScreen(),
          ),
        );

    if (created == null) {
      return;
    }

    await _controller.refresh();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LecturerCourseDetailsScreen(
          course: LecturerCourseOverview(
            id: created.id,
            code: created.courseCode,
            title: created.title,
            description: created.description,
            semester: created.semester,
            students: created.studentCount,
            notes: created.notesCount,
            alerts: created.alertCount,
            lastActivity: created.lastActivity,
          ),
        ),
      ),
    );

    await _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCourse,
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create New Course'),
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'My Courses',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your ICTU courses, students and delegates.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 14),
              GlassInput(
                label: 'Search',
                controller: _searchController,
                icon: Icons.search_rounded,
                placeholder: 'Search by course code or title',
                onChanged: _controller.onSearchChanged,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.refresh,
                  color: AppColors.primaryContainer,
                  backgroundColor: const Color(0xFF1E293B),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _controller.isLoading,
                    builder: (_, bool isLoading, __) {
                      return ValueListenableBuilder<List<LecturerCourse>>(
                        valueListenable: _controller.items,
                        builder: (_, List<LecturerCourse> courses, __) {
                          return ValueListenableBuilder<String?>(
                            valueListenable: _controller.errorMessage,
                            builder: (_, String? error, __) {
                              if (error != null && courses.isEmpty) {
                                return SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    alignment: Alignment.center,
                                    child: Text(
                                      error,
                                      style: const TextStyle(color: Color(0xFFF87171)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              if (isLoading && courses.isEmpty) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryContainer,
                                  ),
                                );
                              }

                              if (courses.isEmpty) {
                                return SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: const Text(
                                      'No courses found. Tap "Create New Course" to start, or pull down to refresh.',
                                      style: TextStyle(color: Color(0xFF94A3B8)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isTablet = constraints.maxWidth >= 700;
                                  final int crossAxisCount = isTablet ? 3 : 2;

                                  return GridView.builder(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(bottom: 110),
                                    itemCount: courses.length + (_controller.hasMore.value ? 1 : 0),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 0.9,
                                    ),
                                    itemBuilder: (context, index) {
                                      if (index >= courses.length) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primaryContainer,
                                          ),
                                        );
                                      }

                                      final LecturerCourse course = courses[index];
                                      return _CourseCard(
                                        course: course,
                                        onTap: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => LecturerCourseDetailsScreen(
                                                course: LecturerCourseOverview(
                                                  id: course.id,
                                                  code: course.courseCode,
                                                  title: course.title,
                                                  description: course.description,
                                                  semester: course.semester,
                                                  students: course.studentCount,
                                                  notes: course.notesCount,
                                                  alerts: course.alertCount,
                                                  lastActivity: course.lastActivity,
                                                ),
                                              ),
                                            ),
                                          );
                                          _controller.refresh();
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final LecturerCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseCode,
              style: const TextStyle(
                color: Color(0xFFF58220),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            _meta('Students', course.studentCount.toString()),
            _meta('Lectures', course.lectureCount.toString()),
            const SizedBox(height: 4),
            Text(
              'Last activity: ${_date(course.lastActivity)}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime value) {
    final String y = value.year.toString();
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    final String hh = value.hour.toString().padLeft(2, '0');
    final String mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
