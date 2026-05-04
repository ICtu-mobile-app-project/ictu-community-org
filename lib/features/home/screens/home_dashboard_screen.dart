import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/utils/string_utils.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/features/alerts/models/alert_item.dart';
import 'package:ictu_community_org/features/alerts/screens/lecturer_alerts_list_screen.dart';
import 'package:ictu_community_org/features/alerts/screens/student_alerts_screen.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/courses/controllers/enrolled_courses_controller.dart';
import 'package:ictu_community_org/features/courses/models/student_course_overview.dart';
import 'package:ictu_community_org/features/courses/screens/course_details_screen.dart';
import 'package:ictu_community_org/features/courses/screens/course_search_screen.dart';
import 'package:ictu_community_org/features/notifications/screens/notifications_screen.dart';
import 'package:ictu_community_org/features/profile/controllers/profile_controller.dart';
import 'package:ictu_community_org/features/profile/screens/profile_screen.dart';
import 'package:ictu_community_org/features/transcription/screens/audio_ai_transcription_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onOpenSearch,
    required this.onOpenTimetable,
    this.onOpenAlerts,
    this.onOpenMenu,
    this.userRole = UserRole.student,
    this.userDisplayName,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenTimetable;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenMenu;
  final UserRole userRole;
  final String? userDisplayName;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final EnrolledCoursesController _enrolledCoursesController =
      EnrolledCoursesController();
  final ProfileController _profileController = ProfileController();

  @override
  void initState() {
    super.initState();
    _enrolledCoursesController.loadEnrolledCourses();
    _profileController.loadProfile();
  }

  @override
  void dispose() {
    _enrolledCoursesController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _enrolledCoursesController,
        _profileController,
      ]),
      builder: (context, _) {
        final profile = _profileController.profileData;
        final displayName = profile?['full_name'] ??
            widget.userDisplayName ??
            _defaultDisplayName;

        return AmbientBackground(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 116, 24, 120),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Day',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.userRole == UserRole.lecturer)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1A60A5FA),
                            borderRadius: BorderRadius.circular(999),
                            border:
                                Border.all(color: const Color(0x6660A5FA)),
                          ),
                          child: const Text(
                            'Lecturer Dashboard',
                            style: TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF141821), Color(0xFF1D2230)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CourseSearchScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF58220,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFFF58220),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Search courses, news, resources',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.north_east_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Text(
                        'University News',
                        style: TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.45,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onOpenSearch,
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Color(0xFFF58220),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 176,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _NewsCard(
                          category: 'ANNOUNCEMENT',
                          categoryColor: Color(0xFFF58220),
                          title: 'ICTU Awarded Best Regional University 2024',
                          description:
                              'The Excellence in Higher Education commission has recognized ICTU for its impact and innovation.',
                          tintColor: Color(0x1AF58220),
                          borderColor: Color(0x33F58220),
                          glowColor: Color(0x33F58220),
                        ),
                        SizedBox(width: 16),
                        _NewsCard(
                          category: 'CONFERENCE',
                          categoryColor: Color(0xFF3B82F6),
                          title: 'Next Global ICT Summit Registration Open',
                          description:
                              'Join global leaders at our annual summit and connect with research and industry experts.',
                          tintColor: Color(0x08FFFFFF),
                          borderColor: Color(0x14FFFFFF),
                          glowColor: Color(0x1A3B82F6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Text(
                        'Active Courses',
                        style: TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.45,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1AF58220),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_enrolledCoursesController.enrolledCourses.length} Enrolled',
                          style: const TextStyle(
                            color: Color(0xFFF58220),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Enrolled Courses List
                  if (_enrolledCoursesController.isLoading && _enrolledCoursesController.enrolledCourses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: Color(0xFFF58220)),
                      ),
                    )
                  else if (_enrolledCoursesController.enrolledCourses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.school_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'No courses enrolled yet',
                            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CourseSearchScreen()),
                              );
                            },
                            child: const Text('Explore Courses', style: TextStyle(color: Color(0xFFF58220))),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._enrolledCoursesController.enrolledCourses.take(3).map((course) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CourseTile(
                        course: course,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourseDetailsScreen(initialCourseId: course.id),
                            ),
                          );
                        },
                      ),
                    )),

                  const SizedBox(height: 32),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickAction(
                        icon: Icons.calendar_month_rounded,
                        label: 'Schedule',
                        color: const Color(0xFFFB7185),
                        onTap: widget.onOpenTimetable,
                      ),
                      _QuickAction(
                        icon: Icons.assignment_rounded,
                        label: 'Exams',
                        color: const Color(0xFF38BDF8),
                        onTap: widget.onOpenAlerts ?? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const StudentAlertsScreen(
                                initialType: AlertType.exam,
                              ),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Finances',
                        color: const Color(0xFFFBBF24),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Finances feature coming soon')),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.school_rounded,
                        label: 'Library',
                        color: const Color(0xFFA78BFA),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Library feature coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                  if (widget.userRole == UserRole.lecturer ||
                      widget.userRole.isDelegate) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0x1AF58220),
                        border: Border.all(color: const Color(0x33F58220)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AudioAiTranscriptionScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFF58220),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Audio/AI Transcription',
                                    style: TextStyle(
                                      color: Color(0xFFF1F5F9),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.north_east_rounded,
                                  color: Color(0xFFF1F5F9),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (widget.userRole.isDelegate) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0x1410B981),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Color(0xFF34D399),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delegate Controls',
                                  style: TextStyle(
                                    color: Color(0xFFF1F5F9),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Moderate class channel and pin key updates.',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              // Fixed profile icon in top-left corner
              Positioned(
                top: 56,
                left: 24,
                child: GestureDetector(
                  onTap: () {
                    if (widget.onOpenMenu != null) {
                      widget.onOpenMenu!();
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF58220),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF1E293B),
                          child: Text(
                            initialsFromName(displayName),
                            style: const TextStyle(
                              color: Color(0xFFF58220),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0A0C10),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Fixed notification icon in top-right corner
              Positioned(
                top: 56,
                right: 24,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _defaultDisplayName {
    if (widget.userRole == UserRole.lecturer) {
      return 'Lecturer';
    }
    if (widget.userRole.isDelegate) {
      return 'Delegate';
    }
    return 'Student';
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.category,
    required this.categoryColor,
    required this.title,
    required this.description,
    required this.tintColor,
    required this.borderColor,
    required this.glowColor,
  });

  final String category;
  final Color categoryColor;
  final String title;
  final String description;
  final Color tintColor;
  final Color borderColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: tintColor,
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -47,
            top: -47,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: glowColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                category,
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.onTap,
  });

  final StudentCourseOverview course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Generate simple icon and color based on course title or id
    final List<IconData> icons = [
      Icons.terminal_rounded,
      Icons.folder_copy_rounded,
      Icons.brush_rounded,
      Icons.architecture_rounded,
      Icons.cloud_queue_rounded,
    ];
    final List<Color> colors = [
      const Color(0xFF818CF8),
      const Color(0xFF34D399),
      const Color(0xFFFB923C),
      const Color(0xFFF472B6),
      const Color(0xFF38BDF8),
    ];
    
    final index = course.id.hashCode % icons.length;
    final icon = icons[index];
    final color = colors[index];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.lecturer,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: course.progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(course.progress * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.description_outlined, size: 10, color: color),
                      const SizedBox(width: 2),
                      Text(
                        '${course.notesCount}',
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
