import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/utils/string_utils.dart';
import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/features/courses/data/in_memory_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/data/lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/data/supabase_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/screens/upload_notes_screen.dart';
import 'package:ictu_community_org/features/notifications/screens/notifications_screen.dart';
import 'package:ictu_community_org/features/profile/controllers/profile_controller.dart';
import 'package:ictu_community_org/features/profile/screens/profile_screen.dart';

class LecturerHomeDashboardScreen extends StatefulWidget {
  const LecturerHomeDashboardScreen({
    super.key,
    required this.onOpenSearch,
    this.onOpenAlerts,
    this.onOpenMenu,
    this.userDisplayName,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenMenu;
  final String? userDisplayName;

  @override
  State<LecturerHomeDashboardScreen> createState() =>
      _LecturerHomeDashboardScreenState();
}

class _LecturerHomeDashboardScreenState extends State<LecturerHomeDashboardScreen> {
  late final LecturerCoursesRepository _coursesRepository;
  final ProfileController _profileController = ProfileController();

  Timer? _reconnectTimer;
  late Future<int> _coursesCountFuture;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();

    _coursesRepository = SupabaseBootstrap.isConfigured
        ? SupabaseLecturerCoursesRepository()
        : InMemoryLecturerCoursesRepository.instance;

    _coursesCountFuture = _loadCoursesCount();
    _profileController.loadProfile();
    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(_checkConnectionAndRefresh()),
    );
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _profileController.dispose();
    super.dispose();
  }

  Future<int> _loadCoursesCount() async {
    try {
      final int count = await _coursesRepository.getMyCoursesCount();
      _wasOffline = false;
      return count;
    } catch (_) {
      _wasOffline = true;
      rethrow;
    }
  }

  Future<void> _checkConnectionAndRefresh() async {
    bool online = false;
    try {
      final List<InternetAddress> lookup = await InternetAddress.lookup(
        'google.com',
      );
      online = lookup.isNotEmpty;
    } on SocketException {
      online = false;
    }

    if (online && _wasOffline) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coursesCountFuture = _loadCoursesCount();
      });
      return;
    }
    _wasOffline = !online;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _profileController,
      builder: (context, _) {
        final profile = _profileController.profileData;
        final displayName = profile?['full_name'] ?? widget.userDisplayName ?? 'Lecturer';

        return AmbientBackground(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 60),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Day',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x1AF58220),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0x55F58220)),
                            ),
                            child: const Text(
                              'Lecturer Dashboard',
                              style: TextStyle(
                                color: Color(0xFFFED7AA),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '2 classes scheduled • 1 pending note approval',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<int>(
                          future: _coursesCountFuture,
                          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                            final String coursesValue = snapshot.hasData
                                ? snapshot.data!.toString()
                                : snapshot.hasError
                                ? '-'
                                : '...';

                            return Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Courses',
                                    value: coursesValue,
                                    tint: const Color(0xFF60A5FA),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: _MetricCard(
                                    label: 'Students',
                                    value: '-',
                                    tint: Color(0xFF22D3EE),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: _MetricCard(
                                    label: 'Delegates',
                                    value: '-',
                                    tint: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Academic Control',
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
                          'Open All',
                          style: TextStyle(
                            color: Color(0xFFF58220),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.menu_book_rounded,
                          label: 'My Courses',
                          onTap: widget.onOpenSearch,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.notifications_active_rounded,
                          label: 'Alerts',
                          onTap: widget.onOpenAlerts,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.note_add_rounded,
                          label: 'Upload Notes',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const UploadNotesScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.groups_rounded,
                          label: 'Delegates',
                          onTap: widget.onOpenSearch, // Redirect to my courses to select a course
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Spacer(flex: 2),
                      const SizedBox(width: 10),
                      const Spacer(flex: 2),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Teaching Queue',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _QueueTile(
                    course: 'SEN3141 • Software Design and Modelling',
                    info: 'Next class • 10:00 AM • Hall B2',
                    status: 'Ready',
                  ),
                  const SizedBox(height: 10),
                  const _QueueTile(
                    course: 'ICT2111 • Technical Writing for Engineers',
                    info: 'Notes upload pending review',
                    status: 'Pending',
                  ),
                  const SizedBox(height: 10),
                  const _QueueTile(
                    course: 'CSC4121 • Artificial Intelligence',
                    info: 'Delegate assignment update required',
                    status: 'Action',
                  ),
                ],
              ),
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
                  child: Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF58220), width: 2),
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
                ),
              ),
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
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: tint, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.adjust_rounded, color: Color(0xFFF58220), size: 0),
            Icon(icon, color: const Color(0xFFF58220), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.course,
    required this.info,
    required this.status,
  });

  final String course;
  final String info;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0x1AF58220),
            ),
            child: const Icon(
              Icons.class_rounded,
              color: Color(0xFFF58220),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  info,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0x1AF58220),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFFF58220),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
