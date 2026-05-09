import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ictu_community_org/features/alerts/data/alerts_service.dart';
import 'package:ictu_community_org/features/alerts/models/alert_item.dart';
import 'package:ictu_community_org/features/courses/data/notes_service.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_option.dart';

class CreateAlertScreen extends StatefulWidget {
  const CreateAlertScreen({super.key, this.initialCourseCode});

  final String? initialCourseCode;

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AlertsService _alertsService = AlertsService();
  final NotesService _notesService = NotesService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _submissionLinkController = TextEditingController();

  List<LecturerCourseOption> _courses = <LecturerCourseOption>[];
  String? _selectedCourseCode;
  AlertType _type = AlertType.assignment;
  DateTime? _deadline;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _submissionLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final List<LecturerCourseOption> courses = await _notesService.getLecturerCourses();
      if (!mounted) {
        return;
      }
      setState(() {
        _courses = courses;
        _selectedCourseCode = widget.initialCourseCode ??
            (courses.isNotEmpty ? courses.first.code : null);
      });
    } catch (_) {
      // Leave empty list and let validation handle submit.
    }
  }

  Future<void> _pickDeadline() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(hours: 1))),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedCourseCode == null || _selectedCourseCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course.')),
      );
      return;
    }

    if (_type != AlertType.notice) {
      if (_deadline == null || !_deadline!.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deadline must be a future date/time.')),
        );
        return;
      }
    }

    final List<String> requirements = _requirementsController.text
        .split('\n')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);

    setState(() => _isSubmitting = true);

    try {
      await _alertsService.createAlert(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        courseCode: _selectedCourseCode!,
        deadline: _type == AlertType.notice ? null : _deadline,
        requirements: requirements,
        submissionLink: _submissionLinkController.text.trim().isEmpty 
            ? null 
            : _submissionLinkController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert created successfully.')),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Create Alert',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 100,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title *',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<AlertType>(
              initialValue: _type,
              dropdownColor: const Color(0xFF111827),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Type *',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
              items: AlertType.values
                  .map(
                    (AlertType item) => DropdownMenuItem<AlertType>(
                      value: item,
                      child: Text(alertTypeLabel(item)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (AlertType? value) {
                if (value == null) {
                  return;
                }
                setState(() => _type = value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedCourseCode,
              dropdownColor: const Color(0xFF111827),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Course *',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
              items: _courses
                  .map(
                    (LecturerCourseOption item) => DropdownMenuItem<String>(
                      value: item.code,
                      child: Text('${item.code} • ${item.title}'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String? value) {
                setState(() => _selectedCourseCode = value);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              maxLength: 1000,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description *',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.white.withValues(alpha: 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              title: Text(
                _deadline == null
                    ? (_type == AlertType.notice ? 'Deadline (optional)' : 'Deadline *')
                    : 'Deadline: ${_deadline!.toLocal()}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              trailing: const Icon(Icons.event_rounded, color: Color(0xFFF58220)),
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _requirementsController,
              maxLength: 600,
              minLines: 3,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Requirements (one per line)',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                hintText: '- Bring laptop\n- Submit PDF\n- Team of 3',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _submissionLinkController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Submission Link (Optional)',
                hintText: 'e.g. Google Drive or Form link',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.link_rounded, color: Color(0xFF94A3B8)),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.startsWith('http')) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF58220),
                foregroundColor: Colors.white,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSubmitting ? 'Creating...' : 'Create Alert'),
            ),
          ],
        ),
      ),
    );
  }
}

