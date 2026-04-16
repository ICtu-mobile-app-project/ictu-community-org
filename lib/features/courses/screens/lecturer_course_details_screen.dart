import 'package:flutter/material.dart';
import '../../auth/models/user_role.dart';
import '../../alerts/screens/lecturer_alerts_list_screen.dart';
import '../models/lecturer_course_overview.dart';
import 'course_notes_list_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
    return const Center(
      child: Text('Student management coming soon', style: TextStyle(color: Color(0xFF94A3B8))),
    );
  }
}
