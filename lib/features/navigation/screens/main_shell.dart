import 'package:flutter/material.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_role.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../community/screens/community_feed_screen.dart';
<<<<<<< Updated upstream
import '../../courses/screens/enrolled_courses_screen.dart';
import '../../courses/screens/lecturer_courses_screen.dart';
=======
import '../../courses/screens/course_details_screen.dart';
import '../../courses/screens/lecturer_my_courses_screen.dart';
>>>>>>> Stashed changes
import '../../courses/screens/timetable_screen.dart';
import '../../home/screens/home_dashboard_screen.dart';
import '../../home/screens/lecturer_home_dashboard_screen.dart';
import '../../home/screens/admin_home_dashboard_screen.dart';
import '../../news/screens/campus_news_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../transcription/screens/audio_ai_transcription_screen.dart';
import '../controllers/main_nav_controller.dart';
import '../../alerts/screens/lecturer_alerts_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.userRole = UserRole.student});

  final UserRole userRole;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final MainNavController _controller = MainNavController();
  final AuthController _authController = AuthController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  @override
  void dispose() {
    _authController.dispose();
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

    await _authController.signOut();
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
<<<<<<< Updated upstream
    final Widget homePage = widget.userRole == UserRole.admin
        ? AdminHomeDashboardScreen(
            onOpenMenu: _openDrawerMenu,
          )
        : widget.userRole == UserRole.lecturer
            ? LecturerHomeDashboardScreen(
                onOpenSearch: () => _controller.setIndex(3),
                onOpenMenu: _openDrawerMenu,
              )
            : HomeDashboardScreen(
                onOpenSearch: () => _controller.setIndex(4),
                onOpenMenu: _openDrawerMenu,
                userRole: widget.userRole,
              );

    final List<Widget> pages = widget.userRole == UserRole.admin
        ? <Widget>[
            homePage,
            TimetableScreen(userRole: widget.userRole),
            const CampusNewsScreen(),
          ]
        : widget.userRole == UserRole.lecturer
            ? <Widget>[
                homePage,
                LecturerAlertsListScreen(
                  courseCode: '',
                  courseTitle: null,
                ),
                TimetableScreen(userRole: widget.userRole),
                const LecturerCoursesScreen(),
                const CampusNewsScreen(),
              ]
            : <Widget>[
                homePage,
                const CommunityFeedScreen(),
                TimetableScreen(userRole: widget.userRole),
                const EnrolledCoursesScreen(),
                const CampusNewsScreen(),
              ];
=======
    final Widget coursesPage = widget.userRole == UserRole.lecturer
        ? const LecturerMyCoursesScreen()
        : const CourseDetailsScreen();

    final List<Widget> pages = <Widget>[
      HomeDashboardScreen(
        onOpenSearch: () => _controller.setIndex(4),
        onOpenMenu: _openDrawerMenu,
        userRole: widget.userRole,
      ),
      const CommunityFeedScreen(),
      const TimetableScreen(),
      coursesPage,
      const CampusNewsScreen(),
    ];
>>>>>>> Stashed changes

    return ValueListenableBuilder<int>(
      valueListenable: _controller.currentIndex,
      builder: (BuildContext context, int index, Widget? child) {
        return Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: Drawer(
            backgroundColor: const Color(0xFF0A0C10),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    color: const Color(0xFF0A0C10),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage('assets/students.jpg'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Account Menu',
                            style: TextStyle(
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
                  if (widget.userRole == UserRole.student)
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
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: pages[index],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: NavigationBar(
                height: 64,
                selectedIndex: index,
                onDestinationSelected: _controller.setIndex,
                backgroundColor: Colors.transparent,
                indicatorColor: const Color(0x33F59E0B),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                destinations: widget.userRole == UserRole.admin
                    ? const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.dashboard_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Admin',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.calendar_month_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Timetable',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.newspaper_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.newspaper_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'News',
                        ),
                      ]
                    : widget.userRole == UserRole.lecturer
                        ? const [
                        NavigationDestination(
                          icon: Icon(Icons.home_filled, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.home_filled,
                            color: Color.fromARGB(255, 255, 132, 0),
                          ),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.notifications_active_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Alerts',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.schedule_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Timetable',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu_book_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Courses',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.newspaper_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.newspaper_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'News',
                        ),
                      ]
                    : const [
                        NavigationDestination(
                          icon: Icon(Icons.home_filled, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.home_filled,
                            color: Color.fromARGB(255, 255, 132, 0),
                          ),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.groups_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.groups_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Community',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.schedule_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Timetable',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu_book_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'Courses',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.newspaper_rounded, color: Color(0xFF7184A3)),
                          selectedIcon: Icon(
                            Icons.newspaper_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          label: 'News',
                        ),
                      ],
              ),
            ),
          ),
        );

      },
    );
  }
}
