import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/courses/data/notes_service.dart';
import 'package:ictu_community_org/features/courses/models/course_note.dart';

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
  double _downloadProgress = 0;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
  }

  Future<void> _checkLocalFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(
        directory.path,
        '${widget.note.id}_${widget.note.fileName}',
      );
      if (await File(filePath).exists()) {
        if (mounted) {
          setState(() {
            _localFilePath = filePath;
          });
        }
      }
    } catch (_) {}
  }

  bool get _isOwnerActionAllowed =>
      widget.role == UserRole.lecturer || widget.role.isDelegate;

  Future<void> _download() async {
    if (_localFilePath != null) {
      final file = File(_localFilePath!);
      if (await file.exists()) {
        await OpenFilex.open(_localFilePath!);
        return;
      }
    }

    setState(() {
      _isWorking = true;
      _downloadProgress = 0;
    });

    try {
      final String url = await _service.createDownloadUrl(widget.note.filePath);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(
        directory.path,
        '${widget.note.id}_${widget.note.fileName}',
      );

      await Dio().download(
        url,
        filePath,
        onReceiveProgress: (int count, int total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = count / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _localFilePath = filePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved to device.')),
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
    try {
      if (_localFilePath != null && await File(_localFilePath!).exists()) {
        await Share.shareXFiles(
          [XFile(_localFilePath!)],
          text: widget.note.title,
        );
        return;
      }

      final String url = await _service.createDownloadUrl(widget.note.filePath);
      await Share.share(url, subject: widget.note.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _editNote() async {
    final TextEditingController titleCtrl = TextEditingController(text: widget.note.title);
    final TextEditingController descCtrl = TextEditingController(text: widget.note.description);
    final TextEditingController summaryCtrl = TextEditingController(text: widget.note.summary);
    String currentStatus = widget.note.status;

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Note Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: summaryCtrl,
                  decoration: const InputDecoration(labelText: 'Summary (Optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: currentStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'published', child: Text('Published')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => currentStatus = val);
                  },
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
        ),
      ),
    );

    if (save != true) return;
    
    setState(() => _isWorking = true);
    try {
      await _service.updateNote(
        noteId: widget.note.id,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        summary: summaryCtrl.text.trim(),
        status: currentStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _delete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
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
        automaticallyImplyLeading: false,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.note.status == 'draft')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This note is a DRAFT. Students cannot see it.',
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.note.description.isNotEmpty) ...[
                  Text(
                    widget.note.description,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.note.summary.isNotEmpty) ...[
                  const Text(
                    'Summary',
                    style: TextStyle(
                      color: Color(0xFFF58220),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.note.summary,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isWorking ? null : _download,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF58220),
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        _localFilePath != null
                            ? Icons.open_in_new_rounded
                            : Icons.download_rounded,
                      ),
                      label: Text(
                        _isWorking
                            ? '${(_downloadProgress * 100).toInt()}%'
                            : (_localFilePath != null ? 'Open' : 'Download'),
                      ),
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
                        onPressed: _isWorking ? null : _editNote,
                        icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      ),
                    if (_isOwnerActionAllowed)
                      IconButton(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child:
                widget.note.isPdf
                    ? (_localFilePath != null
                        ? SfPdfViewer.file(File(_localFilePath!))
                        : FutureBuilder<String>(
                          future: _service.createDownloadUrl(
                            widget.note.filePath,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
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
                        ))
                    : _NonPdfViewer(
                      note: widget.note,
                      localPath: _localFilePath,
                      onDownload: _download,
                      isWorking: _isWorking,
                      progress: _downloadProgress,
                    ),
          ),
        ],
      ),
    );
  }
}

class _NonPdfViewer extends StatelessWidget {
  const _NonPdfViewer({
    required this.note,
    this.localPath,
    required this.onDownload,
    required this.isWorking,
    required this.progress,
  });

  final CourseNote note;
  final String? localPath;
  final VoidCallback onDownload;
  final bool isWorking;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getFileIcon(note.fileName),
              size: 80,
              color: const Color(0xFFF58220),
            ),
            const SizedBox(height: 20),
            Text(
              note.fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: isWorking ? null : onDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF58220),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    isWorking
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${(progress * 100).toInt()}%'),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              localPath != null
                                  ? Icons.open_in_new_rounded
                                  : Icons.download_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localPath != null ? 'Open to View' : 'Download Now',
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Files like DOC and DOCX require an external viewer app (e.g., Word, Google Docs).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext == '.doc' || ext == '.docx') return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
