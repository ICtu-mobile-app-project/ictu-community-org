<<<<<<< Updated upstream
import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../../alerts/screens/lecturer_alerts_list_screen.dart';
import '../models/lecturer_course_overview.dart';
import 'course_notes_list_screen.dart';
=======
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/ictu_constants.dart';
import '../data/lecturer_courses_repository.dart';
import '../models/course_delegate.dart';
import '../models/course_student.dart';
import '../models/lecturer_course.dart';
import 'course_notes_screen.dart';
>>>>>>> Stashed changes

class LecturerCourseDetailsScreen extends StatefulWidget {
  const LecturerCourseDetailsScreen({
    super.key,
<<<<<<< Updated upstream
    required this.course,
  });

  final LecturerCourseOverview course;
=======
    required this.courseId,
    required this.repository,
    required this.lecturerId,
  });

  final String courseId;
  final LecturerCoursesRepository repository;
  final String lecturerId;
>>>>>>> Stashed changes

  @override
  State<LecturerCourseDetailsScreen> createState() =>
      _LecturerCourseDetailsScreenState();
}

class _LecturerCourseDetailsScreenState
    extends State<LecturerCourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

<<<<<<< Updated upstream
=======
  LecturerCourse? _course;
  List<CourseStudent> _students = <CourseStudent>[];
  List<CourseDelegate> _delegates = <CourseDelegate>[];
  bool _isLoading = true;
  String? _error;

>>>>>>> Stashed changes
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
<<<<<<< Updated upstream
=======
    _load();
>>>>>>> Stashed changes
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

<<<<<<< Updated upstream
  @override
  Widget build(BuildContext context) {
=======
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final LecturerCourse course = await widget.repository.getCourseDetails(
        widget.courseId,
      );
      final List<CourseStudent> students = await widget.repository
          .getEnrolledStudents(widget.courseId);
      final List<CourseDelegate> delegates = await widget.repository
          .getDelegates(widget.courseId);

      if (!mounted) {
        return;
      }

      setState(() {
        _course = course;
        _students = students;
        _delegates = delegates;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not load course details: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openEditDialog() async {
    final LecturerCourse? course = _course;
    if (course == null) {
      return;
    }

    final TextEditingController titleController = TextEditingController(
      text: course.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: course.description,
    );
    String semester = course.semester;
    bool archived = course.archived;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: semester,
                  items: ICTUConstants.semesters
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      semester = value;
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Semester'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: archived,
                  onChanged: (bool value) {
                    archived = value;
                  },
                  title: const Text('Archive Course'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.repository.updateCourse(
                  courseId: course.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  semester: semester,
                  archived: archived,
                );
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _deleteCourseIfAllowed() async {
    final LecturerCourse? course = _course;
    if (course == null) {
      return;
    }

    if (course.hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete course with existing lectures, notes, or alerts.',
          ),
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await widget.repository.deleteCourse(widget.courseId);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _course == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0C10),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF58220)),
        ),
      );
    }

    if (_error != null && _course == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0C10),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Color(0xFFF87171)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final LecturerCourse course = _course!;

>>>>>>> Stashed changes
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
<<<<<<< Updated upstream
          '${widget.course.code} • ${widget.course.title}',
=======
          '${course.courseCode} • ${course.title}',
