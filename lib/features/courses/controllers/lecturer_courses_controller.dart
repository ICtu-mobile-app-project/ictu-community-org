import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ictu_community_org/features/courses/data/lecturer_courses_repository.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course.dart';

class LecturerCoursesController {
  LecturerCoursesController({
    required LecturerCoursesRepository repository,
    required this.lecturerId,
  }) : _repository = repository;

  final LecturerCoursesRepository _repository;
  final String lecturerId;

  final ValueNotifier<List<LecturerCourse>> items =
      ValueNotifier<List<LecturerCourse>>(<LecturerCourse>[]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<bool> hasMore = ValueNotifier<bool>(true);

  int _page = 0;
  String _query = '';
  Timer? _searchDebounce;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    _page = 0;
    hasMore.value = true;
    items.value = <LecturerCourse>[];
    await _fetchPage(isRefresh: true);
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) {
      return;
    }
    _page += 1;
    await _fetchPage(isRefresh: false);
  }

  void onSearchChanged(String query) {
    _query = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });
  }

  Future<void> _fetchPage({required bool isRefresh}) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.getMyCourses(
        lecturerId: lecturerId,
        page: _page,
        limit: 20,
        searchQuery: _query,
      );

      if (isRefresh) {
        items.value = result.items;
      } else {
        items.value = <LecturerCourse>[...items.value, ...result.items];
      }
      hasMore.value = result.hasMore;
    } catch (e) {
      errorMessage.value = 'Could not load courses: $e';
      if (!isRefresh) {
        _page -= 1;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    _searchDebounce?.cancel();
    items.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    hasMore.dispose();
  }
}
