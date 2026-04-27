import 'package:flutter/material.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/alerts/screens/lecturer_alerts_list_screen.dart';
import 'package:ictu_community_org/features/courses/data/supabase_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/data/lecturer_courses_repository.dart';
import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';
import 'package:ictu_community_org/features/courses/data/in_memory_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/models/course_student.dart';
import 'package:ictu_community_org/features/courses/models/course_delegate.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_overview.dart';
import 'package:ictu_community_org/features/courses/screens/course_notes_list_screen.dart';
import 'dart:async';

class LecturerCourseDetailsScreen extends StatefulWidget {
  const LecturerCourseDetailsScreen({
    super.key,
    required this.course,
  });

  final LecturerCourseOverview course;

  @override
  State<LecturerCourseDetailsScreen> createState() =>
      _LecturerCourseDetailsScreenState();
}

class _LecturerCourseDetailsScreenState
    extends State<LecturerCourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.course.code),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF58220),
          labelColor: const Color(0xFFF58220),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'Content'),
            Tab(text: 'Notes'),
            Tab(text: 'Alerts'),
            Tab(text: 'Students'),
            Tab(text: 'Delegates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentTab(),
          CourseNotesListScreen(
            courseId: widget.course.id,
            courseCode: widget.course.code,
            role: UserRole.lecturer,
          ),
          LecturerAlertsListScreen(
            courseCode: widget.course.code,
            courseTitle: widget.course.title,
          ),
          _buildStudentsTab(),
          _buildDelegatesTab(),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.course.semester,
            style: const TextStyle(color: Color(0xFFF58220), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          const Text(
            'Course Description',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.course.description.isEmpty 
              ? 'No description provided for this course.' 
              : widget.course.description,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          _buildStatTile(Icons.people_outline, 'Students Enrolled', '${widget.course.students}'),
          _buildStatTile(Icons.assignment_outlined, 'Course Materials', '${widget.course.notes}'),
          _buildStatTile(Icons.notification_important_outlined, 'Active Alerts', '${widget.course.alerts}'),
        ],
      ),
    );
  }

  Widget _buildStatTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF58220)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    return _StudentsTab(courseId: widget.course.id);
  }

  Widget _buildDelegatesTab() {
    return _DelegatesTab(
      courseId: widget.course.id,
      courseCode: widget.course.code,
    );
  }
}

class _StudentsTab extends StatefulWidget {
  const _StudentsTab({required this.courseId});
  final String courseId;

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  late final LecturerCoursesRepository _repository;
  late Future<List<CourseStudent>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseBootstrap.isConfigured
        ? SupabaseLecturerCoursesRepository()
        : InMemoryLecturerCoursesRepository.instance;
    _studentsFuture = _repository.getEnrolledStudents(widget.courseId);
  }

  void _refresh() {
    setState(() {
      _studentsFuture = _repository.getEnrolledStudents(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseStudent>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF58220)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFF87171)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const Center(
            child: Text(
              'No students enrolled in this course yet.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: const Color(0xFFF58220),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final student = students[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFF58220).withOpacity(0.1),
                      child: Text(
                        student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFFF58220), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student.email,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DelegatesTab extends StatefulWidget {
  const _DelegatesTab({
    required this.courseId,
    required this.courseCode,
  });

  final String courseId;
  final String courseCode;

  @override
  State<_DelegatesTab> createState() => _DelegatesTabState();
}

class _DelegatesTabState extends State<_DelegatesTab> {
  late final LecturerCoursesRepository _repository;
  late Future<List<CourseDelegate>> _delegatesFuture;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseBootstrap.isConfigured
        ? SupabaseLecturerCoursesRepository()
        : InMemoryLecturerCoursesRepository.instance;
    _delegatesFuture = _repository.getDelegates(widget.courseId);
  }

  void _refresh() {
    setState(() {
      _delegatesFuture = _repository.getDelegates(widget.courseId);
    });
  }

  Future<void> _removeDelegate(CourseDelegate delegate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Remove Delegate', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${delegate.studentName} as a delegate for ${widget.courseCode}?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRemoving = true);
    try {
      await _repository.removeDelegate(
        courseId: widget.courseId,
        studentId: delegate.studentId,
      );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${delegate.studentName} removed as delegate')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  Future<void> _showAssignDialog() async {
    final student = await showDialog<CourseStudent>(
      context: context,
      builder: (context) => _AssignDelegateDialog(repository: _repository),
    );

    if (student == null) return;

    try {
      await _repository.assignDelegate(
        courseId: widget.courseId,
        studentId: student.id,
      );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.fullName} assigned as delegate')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAssignDialog,
        backgroundColor: const Color(0xFFF58220),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<CourseDelegate>>(
        future: _delegatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF58220)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFF87171)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final delegates = snapshot.data ?? [];

          if (delegates.isEmpty) {
            return const Center(
              child: Text(
                'No delegates assigned for this course.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: const Color(0xFFF58220),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: delegates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final delegate = delegates[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFF58220).withOpacity(0.1),
                        child: Text(
                          delegate.studentName.isNotEmpty ? delegate.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Color(0xFFF58220), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    delegate.studentName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF58220).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Delegate',
                                    style: TextStyle(
                                      color: Color(0xFFF58220),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              delegate.studentEmail,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFF87171), size: 20),
                        onPressed: _isRemoving ? null : () => _removeDelegate(delegate),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AssignDelegateDialog extends StatefulWidget {
  const _AssignDelegateDialog({required this.repository});
  final LecturerCoursesRepository repository;

  @override
  State<_AssignDelegateDialog> createState() => _AssignDelegateDialogState();
}

class _AssignDelegateDialogState extends State<_AssignDelegateDialog> {
  final _searchController = TextEditingController();
  List<CourseStudent> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 2) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      try {
        final results = await widget.repository.searchStudents(query);
        setState(() => _searchResults = results);
      } catch (e) {
        debugPrint('Search error: $e');
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0C10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign New Delegate',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF58220)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFF58220)))
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.length < 2
                                ? 'Type at least 2 characters'
                                : 'No students found',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final student = _searchResults[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF58220).withOpacity(0.1),
                                child: Text(
                                  student.fullName[0].toUpperCase(),
                                  style: const TextStyle(color: Color(0xFFF58220)),
                                ),
                              ),
                              title: Text(student.fullName, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(student.email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              onTap: () => Navigator.pop(context, student),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
