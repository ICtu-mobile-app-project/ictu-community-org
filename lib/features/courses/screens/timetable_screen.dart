import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/user_role.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/timetable_controller.dart';
import '../data/timetable_repository.dart';
import '../models/schedule_item.dart';
import 'admin_timetable_management_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, this.userRole});

  final UserRole? userRole;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TimetableController _controller;
  
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: days.length, vsync: this);
    
    final repository = TimetableRepository(Supabase.instance.client);
    _controller = TimetableController(repository);
    
    _loadData();
  }

  Future<void> _loadData() async {
    UserRole? role = widget.userRole;
    String? lecturerName;

    if (role == null) {
      final authController = AuthController();
      role = await authController.restoreCurrentUserRole();
    }

    if (role == UserRole.lecturer) {
      final user = Supabase.instance.client.auth.currentUser;
      lecturerName = user?.userMetadata?['full_name'] as String?;
    }

    _controller.loadTimetable(role: role ?? UserRole.student, lecturerName: lecturerName);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0C10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Timetable',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.userRole == UserRole.admin)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminTimetableManagementScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.settings_suggest_rounded,
                      color: Color(0xFFF58220),
                      size: 20,
                    ),
                    tooltip: 'Manage Timetable',
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0x1AF58220),
                  ),
                  child: const Text(
                    'Spring 2026',
                    style: TextStyle(
                      color: Color(0xFFF58220),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: days.map((day) => Tab(text: day)).toList(),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFF59E0B),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF7E90AB),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              splashBorderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (_controller.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${_controller.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: days.map((day) => _buildDaySchedule(day)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final schedule = _controller.getSchedulesForDay(day);

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: schedule.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No classes scheduled for $day',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            : schedule.map((session) => _buildTimeSlot(session)).toList(),
      ),
    );
  }

  Widget _buildTimeSlot(ScheduleItem session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF111726), Color(0xFF1B1F2B)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      ),
                      child: Text(
                        session.timeRange,
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${session.courseCode}: ${session.courseName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (session.hall != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          session.hall!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                if (session.lecturer != null)
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          session.lecturer!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (session.groupName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        session.groupName!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (session.isEnrolled)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomRight: Radius.circular(40),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF9D42),
                      Color(0x00FF9D42),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
