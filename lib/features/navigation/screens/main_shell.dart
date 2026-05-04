import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:ictu_community_org/core/widgets/app_bottom_nav.dart';
import 'package:ictu_community_org/features/alerts/screens/lecturer_alerts_list_screen.dart';
import 'package:ictu_community_org/features/alerts/screens/student_alerts_screen.dart';
import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/auth/screens/welcome_screen.dart';
import 'package:ictu_community_org/features/community/screens/community_feed_screen.dart';
import 'package:ictu_community_org/features/courses/screens/enrolled_courses_screen.dart';
import 'package:ictu_community_org/features/courses/screens/lecturer_my_courses_screen.dart';
import 'package:ictu_community_org/features/courses/screens/timetable_screen.dart';
import 'package:ictu_community_org/features/home/screens/admin_home_dashboard_screen.dart';
import 'package:ictu_community_org/features/home/screens/home_dashboard_screen.dart';
import 'package:ictu_community_org/features/home/screens/lecturer_home_dashboard_screen.dart';
import 'package:ictu_community_org/features/navigation/controllers/main_nav_controller.dart';
import 'package:ictu_community_org/features/news/screens/campus_news_screen.dart';
import 'package:ictu_community_org/core/utils/string_utils.dart';
import 'package:ictu_community_org/features/profile/controllers/profile_controller.dart';
import 'package:ictu_community_org/features/profile/screens/profile_screen.dart';
import 'package:ictu_community_org/features/transcription/screens/audio_ai_transcription_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.userRole = UserRole.student});

  final UserRole userRole;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final MainNavController _controller = MainNavController();
  final ProfileController _profileController = ProfileController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _profileController.loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDrawerMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _openProfileFromDrawer() async {
    Navigator.of(context).pop();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  Future<void> _openTranscriptionFromDrawer() async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AudioAiTranscriptionScreen(),
      ),
    );
  }

  Future<void> _openNewsFromDrawer() async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CampusNewsScreen(),
      ),
    );
  }

  Future<void> _openCommunityFromDrawer() async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CommunityFeedScreen(),
      ),
    );
  }

  Future<void> _logoutFromDrawer() async {
    if (_isLoggingOut) {
      return;
    }

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you want to logout from this account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

     final authController = Provider.of<AuthController>(context, listen: false);
     await authController.signOut();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget homePage = widget.userRole == UserRole.admin
        ? AdminHomeDashboardScreen(
            onOpenMenu: _openDrawerMenu,
          )
        : widget.userRole == UserRole.lecturer
            ? LecturerHomeDashboardScreen(
                onOpenSearch: () => _controller.setIndex(3),
                onOpenAlerts: () => _controller.setIndex(1),
                onOpenMenu: _openDrawerMenu,
              )
            : HomeDashboardScreen(
                onOpenSearch: () => _controller.setIndex(3),
                onOpenTimetable: () => _controller.setIndex(2),
                onOpenAlerts: () => _controller.setIndex(1),
                onOpenMenu: _openDrawerMenu,
                userRole: widget.userRole,
              );

    final List<Widget> pages = widget.userRole == UserRole.admin
        ? <Widget>[
            homePage,
            TimetableScreen(userRole: widget.userRole),
          ]
        : widget.userRole == UserRole.lecturer
            ? <Widget>[
                homePage,
                const LecturerAlertsListScreen(
                  courseCode: '',
                  courseTitle: null,
                ),
                TimetableScreen(userRole: widget.userRole),
                const LecturerMyCoursesScreen(),
              ]
            : <Widget>[
                homePage,
                const StudentAlertsScreen(),
                TimetableScreen(userRole: widget.userRole),
                const EnrolledCoursesScreen(),
              ];

    return ValueListenableBuilder<int>(
      valueListenable: _controller.currentIndex,
      builder: (BuildContext context, int index, Widget? child) {
        final List<AppBottomNavItem> navItems = widget.userRole == UserRole.admin
            ? const [
                AppBottomNavItem(
                  icon: Icons.dashboard_outlined,
                  filledIcon: Icons.dashboard,
                  label: 'Admin',
                ),
                AppBottomNavItem(
                  icon: Icons.calendar_month_outlined,
                  filledIcon: Icons.calendar_month,
                  label: 'Timetable',
                ),
              ]
            : widget.userRole == UserRole.lecturer
                ? const [
                    AppBottomNavItem(
                      icon: Icons.home_outlined,
                      filledIcon: Icons.home,
                      label: 'Home',
                    ),
                    AppBottomNavItem(
                      icon: Icons.notifications_active_outlined,
                      filledIcon: Icons.notifications_active,
                      label: 'Alerts',
                    ),
                    AppBottomNavItem(
                      icon: Icons.schedule_outlined,
                      filledIcon: Icons.schedule,
                      label: 'Timetable',
                    ),
                    AppBottomNavItem(
                      icon: Icons.menu_book_outlined,
                      filledIcon: Icons.menu_book,
                      label: 'Courses',
                    ),
                  ]
                : const [
                    AppBottomNavItem(
                      icon: Icons.home_outlined,
                      filledIcon: Icons.home,
                      label: 'Home',
                    ),
                    AppBottomNavItem(
                      icon: Icons.notifications_active_outlined,
                      filledIcon: Icons.notifications_active,
                      label: 'Alerts',
                    ),
                    AppBottomNavItem(
                      icon: Icons.schedule_outlined,
                      filledIcon: Icons.schedule,
                      label: 'Timetable',
                    ),
                    AppBottomNavItem(
                      icon: Icons.menu_book_outlined,
                      filledIcon: Icons.menu_book,
                      label: 'Courses',
                    ),
                  ];

        return Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: Drawer(
            backgroundColor: const Color(0xFF0A0C10),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _profileController,
                builder: (context, _) {
                  final profile = _profileController.profileData;
                  final fullName = profile?['full_name'] ?? 'User';

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        color: const Color(0xFF0A0C10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF1E293B),
                              child: Text(
                                initialsFromName(fullName),
                                style: const TextStyle(
                                  color: Color(0xFFF58220),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fullName,
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        iconColor: const Color(0xFFF1F5F9),
                        textColor: const Color(0xFFF1F5F9),
                        title: const Text('Profile'),
                        onTap: _openProfileFromDrawer,
                      ),
                      ListTile(
                        leading: const Icon(Icons.newspaper_outlined),
                        iconColor: const Color(0xFFF1F5F9),
                        textColor: const Color(0xFFF1F5F9),
                        title: const Text('Campus News'),
                        onTap: _openNewsFromDrawer,
                      ),
                      if (widget.userRole == UserRole.student)
                        ListTile(
                          leading: const Icon(Icons.groups_outlined),
                          iconColor: const Color(0xFFF1F5F9),
                          textColor: const Color(0xFFF1F5F9),
                          title: const Text('Community Feed'),
                          onTap: _openCommunityFromDrawer,
                        ),
                      if (widget.userRole == UserRole.student ||
                          widget.userRole == UserRole.lecturer)
                        ListTile(
                          leading: const Icon(Icons.auto_awesome_rounded),
                          iconColor: const Color(0xFFF58220),
                          textColor: const Color(0xFFF1F5F9),
                          title: const Text('AI Transcription'),
                          onTap: _openTranscriptionFromDrawer,
                        ),
                      ListTile(
                        leading: _isLoggingOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.logout_rounded),
                        iconColor: const Color(0xFFF1F5F9),
                        textColor: const Color(0xFFF1F5F9),
                        title: const Text('Logout'),
                        onTap: _isLoggingOut ? null : _logoutFromDrawer,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: pages[index],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: AppBottomNav(
              currentIndex: index,
              onTap: _controller.setIndex,
              items: navItems,
            ),
          ),
        );

      },
    );
  }
}
