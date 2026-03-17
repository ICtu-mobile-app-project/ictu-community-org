import 'package:flutter/material.dart';

class CourseSearchScreen extends StatelessWidget {
  const CourseSearchScreen({super.key, required this.onOpenCourseDetails});

  final VoidCallback onOpenCourseDetails;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.arrow_back, color: Colors.white70),
            const SizedBox(width: 12),
            const Text(
              'Search Courses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            CircleAvatar(
              backgroundColor: const Color(0xFFFFD3BC),
              child: Image.asset('assets/Logo.png', width: 20),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF111726), Color(0xFF1B1F2B)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              const _FakeInput(hint: 'Search course by name or code...'),
              const SizedBox(height: 12),
              const _FakeInput(hint: 'Select Faculty', withChevron: true),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _FakeInput(hint: 'Level', withChevron: true)),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FakeInput(hint: 'Semester', withChevron: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: onOpenCourseDetails,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text(
                    'Search Courses',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FakeInput extends StatelessWidget {
  const _FakeInput({required this.hint, this.withChevron = false});

  final String hint;
  final bool withChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          if (!withChevron) const Icon(Icons.search, color: Color(0xFF7788A4)),
          if (!withChevron) const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(color: Color(0xFF7E90AB), fontSize: 16),
            ),
          ),
          if (withChevron)
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF7E90AB),
            ),
        ],
      ),
    );
  }
}