>>>>>>> Stashed changes
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
<<<<<<< Updated upstream
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: () {},
=======
          IconButton(
            onPressed: _openEditDialog,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: course.hasContent ? null : _deleteCourseIfAllowed,
>>>>>>> Stashed changes
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _StatsCard(
                  label: 'Students',
<<<<<<< Updated upstream
                  value: widget.course.students.toString(),
=======
                  value: _students.length,
>>>>>>> Stashed changes
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 8),
                _StatsCard(
<<<<<<< Updated upstream
                  label: 'Notes',
                  value: widget.course.notes.toString(),
=======
                  label: 'Lectures',
                  value: course.lectureCount,
                  color: const Color(0xFFA78BFA),
                ),
                const SizedBox(width: 8),
                _StatsCard(
                  label: 'Notes',
                  value: course.notesCount,
>>>>>>> Stashed changes
                  color: const Color(0xFFF58220),
                ),
                const SizedBox(width: 8),
                _StatsCard(
                  label: 'Alerts',
<<<<<<< Updated upstream
                  value: widget.course.alerts.toString(),
=======
                  value: course.alertCount,
>>>>>>> Stashed changes
                  color: const Color(0xFFFB7185),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFF58220),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF94A3B8),
                tabs: const [
                  Tab(text: 'Content'),
                  Tab(text: 'Students'),
                  Tab(text: 'Delegates'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
<<<<<<< Updated upstream
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ContentSection(
                      title: 'Course Description',
                      content: widget.course.description.isEmpty 
                        ? 'No description provided for this course.' 
                        : widget.course.description,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlassTile(
                      icon: Icons.description_rounded,
                      title: 'Course Notes',
                      subtitle: 'Upload and manage study materials',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CourseNotesListScreen(
                              courseId: widget.course.id,
                              courseCode: widget.course.code,
                              role: UserRole.lecturer,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _GlassTile(
                      icon: Icons.notification_important_rounded,
                      title: 'Course Alerts',
                      subtitle: 'Post assignments, exams, and announcements',
                      onTap: () {
                         Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LecturerAlertsListScreen(
                              courseCode: widget.course.code,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _ContentSection(
                      title: 'General Info',
                      content: 'Semester: ${widget.course.semester}\nCreated: ${_fmtDate(widget.course.lastActivity)}',
                    ),
                  ],
                ),
                const _SimpleTabBody(
                  title: 'Students',
                  subtitle:
                      'Add/remove enrolled students and CSV batch enrollments.',
                ),
                const _SimpleTabBody(
                  title: 'Delegates',
                  subtitle: 'Assign delegates and manage note permissions.',
                ),
                const _SimpleTabBody(
                  title: 'Settings',
                  subtitle: 'Edit course details and archive options.',
=======
                _ContentTab(
                  course: course,
                  onOpenNotes: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CourseNotesScreen(
                          courseId: course.id,
                          title: '${course.courseCode} Notes',
                          canUpload: true,
                        ),
                      ),
                    );
                  },
                ),
                _StudentsTab(
                  repository: widget.repository,
                  courseId: course.id,
                  students: _students,
                  onUpdated: _load,
                ),
                _DelegatesTab(
                  repository: widget.repository,
                  courseId: course.id,
                  students: _students,
                  delegates: _delegates,
                  onUpdated: _load,
                ),
                _SettingsTab(
                  course: course,
                  onEdit: _openEditDialog,
                  onDelete: _deleteCourseIfAllowed,
>>>>>>> Stashed changes
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< Updated upstream

  String _fmtDate(DateTime value) {
    final String y = value.year.toString();
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            height: 1.5,
          ),
        ),
      ],
    );
  }
=======
>>>>>>> Stashed changes
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
<<<<<<< Updated upstream
  final String value;
=======
  final int value;
>>>>>>> Stashed changes
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
<<<<<<< Updated upstream
              value,
=======
              '$value',
>>>>>>> Stashed changes
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
=======
class _ContentTab extends StatelessWidget {
  const _ContentTab({required this.course, required this.onOpenNotes});

  final LecturerCourse course;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Lectures'),
        _GlassTile(
          icon: Icons.mic_rounded,
          title: 'Uploaded Lectures: ${course.lectureCount}',
          subtitle: 'Latest lecture activity in this course.',
        ),
        const SizedBox(height: 14),
        const _SectionTitle('Notes'),
        _GlassTile(
          icon: Icons.note_alt_rounded,
          title: 'Lecture Notes: ${course.notesCount}',
          subtitle: 'PDF/DOC resources shared with students.',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: onOpenNotes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF58220),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Open Notes'),
          ),
        ),
        const SizedBox(height: 14),
        const _SectionTitle('Alerts'),
        _GlassTile(
          icon: Icons.notifications_active_rounded,
          title: 'Course Alerts: ${course.alertCount}',
          subtitle: 'Exams, CA notices, and assignment reminders.',
        ),
      ],
    );
  }
}

