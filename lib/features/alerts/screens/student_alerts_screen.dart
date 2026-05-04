import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/app_top_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ictu_community_org/core/utils/calendar_utils.dart';
import 'package:ictu_community_org/features/alerts/data/alerts_service.dart';
import 'package:ictu_community_org/features/alerts/models/alert_item.dart';
import 'package:ictu_community_org/features/alerts/screens/alert_details_screen.dart';

class StudentAlertsScreen extends StatefulWidget {
  const StudentAlertsScreen({
    super.key,
    this.courseCode,
    this.initialType,
  });

  final String? courseCode;
  final AlertType? initialType;

  @override
  State<StudentAlertsScreen> createState() => _StudentAlertsScreenState();
}

class _StudentAlertsScreenState extends State<StudentAlertsScreen> {
  final AlertsService _service = AlertsService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  List<AlertItem> _alerts = <AlertItem>[];
  AlertType? _filterType;
  String _sort = 'deadline';
  bool _isLoading = true;
  String? _error;
  int _page = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialType;
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Re-using listLecturerAlerts as it's the generic list_alerts API
      final List<AlertItem> data = await _service.listLecturerAlerts(
        courseCode: widget.courseCode,
        type: _filterType,
        search: _searchController.text.trim(),
        sort: _sort,
        page: _page,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        _alerts = data;
      });
    } catch (error) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final title = widget.courseCode != null && widget.courseCode!.isNotEmpty
        ? '${widget.courseCode} Alerts'
        : 'My Alerts';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppTopBar(
        showBack: true,
        title: title,
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search alerts...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filterType == null,
                      onTap: () {
                        setState(() {
                          _filterType = null;
                          _page = 0;
                        });
                        unawaited(_load());
                      },
                    ),
                    _FilterChip(
                      label: 'Assignments',
                      selected: _filterType == AlertType.assignment,
                      onTap: () {
                        setState(() {
                          _filterType = AlertType.assignment;
                          _page = 0;
                        });
                        unawaited(_load());
                      },
                    ),
                    _FilterChip(
                      label: 'Exams',
                      selected: _filterType == AlertType.exam,
                      onTap: () {
                        setState(() {
                          _filterType = AlertType.exam;
                          _page = 0;
                        });
                        unawaited(_load());
                      },
                    ),
                    _FilterChip(
                      label: 'CAs',
                      selected: _filterType == AlertType.ca,
                      onTap: () {
                        setState(() {
                          _filterType = AlertType.ca;
                          _page = 0;
                        });
                        unawaited(_load());
                      },
                    ),
                    _FilterChip(
                      label: 'Notices',
                      selected: _filterType == AlertType.notice,
                      onTap: () {
                        setState(() {
                          _filterType = AlertType.notice;
                          _page = 0;
                        });
                        unawaited(_load());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primaryContainer,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer));
    }

    if (_error != null && _alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, color: Colors.white.withOpacity(0.2), size: 64),
            const SizedBox(height: 16),
            const Text(
              'No alerts found',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _alerts[index];
        final deadline = item.deadline;
        final deadlineText = deadline == null ? 'No deadline' : getDeadlineText(deadline);
        final deadlineColor = deadline == null ? const Color(0xFF94A3B8) : getDeadlineColor(deadline);

        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AlertDetailsScreen(alertId: item.id)),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: alertTypeTint(item.type).withOpacity(0.08),
              border: Border.all(color: alertTypeAccent(item.type).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: alertTypeAccent(item.type).withOpacity(0.15),
                      ),
                      child: Text(
                        alertTypeLabel(item.type).toUpperCase(),
                        style: TextStyle(
                          color: alertTypeAccent(item.type),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (item.courseCode.isNotEmpty)
                      Text(
                        item.courseCode,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: deadlineColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deadlineText,
                        style: TextStyle(
                          color: deadlineColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.submissionLink != null)
                      IconButton(
                        onPressed: () async {
                          final url = Uri.parse(item.submissionLink!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.link_rounded, size: 20),
                        color: const Color(0xFFF58220),
                        tooltip: 'Submission Link',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 12),
                      ),
                    if (item.deadline != null)
                      IconButton(
                        onPressed: () {
                          CalendarUtils.addToCalendar(
                            title: item.title,
                            description: item.description,
                            startTime: item.deadline!,
                          );
                        },
                        icon: const Icon(Icons.event_available_rounded, size: 20),
                        color: AppColors.primaryContainer,
                        tooltip: 'Add to Calendar',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white.withOpacity(0.05),
        selectedColor: AppColors.primaryContainer.withOpacity(0.2),
        checkmarkColor: AppColors.primaryContainer,
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryContainer : const Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primaryContainer.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          ),
        ),
      ),
    );
  }
}
