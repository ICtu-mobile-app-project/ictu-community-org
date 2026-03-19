import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0C10),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: const [
          Text(
            'Course Tracker',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 12),
          _CourseProgressCard(
            title: 'Software Engineering',
            code: 'SWE-402',
            progress: 0.72,
            lecturer: 'Prof. Dr. Victor Mbarika',
          ),
          _CourseProgressCard(
            title: 'Database Management',
            code: 'CSC-315',
            progress: 0.58,
            lecturer: 'Dr. Sarah Johnson',
          ),
          SizedBox(height: 18),
          Text(
            'Course Materials',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 10),
          _MaterialTile(name: 'Week 7 - UML Design Patterns.pdf', size: '3.1 MB'),
          _MaterialTile(name: 'DBMS Query Optimization Slides.pptx', size: '7.8 MB'),
          SizedBox(height: 18),
          Text(
            'Exams & Deadlines',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 10),
          _DeadlineTile(
            title: 'Midterm Exam • SWE-402',
            due: 'Apr 04, 10:00 AM',
            color: Color(0xFFF59E0B),
          ),
          _DeadlineTile(
            title: 'Assignment 3 • DBMS',
            due: 'Mar 28, 11:59 PM',
            color: Color(0xFFFB7185),
          ),
          _DeadlineTile(
            title: 'Lab Report • Mobile Dev',
            due: 'Mar 25, 04:00 PM',
            color: Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({
    required this.title,
    required this.code,
    required this.progress,
    required this.lecturer,
  });

  final String title;
  final String code;
  final double progress;
  final String lecturer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 3),
          Text(lecturer, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}% completed',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.name, required this.size});

  final String name;
  final String size;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x1AF59E0B),
            ),
            child: const Icon(Icons.file_present_rounded, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Text(size, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        ],
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.title,
    required this.due,
    required this.color,
  });

  final String title;
  final String due;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(due, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