class _StudentsTab extends StatefulWidget {
  const _StudentsTab({
    required this.repository,
    required this.courseId,
    required this.students,
    required this.onUpdated,
  });

  final LecturerCoursesRepository repository;
  final String courseId;
  final List<CourseStudent> students;
  final Future<void> Function() onUpdated;

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  bool _isWorking = false;

  Future<void> _removeStudent(CourseStudent student) async {
    setState(() => _isWorking = true);
    try {
      await widget.repository.removeStudent(
        courseId: widget.courseId,
        studentId: student.id,
      );
      await widget.onUpdated();
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _openAddStudentsDialog() async {
    final TextEditingController searchController = TextEditingController();
    List<CourseStudent> candidates = <CourseStudent>[];
    final Set<String> selected = <String>{};

    final bool? shouldAdd = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> search() async {
              final List<CourseStudent> result = await widget.repository
                  .searchStudentsByEmail(searchController.text);
              setDialogState(() {
                candidates = result;
              });
            }

            return AlertDialog(
              title: const Text('Add Students'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by email',
                        suffixIcon: IconButton(
                          onPressed: search,
                          icon: const Icon(Icons.search_rounded),
                        ),
                      ),
                      onSubmitted: (_) => search(),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: candidates.map((CourseStudent student) {
                          return CheckboxListTile(
                            value: selected.contains(student.id),
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selected.add(student.id);
                                } else {
                                  selected.remove(student.id);
                                }
                              });
                            },
                            title: Text(student.fullName),
                            subtitle: Text(student.email),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: const Text('Enroll Selected'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldAdd != true || selected.isEmpty) {
      return;
    }

    setState(() => _isWorking = true);
    try {
      await widget.repository.enrollStudents(
        courseId: widget.courseId,
        studentIds: selected.toList(),
      );
      await widget.onUpdated();
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _bulkCsvEnroll() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile file = result.files.single;
    final String? csvText = file.bytes != null
        ? utf8.decode(file.bytes!, allowMalformed: true)
        : null;

    if (csvText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CSV upload requires in-memory file data in this demo mode.',
          ),
        ),
      );
      return;
    }

    final List<String> emails = csvText
        .split(RegExp(r'[\r\n,;]'))
        .map((String e) => e.trim().toLowerCase())
        .where((String e) => e.contains('@'))
        .toSet()
        .toList();

    final List<String> studentIds = <String>[];
    for (final String email in emails) {
      final List<CourseStudent> matches = await widget.repository
          .searchStudentsByEmail(email);
      if (matches.isNotEmpty) {
        studentIds.add(matches.first.id);
      }
    }

    if (studentIds.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid student emails found in CSV.')),
      );
      return;
    }

