import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/lecturer_courses_repository.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final LecturerCoursesRepository _repository = LecturerCoursesRepository();

  String _semester = _semesters.first;
  bool _isSubmitting = false;

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
    final String clean = _codeController.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final String next = clean.length > 7 ? clean.substring(0, 7) : clean;
    if (next != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
    setState(() {});
  }

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
        semester: _semester,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully.')),
      );
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                _glass(
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Course Code *',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                      hintText: 'CSC3141',
                    ),
                    validator: _validateCode,
                  ),
                ),
                const SizedBox(height: 12),
                _glass(
                  TextFormField(
                    controller: _titleController,
                    maxLength: 100,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Course Title *',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _glass(
                  DropdownButtonFormField<String>(
                    initialValue: _semester,
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Semester *',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    items: _semesters
                        .map(
                          (String item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value == null) return;
                      setState(() => _semester = value);
                    },
                  ),
                ),
                const SizedBox(height: 14),
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
                  );
                }),
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
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(_isSubmitting ? 'Creating...' : 'Create Course'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glass(Widget child) {
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
