import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              child: const Icon(Icons.arrow_back, color: Colors.white70),
            ),
            const Spacer(),
            const Text(
              'Course Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              child: const Icon(Icons.more_horiz, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFFF5A100), Color(0xFFE98500)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SWE-402   Core Course',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Software Engineering',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Prof. Dr. Victor Mbarika',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT LECTURE',
                style: TextStyle(
                  color: Color(0xFF8CA0BC),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  _CalendarBadge(),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '09:00 AM - 11:30 AM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Main Campus, Hall 3B',
                          style: TextStyle(
                            color: Color(0xFF8AA2BD),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(radius: 5, backgroundColor: Color(0xFF22C55E)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x33F59E0B),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'OCT',
            style: TextStyle(
              color: Color(0xFFFCD34D),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '24',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
