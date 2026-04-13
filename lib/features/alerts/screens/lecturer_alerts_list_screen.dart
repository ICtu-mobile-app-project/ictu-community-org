import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ictu_community_org/features/alerts/screens/alert_details_screen.dart';
import 'package:ictu_community_org/features/alerts/screens/create_alert_screen.dart';

import '../data/alerts_service.dart';
import '../models/alert_item.dart';

class LecturerAlertsListScreen extends StatefulWidget {
  const LecturerAlertsListScreen({
    super.key,
    required this.courseCode,
    this.courseTitle,
  });

  final String courseCode;
  final String? courseTitle;

  @override
  State<LecturerAlertsListScreen> createState() => _LecturerAlertsListScreenState();
}

class _LecturerAlertsListScreenState extends State<LecturerAlertsListScreen> {
  final AlertsService _service = AlertsService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  List<AlertItem> _alerts = <AlertItem>[];
  AlertType? _filterType;
  String _sort = 'deadline';
  bool _isLoading = true;
  String? _error;
  int _page = 0;
  int _totalPages = 1;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<AlertItem> data = await _service.listLecturerAlerts(
        courseCode: widget.courseCode,
        type: _filterType,
        search: _searchController.text.trim(),
        sort: _sort,
        page: _page,
        limit: _limit,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _alerts = data;
        // If less than limit, it's the last page
        _totalPages = data.length < _limit && _page == 0 ? 1 : (_page + (data.length == _limit ? 2 : 1));
      });
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _page = 0);
      unawaited(_load());
    });
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
    });
    unawaited(_load());
  }

  Future<void> _openCreate() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateAlertScreen(
          initialCourseCode: widget.courseCode,
        ),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.courseCode} Alerts',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: const Color(0xFFF58220),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Create Alert'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search title or course code',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filterType == null,
                    onTap: () {
                      setState(() => _filterType = null);
                      setState(() => _page = 0);
                      unawaited(_load());
                    },
                  ),
                  _FilterChip(
                    label: 'Assignments',
                    selected: _filterType == AlertType.assignment,
                    onTap: () {
                      setState(() => _filterType = AlertType.assignment);
                      setState(() => _page = 0);
                      unawaited(_load());
                    },
                  ),
                  _FilterChip(
                    label: 'CAs',
                    selected: _filterType == AlertType.ca,
                    onTap: () {
                      setState(() => _filterType = AlertType.ca);
                      setState(() => _page = 0);
                      unawaited(_load());
                    },
                  ),
                  _FilterChip(
                    label: 'Exams',
                    selected: _filterType == AlertType.exam,
                    onTap: () {
                      setState(() => _filterType = AlertType.exam);
                      setState(() => _page = 0);
                      unawaited(_load());
                    },
                  ),
                  _FilterChip(
                    label: 'Notices',
                    selected: _filterType == AlertType.notice,
                    onTap: () {
                      setState(() => _filterType = AlertType.notice);
                      setState(() => _page = 0);
                      unawaited(_load());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _sort,
              dropdownColor: const Color(0xFF111827),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Sort',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'deadline', child: Text('Deadline (soonest)')),
                DropdownMenuItem(value: 'created', child: Text('Date Created (newest)')),
              ],
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() => _sort = value);
                setState(() => _page = 0);
                unawaited(_load());
              },
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFFF58220)),
                ),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFF87171)))
            else if (_alerts.isEmpty)
              const Text(
                'No alerts found for this course.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              )
            else ...[
              ..._alerts.map((AlertItem item) {
                final DateTime? deadline = item.deadline;
                final String deadlineText = deadline == null ? 'No deadline' : getDeadlineText(deadline);
                final Color deadlineColor = deadline == null
                    ? const Color(0xFF94A3B8)
                    : getDeadlineColor(deadline);

                return InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AlertDetailsScreen(alertId: item.id),
                      ),
                    );
                    await _load();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: alertTypeTint(item.type),
                      border: Border.all(color: alertTypeAccent(item.type).withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: alertTypeAccent(item.type).withValues(alpha: 0.25),
                            ),
                            child: Text(
                              alertTypeLabel(item.type),
                              style: TextStyle(
                                color: alertTypeAccent(item.type),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.courseCode,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          deadlineText,
                          style: TextStyle(color: deadlineColor, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _page > 0 ? () => _goToPage(_page - 1) : null,
                  ),
                  Text(
                    'Page ${_page + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _alerts.length == _limit ? () => _goToPage(_page + 1) : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: const Color(0x33F58220),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFFFED7AA) : const Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

