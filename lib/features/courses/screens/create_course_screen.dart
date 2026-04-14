import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

<<<<<<< Updated upstream
import '../data/lecturer_courses_repository.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});
=======
import '../../../core/constants/ictu_constants.dart';
import '../../../core/validation/course_code_validator.dart';
import '../data/lecturer_courses_repository.dart';
import '../models/lecturer_course.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({
    super.key,
    required this.repository,
    required this.lecturerId,
    required this.lecturerName,
  });

  final LecturerCoursesRepository repository;
  final String lecturerId;
  final String lecturerName;
>>>>>>> Stashed changes

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
<<<<<<< Updated upstream
  static const List<String> _semesters = <String>[
    'Fall 2025',
    'Spring 2026',
    'Summer 2025',
  ];

  static const Map<String, String> _sampleCourses = <String, String>{
    'SEN3141': 'Software Design and Modelling',
    'ICT2111': 'Technical Writing for Engineers',
    'CYS4151': 'Ethical Hacking',
    'CSC4121': 'Artificial Intelligence',
  };

=======
>>>>>>> Stashed changes
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
<<<<<<< Updated upstream
  final LecturerCoursesRepository _repository = LecturerCoursesRepository();

  String _semester = _semesters.first;
  bool _isSubmitting = false;
=======

  String _semester = ICTUConstants.semesters.first;
  bool _isSubmitting = false;
  String? _error;

  List<MapEntry<String, String>> get _suggestions {
    final String code = _codeController.text.trim().toUpperCase();
    final String title = _titleController.text.trim().toLowerCase();

    return ICTUConstants.sampleCourses.entries
        .where((entry) {
          if (code.isEmpty && title.isEmpty) {
            return true;
          }
          return entry.key.contains(code) ||
              entry.value.toLowerCase().contains(title);
        })
        .take(6)
        .toList();
  }
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_normalizeCode);
  }

  @override
  void dispose() {
    _codeController.removeListener(_normalizeCode);
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _normalizeCode() {
<<<<<<< Updated upstream
    final String clean = _codeController.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final String next = clean.length > 7 ? clean.substring(0, 7) : clean;
    if (next != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
=======
    final String normalized = CourseCodeValidator.formatTyped(
      _codeController.text,
    );
    if (normalized != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
>>>>>>> Stashed changes
      );
    }
    setState(() {});
  }

<<<<<<< Updated upstream
  String? _validateCode(String? value) {
    final String code = (value ?? '').trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}\d{4}$').hasMatch(code)) {
      return 'Code must match format XXX####';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _repository.createCourse(
        courseCode: _codeController.text,
        title: _titleController.text,
        description: _descriptionController.text,
=======
  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String code = _codeController.text.trim().toUpperCase();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bool exists = await widget.repository.courseCodeExists(code);
      if (exists) {
        setState(() {
          _error = 'Course code already exists.';
          _isSubmitting = false;
        });
        return;
      }

      final bool canTeach = await widget.repository.canTeachDepartment(
        lecturerId: widget.lecturerId,
        courseCode: code,
      );

      if (!canTeach) {
        setState(() {
          _error = 'You cannot create a course outside your department.';
          _isSubmitting = false;
        });
        return;
      }

      final LecturerCourse created = await widget.repository.createCourse(
        lecturerId: widget.lecturerId,
        lecturerName: widget.lecturerName,
        courseCode: code,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
>>>>>>> Stashed changes
        semester: _semester,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully.')),
      );
<<<<<<< Updated upstream
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
=======

      Navigator.of(context).pop<LecturerCourse>(created);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not create course: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
>>>>>>> Stashed changes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    final Iterable<MapEntry<String, String>> suggestions = _sampleCourses
        .entries
        .where(
          (MapEntry<String, String> e) =>
              _codeController.text.isEmpty ||
              e.key.contains(_codeController.text.toUpperCase()) ||
              e.value.toLowerCase().contains(
                _titleController.text.toLowerCase(),
              ),
        );

=======
>>>>>>> Stashed changes
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Create Course',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            child: Column(
<<<<<<< Updated upstream
              children: [
                _glass(
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white),
=======
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _glassCard(
                  child: TextFormField(
                    controller: _codeController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.characters,
>>>>>>> Stashed changes
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Course Code *',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                      hintText: 'CSC3141',
                    ),
<<<<<<< Updated upstream
                    validator: _validateCode,
                  ),
                ),
                const SizedBox(height: 12),
                _glass(
                  TextFormField(
                    controller: _titleController,
                    maxLength: 100,
                    style: const TextStyle(color: Colors.white),
=======
                    validator: CourseCodeValidator.validate,
                  ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    maxLength: 100,
>>>>>>> Stashed changes
                    decoration: const InputDecoration(
                      labelText: 'Course Title *',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
<<<<<<< Updated upstream
                    validator: (String? value) => (value ?? '').trim().isEmpty
                        ? 'Title is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                _glass(
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 500,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
=======
                    validator: (String? value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Course title is required';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    maxLength: 500,
>>>>>>> Stashed changes
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
<<<<<<< Updated upstream
                _glass(
                  DropdownButtonFormField<String>(
=======
                _glassCard(
                  child: DropdownButtonFormField<String>(
>>>>>>> Stashed changes
                    initialValue: _semester,
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Semester *',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
<<<<<<< Updated upstream
                    items: _semesters
=======
                    items: ICTUConstants.semesters
>>>>>>> Stashed changes
                        .map(
                          (String item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
<<<<<<< Updated upstream
                      if (value == null) return;
                      setState(() => _semester = value);
=======
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _semester = value;
                      });
>>>>>>> Stashed changes
                    },
                  ),
                ),
                const SizedBox(height: 14),
<<<<<<< Updated upstream
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggestions',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...suggestions.take(6).map((entry) {
                  return InkWell(
=======
                const Text(
                  'ICTU Suggestions',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._suggestions.map(
                  (entry) => InkWell(
>>>>>>> Stashed changes
                    onTap: () {
                      _codeController.text = entry.key;
                      _titleController.text = entry.value;
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Color(0xFFF58220),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(color: Color(0xFFF1F5F9)),
                            ),
                          ),
                        ],
                      ),
                    ),
<<<<<<< Updated upstream
                  );
                }),
=======
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFF87171)),
                    ),
                  ),
>>>>>>> Stashed changes
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF58220),
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
<<<<<<< Updated upstream
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(_isSubmitting ? 'Creating...' : 'Create Course'),
=======
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      _isSubmitting ? 'Creating...' : 'Create Course',
                    ),
>>>>>>> Stashed changes
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _glass(Widget child) {
=======
  Widget _glassCard({required Widget child}) {
>>>>>>> Stashed changes
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}
