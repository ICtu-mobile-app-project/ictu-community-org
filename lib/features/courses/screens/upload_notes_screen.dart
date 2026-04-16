import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/notes_service.dart';
import '../models/course_note.dart';
import '../models/lecturer_course_option.dart';
import '../models/note_upload_session.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  final NotesService _service = NotesService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<LecturerCourseOption> _courses = <LecturerCourseOption>[];
  LecturerCourseOption? _selectedCourse;
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final List<LecturerCourseOption> courses = await _service
        .getLecturerCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      if (courses.isNotEmpty) {
        _selectedCourse = courses.first;
      }
    });
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile item = result.files.first;
    if (item.path == null) {
      setState(() {
        _error = 'Could not access selected file path.';
      });
      return;
    }

    setState(() {
      _selectedFile = File(item.path!);
      _error = null;
    });
  }

  Future<void> _upload() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Note title is required.');
      return;
    }
    if (_selectedCourse == null) {
      setState(() => _error = 'Please select a course.');
      return;
    }
    if (_selectedFile == null) {
      setState(() => _error = 'Please select a PDF/DOC/DOCX file.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1;
      _uploadStatus = 'Preparing upload...';
      _error = null;
    });

    try {
      await _service.uploadNote(
        file: _selectedFile!,
        title: title,
        courseId: _selectedCourse!.id,
        courseCode: _selectedCourse!.code,
        description: _descriptionController.text.trim(),
        strategy: NoteUploadStrategy.chunkedRetry,
        onProgress: (NoteUploadProgress progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _uploadProgress = progress.fraction;
            _uploadStatus = progress.message;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _uploadProgress = 1;
        _uploadStatus = 'Upload complete.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? fileName = _selectedFile == null
        ? null
        : _selectedFile!.path.split(Platform.pathSeparator).last;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Upload Notes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _glass(
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Note Title *',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            DropdownButtonFormField<String>(
              initialValue: _selectedCourse?.id,
              dropdownColor: const Color(0xFF111827),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Course *',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
              items: _courses
                  .map(
                    (LecturerCourseOption course) => DropdownMenuItem<String>(
                      value: course.id,
                      child: Text('${course.code} • ${course.title}'),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) return;
                setState(() {
                  _selectedCourse = _courses.firstWhere((c) => c.id == value);
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            TextField(
              controller: _descriptionController,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected File',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fileName ?? 'No file selected.',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickFile,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Pick PDF/DOC/DOCX'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Max size: ${NotesService.maxNoteUploadBytes ~/ (1024 * 1024)}MB',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
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
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    color: const Color(0xFFF58220),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadStatus,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _upload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF58220),
              foregroundColor: Colors.white,
            ),
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(_isUploading ? 'Uploading...' : 'Upload Note'),
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
