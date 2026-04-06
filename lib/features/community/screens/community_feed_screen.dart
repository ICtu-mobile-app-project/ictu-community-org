import 'package:flutter/material.dart';

class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0C10),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          const Text(
            'Community & Feed',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Message Groups',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _Chip(label: 'Software Eng. 4', selected: true),
                _Chip(label: 'Hostel Block C'),
                _Chip(label: 'ICT Summit 2026'),
                _Chip(label: 'Class Reps'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Status',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _StatusBubble(name: 'Alex', active: true),
                _StatusBubble(name: 'Mina'),
                _StatusBubble(name: 'Dean'),
                _StatusBubble(name: 'Tobi'),
                _StatusBubble(name: 'Martha'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chats',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          const _ChatTile(
            title: 'Software Eng. 4',
            message: 'Quiz moved to Friday 10:00 AM',
            time: '2m',
            unread: 3,
          ),
          const _ChatTile(
            title: 'Project Team Falcon',
            message: 'I uploaded the Figma flow in docs.',
            time: '18m',
            unread: 1,
          ),
          const _ChatTile(
            title: 'ICT Summit 2026',
            message: 'Volunteers meeting starts in 30 mins.',
            time: '1h',
            unread: 0,
          ),
          const SizedBox(height: 18),
          const Text(
            'Reels',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _ReelCard(title: 'Hackathon Night', subtitle: '2.1k views'),
                SizedBox(width: 12),
                _ReelCard(title: 'AI Club Demo Day', subtitle: '1.4k views'),
                SizedBox(width: 12),
                _ReelCard(title: 'Campus Street Dance', subtitle: '3.0k views'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBubble extends StatelessWidget {
  const _StatusBubble({required this.name, this.active = false});

  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? const Color(0xFFF58220)
                    : const Color(0xFF475569),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 21,
              backgroundImage: AssetImage('assets/students.jpg'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.title,
    required this.message,
    required this.time,
    required this.unread,
  });

  final String title;
  final String message;
  final String time;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/students.jpg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 6),
              if (unread > 0)
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFF58220),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/school.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xCC000000)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: selected
            ? const Color(0xFFF59E0B)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
