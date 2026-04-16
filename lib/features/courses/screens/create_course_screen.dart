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
    if (clean != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _repository.createCourse(
        courseCode: _codeController.text,
        title: _titleController.text,
        semester: _semester,
        description: _descriptionController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating course: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Create New Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Course Code',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. SWE4112'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Course Title',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. Mobile Application Development'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Semester',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _semester,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(''),
                items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _semester = v!),
              ),
              const SizedBox(height: 24),
              const Text(
                'Description (Optional)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _inputDecoration('Brief overview of the course'),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Course', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
