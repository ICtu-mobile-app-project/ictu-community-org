import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key, required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/students.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Day',
                    style: TextStyle(color: Color(0xFF9CB0CC), fontSize: 14),
                  ),
                  Text(
                    'Alex.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              child: const Icon(Icons.settings, color: Color(0xFF9FB1CB)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search courses or news...',
            hintStyle: const TextStyle(color: Color(0xFF7588A6)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF7588A6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Text(
              'University News',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: onOpenSearch, child: const Text('See All')),
          ],
        ),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF2A190A), Color(0xFF0D1018)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANNOUNCEMENT',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Spacer(),
              Text(
                'ICTU Awarded Best Regional University 2024',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The Excellence in Higher Education commission recognized ICTU for impact and innovation.',
                style: TextStyle(color: Color(0xFF90A4C0)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
