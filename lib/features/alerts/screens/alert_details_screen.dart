import 'package:flutter/material.dart';

import 'package:ictu_community_org/features/alerts/data/alerts_service.dart';
import 'package:ictu_community_org/features/alerts/models/alert_item.dart';

class AlertDetailsScreen extends StatefulWidget {
  const AlertDetailsScreen({
    super.key,
    required this.alertId,
  });

  final String alertId;

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  final AlertsService _service = AlertsService();
  bool _isLoading = true;
  AlertItem? _alert;
  String? _error;
  bool _markDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final AlertItem alert = await _service.getAlert(widget.alertId);
      if (!mounted) {
        return;
      }
      setState(() => _alert = alert);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Alert Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF58220)))
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFF87171)),
              ),
            )
          : _alert == null
          ? const Center(
              child: Text(
                'Alert not found.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: alertTypeTint(_alert!.type),
                    border: Border.all(color: alertTypeAccent(_alert!.type).withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: alertTypeAccent(_alert!.type).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          alertTypeLabel(_alert!.type),
                          style: TextStyle(
                            color: alertTypeAccent(_alert!.type),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _alert!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _alert!.courseCode,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    _alert!.description,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                if (_alert!.deadline != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline',
                          style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _alert!.deadline!.toLocal().toString(),
                          style: const TextStyle(color: Color(0xFFF1F5F9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getDeadlineText(_alert!.deadline!),
                          style: TextStyle(
                            color: getDeadlineColor(_alert!.deadline!),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_alert!.requirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requirements',
                          style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ..._alert!.requirements.map(
                          (String item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '- $item',
                              style: const TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.event_available_rounded),
                  label: const Text('Add to Calendar'),
                ),
                CheckboxListTile(
                  value: _markDone,
                  onChanged: (bool? value) {
                    setState(() => _markDone = value ?? false);
                  },
                  title: const Text(
                    'Mark as Done',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeColor: const Color(0xFFF58220),
                  checkColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ],
            ),
    );
  }
}

