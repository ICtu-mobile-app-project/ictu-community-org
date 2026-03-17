import 'package:flutter/material.dart';

import '../../community/screens/community_feed_screen.dart';
import '../../courses/screens/course_details_screen.dart';
import '../../courses/screens/course_search_screen.dart';
import '../../home/screens/home_dashboard_screen.dart';
import '../../news/screens/campus_news_screen.dart';
import '../controllers/main_nav_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final MainNavController _controller = MainNavController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeDashboardScreen(onOpenSearch: () => _controller.setIndex(2)),
      const CommunityFeedScreen(),
      CourseSearchScreen(onOpenCourseDetails: () => _controller.setIndex(3)),
      const CourseDetailsScreen(),
      const CampusNewsScreen(),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: _controller.currentIndex,
      builder: (BuildContext context, int index, Widget? child) {
        return Scaffold(
          backgroundColor: const Color(0xFF050913),
          body: SafeArea(child: pages[index]),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: NavigationBar(
              height: 66,
              selectedIndex: index,
              onDestinationSelected: _controller.setIndex,
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0x33F59E0B),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_filled, color: Color(0xFF7184A3)),
                  selectedIcon: Icon(
                    Icons.home_filled,
                    color: Color(0xFFF59E0B),
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
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF7184A3),
                  ),
                  selectedIcon: Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  label: 'Courses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_rounded, color: Color(0xFF7184A3)),
                  selectedIcon: Icon(
                    Icons.pie_chart_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  label: 'Details',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded, color: Color(0xFF7184A3)),
                  selectedIcon: Icon(
                    Icons.settings_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
