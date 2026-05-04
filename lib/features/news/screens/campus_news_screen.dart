import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';

class CampusNewsScreen extends StatelessWidget {
  const CampusNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            const Text(
              'News & Updates',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _NewsFilter(label: 'All', selected: true),
              _NewsFilter(label: 'Academic'),
              _NewsFilter(label: 'Sports'),
            ],
          ),
          const SizedBox(height: 14),
          _newsCard(
            image: 'assets/school.jpeg',
            category: 'NEWSLETTER',
            title: 'Weekly Campus Digest: Innovation, Grants and Internships',
            description:
                'Top highlights from faculties, student clubs, and partner companies in one quick roundup.',
          ),
          const SizedBox(height: 14),
          _newsCard(
            image: 'assets/school.jpeg',
            category: 'ANNOUNCEMENT',
            title: 'Course Registration Window Opens Monday',
            description:
                'All students should complete registration before April 2 to avoid late penalties.',
          ),
          const SizedBox(height: 18),
          const Text(
            'Upcoming Events',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          const _EventTile(
            title: 'AI Seminar with Industry Panel',
            meta: 'Mar 26 • Innovation Hall • 4:00 PM',
          ),
          const _EventTile(
            title: 'Robotics Club Demo Day',
            meta: 'Mar 28 • Main Arena • 2:00 PM',
          ),
          const _EventTile(
            title: 'Career Fair 2026',
            meta: 'Apr 02 • Conference Center • 10:00 AM',
          ),
          ],
        ),
      ),
    );
  }

  Widget _newsCard({
    required String image,
    required String category,
    required String title,
    required String description,
  }) {
    return GlassCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.asset(
              image,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF94A3B8), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsFilter extends StatelessWidget {
  const _NewsFilter({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selected
            ? AppColors.primaryContainer
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFFA6BAD4),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 14,
        padding: const EdgeInsets.all(14),
        child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: AppColors.primaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(
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
    );
  }
}