    await widget.repository.enrollStudents(
      courseId: widget.courseId,
      studentIds: studentIds,
    );
    await widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isWorking ? null : _openAddStudentsDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF58220),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Add Students'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _isWorking ? null : _bulkCsvEnroll,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('CSV Upload'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.students.isEmpty)
          const Text(
            'No students enrolled yet.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          )
        else
          ...widget.students.map((CourseStudent student) {
            return Dismissible(
              key: ValueKey<String>(student.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
              confirmDismiss: (_) async {
                await _removeStudent(student);
                return false;
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0x1AF58220),
                      child: Text(
                        student.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Color(0xFFF58220)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            student.email,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Enrolled ${_date(student.enrolledAt)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isWorking
                          ? null
                          : () => _removeStudent(student),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _DelegatesTab extends StatefulWidget {
  const _DelegatesTab({
    required this.repository,
    required this.courseId,
    required this.students,
    required this.delegates,
    required this.onUpdated,
  });

  final LecturerCoursesRepository repository;
  final String courseId;
  final List<CourseStudent> students;
  final List<CourseDelegate> delegates;
  final Future<void> Function() onUpdated;

  @override
  State<_DelegatesTab> createState() => _DelegatesTabState();
}

class _DelegatesTabState extends State<_DelegatesTab> {
  bool _isWorking = false;

  Future<void> _assignDelegate() async {
    if (widget.students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enroll students first before assigning delegates.'),
        ),
      );
      return;
    }

    String selectedStudentId = widget.students.first.id;
    bool canUpload = true;
    bool canEdit = false;
    bool canDelete = false;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Delegate'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedStudentId,
                      items: widget.students
                          .map(
                            (CourseStudent s) => DropdownMenuItem<String>(
                              value: s.id,
                              child: Text('${s.fullName} (${s.email})'),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStudentId = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Student'),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: canUpload,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          canUpload = value ?? false;
                        });
                      },
                      title: const Text('Can upload notes'),
                    ),
                    CheckboxListTile(
                      value: canEdit,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          canEdit = value ?? false;
                        });
                      },
                      title: const Text('Can edit notes'),
                    ),
                    CheckboxListTile(
                      value: canDelete,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          canDelete = value ?? false;
                        });
                      },
                      title: const Text('Can delete notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() => _isWorking = true);
    try {
      await widget.repository.assignDelegate(
        courseId: widget.courseId,
        studentId: selectedStudentId,
        canUploadNotes: canUpload,
        canEditNotes: canEdit,
        canDeleteNotes: canDelete,
      );
      await widget.onUpdated();
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _editDelegate(CourseDelegate delegate) async {
    bool canUpload = delegate.canUploadNotes;
    bool canEdit = delegate.canEditNotes;
    bool canDelete = delegate.canDeleteNotes;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${delegate.studentName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: canUpload,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        canUpload = value ?? false;
                      });
                    },
                    title: const Text('Can upload notes'),
                  ),
                  CheckboxListTile(
                    value: canEdit,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        canEdit = value ?? false;
                      });
                    },
                    title: const Text('Can edit notes'),
                  ),
                  CheckboxListTile(
                    value: canDelete,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        canDelete = value ?? false;
                      });
                    },
                    title: const Text('Can delete notes'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await widget.repository.updateDelegatePermissions(
      courseId: widget.courseId,
      delegateId: delegate.id,
      canUploadNotes: canUpload,
      canEditNotes: canEdit,
      canDeleteNotes: canDelete,
    );
    await widget.onUpdated();
  }

  Future<void> _removeDelegate(CourseDelegate delegate) async {
    await widget.repository.removeDelegate(
      courseId: widget.courseId,
      delegateId: delegate.id,
    );
    await widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: _isWorking ? null : _assignDelegate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF58220),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.admin_panel_settings_rounded),
          label: const Text('Assign Delegate'),
        ),
        const SizedBox(height: 12),
        if (widget.delegates.isEmpty)
          const Text(
            'No delegates assigned.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          )
        else
          ...widget.delegates.map((CourseDelegate delegate) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              delegate.studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              delegate.studentEmail,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _editDelegate(delegate),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _removeDelegate(delegate),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _permissionChip('Upload', delegate.canUploadNotes),
                      _permissionChip('Edit', delegate.canEditNotes),
                      _permissionChip('Delete', delegate.canDeleteNotes),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _permissionChip(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (enabled ? const Color(0x1AF58220) : const Color(0x1A64748B)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: ${enabled ? 'Yes' : 'No'}',
        style: TextStyle(
          color: enabled ? const Color(0xFFF58220) : const Color(0xFF94A3B8),
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  final LecturerCourse course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _GlassTile(
          icon: Icons.info_outline_rounded,
          title: 'Semester: ${course.semester}',
          subtitle: 'Archived: ${course.archived ? 'Yes' : 'No'}',
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Course'),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: onDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7F1D1D),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete Course'),
        ),
      ],
    );
  }
}

>>>>>>> Stashed changes
class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.icon,
    required this.title,
    required this.subtitle,
<<<<<<< Updated upstream
    this.onTap,
=======
>>>>>>> Stashed changes
  });

  final IconData icon;
  final String title;
  final String subtitle;
<<<<<<< Updated upstream
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF58220)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
=======

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF58220)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
class _SimpleTabBody extends StatelessWidget {
  const _SimpleTabBody({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
=======
String _date(DateTime value) {
  final String y = value.year.toString();
  final String m = value.month.toString().padLeft(2, '0');
  final String d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
>>>>>>> Stashed changes
}
