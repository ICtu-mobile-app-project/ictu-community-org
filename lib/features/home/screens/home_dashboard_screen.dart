import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key, required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0C10),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
        children: [
          Row(
            children: [
              const Text(
                '9:41',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.signal_cellular_alt_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: 16,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.wifi_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: 16,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.battery_full_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF58220),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage('assets/students.jpg'),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0A0C10),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Day',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  Text(
                    'Alex.',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search courses or news...',
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF64748B),
                size: 18,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Text(
                'University News',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.45,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenSearch,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFFF58220),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 176,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _NewsCard(
                  category: 'ANNOUNCEMENT',
                  categoryColor: Color(0xFFF58220),
                  title: 'ICTU Awarded Best Regional University 2024',
                  description:
                      'The Excellence in Higher Education commission has recognized ICTU for its impact and innovation.',
                  tintColor: Color(0x1AF58220),
                  borderColor: Color(0x33F58220),
                  glowColor: Color(0x33F58220),
                ),
                SizedBox(width: 16),
                _NewsCard(
                  category: 'CONFERENCE',
                  categoryColor: Color(0xFF3B82F6),
                  title: 'Next Global ICT Summit Registration Open',
                  description:
                      'Join global leaders at our annual summit and connect with research and industry experts.',
                  tintColor: Color(0x08FFFFFF),
                  borderColor: Color(0x14FFFFFF),
                  glowColor: Color(0x1A3B82F6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Text(
                'Active Courses',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.45,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x1AF58220),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '4 Enrolled',
                  style: TextStyle(
                    color: Color(0xFFF58220),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _CourseTile(
            icon: Icons.terminal_rounded,
            iconBg: Color(0x1A6366F1),
            iconColor: Color(0xFF818CF8),
            title: 'Advanced Mobile Development',
            subtitle: 'Prof. Alexander Silvin',
            progress: 0.65,
            progressColor: Color(0xFF6366F1),
          ),
          const SizedBox(height: 16),
          const _CourseTile(
            icon: Icons.folder_copy_rounded,
            iconBg: Color(0x1A10B981),
            iconColor: Color(0xFF34D399),
            title: 'Database Management Systems',
            subtitle: 'Dr. Sarah Johnson',
            progress: 0.82,
            progressColor: Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          const _CourseTile(
            icon: Icons.brush_rounded,
            iconBg: Color(0x1AF97316),
            iconColor: Color(0xFFFB923C),
            title: 'UI/UX Design Systems',
            subtitle: 'Senior Designer Vitaliy D.',
            progress: 0.30,
            progressColor: Color(0xFFF58220),
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.45,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickAction(
                icon: Icons.calendar_month_rounded,
                label: 'Schedule',
                color: Color(0xFFFB7185),
              ),
              _QuickAction(
                icon: Icons.assignment_rounded,
                label: 'Exams',
                color: Color(0xFF38BDF8),
              ),
              _QuickAction(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Finances',
                color: Color(0xFFFBBF24),
              ),
              _QuickAction(
                icon: Icons.school_rounded,
                label: 'Library',
                color: Color(0xFFA78BFA),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.category,
    required this.categoryColor,
    required this.title,
    required this.description,
    required this.tintColor,
    required this.borderColor,
    required this.glowColor,
  });

  final String category;
  final Color categoryColor;
  final String title;
  final String description;
  final Color tintColor;
  final Color borderColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: tintColor,
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -47,
            top: -47,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: glowColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                category,
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
