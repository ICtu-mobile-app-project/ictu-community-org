import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../data/notes_service.dart';
import '../models/course_note.dart';
import 'package:ictu_community_org/features/courses/screens/note_details_screen.dart';
import 'package:ictu_community_org/features/courses/screens/upload_notes_screen.dart';

class CourseNotesListScreen extends StatefulWidget {
  const CourseNotesListScreen({
    super.key,
    required this.courseId,
    required this.courseCode,
    required this.role,
  });

  final String courseId;
  final String courseCode;
  final UserRole role;

  @override
  State<CourseNotesListScreen> createState() => _CourseNotesListScreenState();
}

class _CourseNotesListScreenState extends State<CourseNotesListScreen> {
  final NotesService _service = NotesService();
  final TextEditingController _searchController = TextEditingController();

  List<CourseNote> _notes = <CourseNote>[];
  bool _isLoading = true;
  String _sort = 'newest';
  String? _error;

  bool get _canUpload =>
      widget.role == UserRole.lecturer || widget.role.isDelegate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<CourseNote> items = await _service.listNotes(
        courseId: widget.courseId,
        courseCode: widget.courseCode,
        search: _searchController.text.trim(),
        sort: _sort,
      );
      if (!mounted) return;
      setState(() => _notes = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openUpload() async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const UploadNotesScreen()),
    );
    if (updated == true) {
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
          '${widget.courseCode} Notes',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: _canUpload
          ? FloatingActionButton.extended(
              onPressed: _openUpload,
              backgroundColor: const Color(0xFFF58220),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search notes by title',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sort,
                  dropdownColor: const Color(0xFF111827),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(value: 'title', child: Text('Title A-Z')),
                  ],
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                    _load();
                  },
                ),
              ],
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
            else if (_notes.isEmpty)
              const Text(
                'No notes available yet.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              )
            else
              ..._notes.map((CourseNote note) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NoteDetailsScreen(note: note),
                        ),
                      );
                    },
                    leading: Icon(
                      note.isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.description_rounded,
                      color: const Color(0xFFF58220),
                    ),
                    title: Text(
                      note.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${note.uploadedByName} • ${_fmtDate(note.uploadedAt)} • ${note.fileSizeLabel}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.download_rounded,
                      color: Color(0xFFF58220),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime value) {
    final String y = value.year.toString();
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
