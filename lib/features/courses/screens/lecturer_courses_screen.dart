import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/services/connectivity_service.dart';
import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/courses/data/in_memory_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/data/lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/data/supabase_lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_overview.dart';
import 'package:ictu_community_org/features/courses/screens/course_notes_list_screen.dart';
import 'package:ictu_community_org/features/courses/screens/create_course_screen.dart';
import 'package:ictu_community_org/features/courses/screens/lecturer_course_details_screen.dart';

class LecturerCoursesScreen extends StatefulWidget {
  const LecturerCoursesScreen({super.key});

  @override
  State<LecturerCoursesScreen> createState() => _LecturerCoursesScreenState();
}

class _LecturerCoursesScreenState extends State<LecturerCoursesScreen> {
  static const int _pageSize = 20;

  late final LecturerCoursesRepository _repository;
  final ConnectivityService _connectivity = ConnectivityService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<LecturerCourseOverview> _allCourses = <LecturerCourseOverview>[];

  StreamSubscription? _connectivitySubscription;
  Timer? _debounce;
  String _search = '';
  String? _error;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _nextPage = 0;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseBootstrap.isConfigured
        ? SupabaseLecturerCoursesRepository()
        : InMemoryLecturerCoursesRepository.instance;
    _scrollController.addListener(_onScroll);
    _checkConnectivity();
    _listenToConnectivity();
    unawaited(_loadCourses(reset: true));
  }

  Future<void> _checkConnectivity() async {
    final online = await _connectivity.isOnline();
    if (mounted) setState(() => _isOnline = online);
  }

  void _listenToConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((online) {
      if (mounted) {
        final wasOffline = !_isOnline;
        setState(() => _isOnline = online);
        if (online && wasOffline) {
          unawaited(_loadCourses(reset: true, forceRefresh: true));
        }
      }
    });
  }

  Future<void> _refresh() => _loadCourses(reset: true, forceRefresh: true);

  Future<void> _loadCourses({
    required bool reset,
    bool forceRefresh = false,
  }) async {
    if (reset) {
      setState(() {
        _isLoadingInitial = true;
        _error = null;
        _nextPage = 0;
        _hasMore = true;
        _allCourses.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMore) {
        return;
      }
      setState(() => _isLoadingMore = true);
    }

    try {
      final List<LecturerCourseOverview> page = await _repository.getCourses(
        page: _nextPage,
        limit: _pageSize,
        searchQuery: _search,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _allCourses.addAll(page);
        _nextPage += 1;
        _hasMore = page.length == _pageSize;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to load courses right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }
    final double trigger = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= trigger) {
      unawaited(_loadCourses(reset: false));
    }
  }

  void _onSearchChanged(String value) {
    _search = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_loadCourses(reset: true));
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final bool? created = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(builder: (_) => const CreateCourseScreen()),
            );
            if (created == true) {
              await _loadCourses(reset: true, forceRefresh: true);
            }
          },
          backgroundColor: const Color(0xFFF58220),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create New Course'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Courses',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!_isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          const Text(
                            'Offline',
                            style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage course content, students, delegates, and notes.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Color(0xFFF1F5F9)),
                decoration: InputDecoration(
                  hintText: 'Search by code or title',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool isTablet = constraints.maxWidth >= 700;
                          final int crossAxisCount = isTablet ? 3 : 2;

                          if (_isLoadingInitial) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF58220),
                              ),
                            );
                          }

                          if (_error != null) {
                            return ListView(
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Color(0xFF94A3B8)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          }

                          if (_allCourses.isEmpty) {
                            return ListView(
                              children: [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No courses found.',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            );
                          }

                          return GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 120,
                            ),
                            itemCount: _allCourses.length + (_isLoadingMore ? 1 : 0),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.84,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              if (index >= _allCourses.length) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF58220),
                                  ),
                                );
                              }

                              final LecturerCourseOverview item = _allCourses[index];
                              return _CourseCard(
                                data: item,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          LecturerCourseDetailsScreen(
                                            course: item,
                                          ),
                                    ),
                                  );
                                },
                                onOpenNotes: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CourseNotesListScreen(
                                        courseId: item.id,
                                        courseCode: item.code,
                                        role: UserRole.lecturer,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.data,
    required this.onTap,
    required this.onOpenNotes,
  });

  final LecturerCourseOverview data;
  final VoidCallback onTap;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.code,
              style: const TextStyle(
                color: Color(0xFFF58220),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            _meta('Students', '${data.students}'),
            _meta('Notes', '${data.notes}'),
            const SizedBox(height: 4),
            Text(
              'Last: ${_fmt(data.lastActivity)}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenNotes,
                child: const Text('Notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime value) {
    final String y = value.year.toString();
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

