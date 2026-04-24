import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';
import 'package:ictu_community_org/features/courses/data/course_notes_repository.dart';
import 'package:ictu_community_org/features/courses/data/supabase_course_notes_repository.dart';
import 'package:ictu_community_org/features/courses/models/course_note.dart';

class CourseNotesScreen extends StatefulWidget {
  const CourseNotesScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.canUpload,
  });

  final String courseId;
  final String title;
  final bool canUpload;

  @override
  State<CourseNotesScreen> createState() => _CourseNotesScreenState();
}

class _CourseNotesScreenState extends State<CourseNotesScreen> {
  late final CourseNotesRepository _repository;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isUploading = false;
  String _sort = 'newest';
  String? _error;
  List<CourseNote> _notes = <CourseNote>[];

  @override
  void initState() {
    super.initState();
    _repository = SupabaseCourseNotesRepository();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<CourseNote> notes = await _repository.listNotes(
        courseId: widget.courseId,
        searchQuery: _searchController.text.trim(),
        sort: _sort,
      );
      if (!mounted) return;
      setState(() {
        _notes = notes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadNote() async {
    if (!SupabaseBootstrap.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supabase is not configured.')),
      );
      return;
    }

    _titleController.clear();
    _descriptionController.clear();

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Title *'),
              ),
              TextField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
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
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    if (proceed != true) {
      return;
    }

    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note title is required.')));
      return;
    }

    final FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf', 'doc', 'docx'],
      withData: true,
    );

    if (fileResult == null || fileResult.files.isEmpty) {
      return;
    }

    final PlatformFile file = fileResult.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file bytes.')),
      );
      return;
    }

    if (file.size > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File size exceeds 10MB.')));
      return;
    }

    final String ext = file.name.toLowerCase();
    if (!(ext.endsWith('.pdf') ||
        ext.endsWith('.doc') ||
        ext.endsWith('.docx'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allowed formats are PDF, DOC, DOCX.')),
      );
      return;
    }

    final String uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login again.')));
      return;
    }

    final String objectPath =
        'notes/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    setState(() {
      _isUploading = true;
    });

    try {
      await Supabase.instance.client.storage
          .from('lecture-notes')
          .uploadBinary(
            objectPath,
            Uint8List.fromList(file.bytes!),
            fileOptions: const FileOptions(upsert: false),
          );

      await _repository.createNote(
        courseId: widget.courseId,
        title: title,
        description: _descriptionController.text.trim(),
        contentUrl: objectPath,
        fileName: file.name,
        fileSizeBytes: file.size,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _download(CourseNote note) async {
    try {
      final String url = await _repository.createDownloadUrl(noteId: note.id);
      if (url.isEmpty) {
        throw Exception('Download URL is empty');
      }
      final Uri uri = Uri.parse(url);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open download URL.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
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
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: widget.canUpload
          ? FloatingActionButton.extended(
              onPressed: _isUploading ? null : _uploadNote,
              backgroundColor: const Color(0xFFF58220),
              foregroundColor: Colors.white,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Note'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search notes',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                      ),
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
                    setState(() {
                      _sort = value;
                    });
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: Color(0xFFF58220)),
                ),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFF87171)))
            else if (_notes.isEmpty)
              const Text(
                'No notes found for this course.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              )
            else
              ..._notes.map((CourseNote note) {
                final bool isPdf = note.fileName.toLowerCase().endsWith('.pdf');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.description_rounded,
                        color: const Color(0xFFF58220),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${note.uploadedByName} • ${note.sizeLabel}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _download(note),
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Color(0xFFF58220),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
