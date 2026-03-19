import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0x1AF58220),
                  ),
                  child: const Text(
                    'March 2026',
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
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _DateCell(day: 'MON', date: '18', selected: false),
                _DateCell(day: 'TUE', date: '19', selected: false),
                _DateCell(day: 'WED', date: '20', selected: true),
                _DateCell(day: 'THU', date: '21', selected: false),
                _DateCell(day: 'FRI', date: '22', selected: false),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              splashBorderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: days.map((day) => _buildDaySchedule(day)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final schedule = _getScheduleForDay(day);

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: schedule.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No classes scheduled',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ]
            : [
                ...schedule.map((session) => _buildTimeSlot(session)),
                const SizedBox(height: 8),
                const _ScheduleTypeCard(
                  title: 'Department Event',
                  subtitle: 'AI Seminar at Innovation Hall • 4:00 PM',
                  icon: Icons.event_available_rounded,
                ),
                const _ScheduleTypeCard(
                  title: 'Lecture Reminder',
                  subtitle: 'Software Engineering Lab • Bring laptop',
                  icon: Icons.menu_book_rounded,
                ),
              ],
      ),
    );
  }

  Widget _buildTimeSlot(Map<String, String> session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
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
                    session['time']!,
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
                    session['course']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                    session['location']!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
                    session['instructor']!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getScheduleForDay(String day) {
    const schedule = {
      'Monday': [
        {
          'time': '09:00 - 10:30',
          'course': 'Data Structures',
          'location': 'Room 201',
          'instructor': 'Dr. Johnson',
        },
        {
          'time': '11:00 - 12:30',
          'course': 'Algorithms',
          'location': 'Room 405',
          'instructor': 'Prof. Smith',
        },
        {
          'time': '14:00 - 15:30',
          'course': 'Database Systems',
          'location': 'Lab 102',
          'instructor': 'Dr. Williams',
        },
      ],
      'Tuesday': [
        {
          'time': '10:00 - 11:30',
          'course': 'Web Development',
          'location': 'Room 301',
          'instructor': 'Eng. Davis',
        },
        {
          'time': '13:00 - 14:30',
          'course': 'Mobile Apps',
          'location': 'Lab 201',
          'instructor': 'Dr. Brown',
        },
      ],
      'Wednesday': [
        {
          'time': '09:00 - 10:30',
          'course': 'Operating Systems',
          'location': 'Room 501',
          'instructor': 'Prof. Miller',
        },
        {
          'time': '15:00 - 16:30',
          'course': 'Software Engineering',
          'location': 'Room 202',
          'instructor': 'Dr. Wilson',
        },
      ],
      'Thursday': [
        {
          'time': '10:00 - 11:30',
          'course': 'Machine Learning',
          'location': 'Room 601',
          'instructor': 'Dr. Anderson',
        },
        {
          'time': '14:00 - 15:30',
          'course': 'Networking',
          'location': 'Lab 301',
          'instructor': 'Eng. Taylor',
        },
      ],
      'Friday': [
        {
          'time': '09:00 - 10:30',
          'course': 'Project Lab',
          'location': 'Lab 102',
          'instructor': 'Dr. Johnson',
        },
      ],
    };

    return List<Map<String, String>>.from(schedule[day] ?? []);
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.day,
    required this.date,
    required this.selected,
  });

  final String day;
  final String date;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selected ? const Color(0x1AF58220) : Colors.transparent,
      ),
      child: Column(
        children: [
          Text(day, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: selected ? const Color(0xFFF58220) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTypeCard extends StatelessWidget {
  const _ScheduleTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x1AF58220),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
