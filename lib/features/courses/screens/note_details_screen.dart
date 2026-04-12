import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/models/user_role.dart';
import '../data/notes_service.dart';
import '../models/course_note.dart';

class NoteDetailsScreen extends StatefulWidget {
  const NoteDetailsScreen({
    super.key,
    required this.note,
    this.role = UserRole.student,
  });

  final CourseNote note;
  final UserRole role;

  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  final NotesService _service = NotesService();
  bool _isWorking = false;

  bool get _isOwnerActionAllowed =>
      widget.role == UserRole.lecturer || widget.role.isDelegate;

  Future<void> _download() async {
    setState(() => _isWorking = true);
    try {
      final String url = await _service.createDownloadUrl(widget.note.filePath);
      final bool launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open download link.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _share() async {
    final String url = await _service.createDownloadUrl(widget.note.filePath);
    await Share.share(url, subject: widget.note.title);
  }

  Future<void> _editTitle() async {
    final TextEditingController ctrl = TextEditingController(
      text: widget.note.title,
    );
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit Note Title'),
        content: TextField(controller: ctrl),
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
      ),
    );

    if (save != true) return;
    await _service.updateNoteTitle(widget.note.id, ctrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Title updated. Refresh notes list to see changes.'),
      ),
    );
  }

  Future<void> _delete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete note?'),
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
      ),
    );

    if (confirm != true) return;
    await _service.deleteNote(widget.note.id, widget.note.filePath);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.note.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isWorking ? null : _download,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _isWorking ? null : _share,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share'),
                ),
                const Spacer(),
                if (_isOwnerActionAllowed)
                  IconButton(
                    onPressed: _editTitle,
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                if (_isOwnerActionAllowed)
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
              ],
            ),
          ),
          Expanded(
            child: widget.note.isPdf
                ? FutureBuilder<String>(
                    future: _service.createDownloadUrl(widget.note.filePath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF58220),
                          ),
                        );
                      }
                      if (snapshot.hasError ||
                          snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'Could not load PDF preview.',
                            style: TextStyle(color: Color(0xFFF87171)),
                          ),
                        );
                      }
                      return SfPdfViewer.network(snapshot.data!);
                    },
                  )
                : _DocViewerHint(note: widget.note),
          ),
        ],
      ),
    );
  }
}

class _DocViewerHint extends StatelessWidget {
  const _DocViewerHint({required this.note});

  final CourseNote note;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_rounded,
              size: 64,
              color: Color(0xFFF58220),
            ),
            const SizedBox(height: 14),
            Text(
              note.fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'DOC/DOCX files open in your system viewer. Use Download button above.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
