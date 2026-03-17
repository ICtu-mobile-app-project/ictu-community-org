import 'package:flutter/material.dart';

class CampusNewsScreen extends StatelessWidget {
  const CampusNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 23, 29, 38),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 14, 30, 51),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Campus News',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 7, 20, 37),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ],
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
            image: 'assets/students.jpg',
            category: 'EVENTS',
            title: 'Annual Spring Festival 2024: Music and Arts',
            description:
                'Join us for the biggest celebration of the year with live bands, food trucks, and interactive installations.',
          ),
        ],
      ),
    );
  }

  Widget _newsCard({
    required String image,
    required String category,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromARGB(255, 0, 9, 40),
        border: Border.all(color: const Color(0xFFDCE3EC)),
      ),
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
                    color: const Color.fromARGB(255, 44, 25, 0),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Color(0xFFF97316),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF475569), height: 1.4),
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
        color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE8ECF1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF475569),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
