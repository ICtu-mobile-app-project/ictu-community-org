import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as excel_pkg;

import '../data/timetable_repository.dart';
import '../../../core/services/offline_service.dart';

class AdminTimetableManagementScreen extends StatefulWidget {
  const AdminTimetableManagementScreen({super.key});

  @override
  State<AdminTimetableManagementScreen> createState() =>
      _AdminTimetableManagementScreenState();
}

class _AdminTimetableManagementScreenState
    extends State<AdminTimetableManagementScreen> {
  final TimetableRepository _repository = TimetableRepository(
    Supabase.instance.client,
    OfflineService(),
  );
  bool _isProcessing = false;
  String? _statusMessage;

  Future<void> _pickAndUploadCsv() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Selecting file...';
    });

    try {
      // Use FileType.any to avoid restrictive system filters that can make folders unselectable
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        return;
      }

      final String path = result.files.single.path!;
      final String extension = path.toLowerCase().split('.').last;
      
      if (extension != 'csv' && extension != 'xlsx' && extension != 'xls') {
        throw Exception('Selected file is not a CSV or Excel file.');
      }

      setState(() => _statusMessage = 'Parsing file...');
      List<Map<String, dynamic>> schedules = [];

      if (extension == 'csv') {
        final File file = File(path);
        final String csvContent = await file.readAsString();
        schedules = _parseCsv(csvContent);
      } else {
        final bytes = File(path).readAsBytesSync();
        schedules = _parseExcel(bytes);
      }

      if (schedules.isEmpty) {
        throw Exception('No valid schedule rows found in CSV');
      }

      // Option: Clear existing or append. For a "Master Timetable" we usually replace.
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Clear Existing Timetable?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'This will delete all current schedule entries before importing the new ones. This action cannot be undone.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear & Import', style: TextStyle(color: Color(0xFFF58220))),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        return;
      }

      setState(() => _statusMessage = 'Clearing database...');
      await _repository.clearTimetable();

      setState(() => _statusMessage = 'Uploading ${schedules.length} entries...');
      await _repository.uploadSchedules(schedules);

      setState(() {
        _isProcessing = false;
        _statusMessage = 'Successfully imported ${schedules.length} entries!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${schedules.length} classes')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  List<Map<String, dynamic>> _parseExcel(List<int> bytes) {
    final excel = excel_pkg.Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> schedules = [];
    
    // Process the first sheet
    final String sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];
    
    if (table == null) return [];

    String? currentDay;

    for (var row in table.rows) {
      if (row.isEmpty) continue;

      final firstCell = row[0]?.value?.toString().toUpperCase() ?? '';
      
      if (['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'].contains(firstCell)) {
        currentDay = firstCell;
        continue;
      }

      if (firstCell == 'TIME') continue;

      if (currentDay != null && row.length >= 2) {
        String timeStr = row[0]?.value?.toString() ?? '';
        if (timeStr.isEmpty && schedules.isNotEmpty) {
           timeStr = '${schedules.last['start_time']} - ${schedules.last['end_time']}';
        }

        if (timeStr.contains('-')) {
          final times = timeStr.split('-');
          final String startTime = _formatTime(times[0].trim());
          final String endTime = _formatTime(times[1].trim());
          
          final String courseRaw = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';
          if (courseRaw.isEmpty) continue;

          final String courseCode = _extractCourseCode(courseRaw);
          final String courseName = courseRaw.replaceFirst(courseCode, '').trim();
          
          final String lecturer = row.length > 2 ? row[2]?.value?.toString() ?? '' : '';
          final String hall = row.length > 3 ? row[3]?.value?.toString() ?? '' : '';
          
          String? groupName;
          if (courseName.contains('Group')) {
             final groupMatch = RegExp(r'Group\s+\d+').firstMatch(courseName);
             groupName = groupMatch?.group(0);
          }

          schedules.add({
            'course_code': courseCode,
            'course_name': courseName,
            'lecturer': lecturer,
            'hall': hall,
            'day_of_week': currentDay,
            'start_time': startTime,
            'end_time': endTime,
            'group_name': groupName,
          });
        }
      }
    }
    return schedules;
  }

  List<Map<String, dynamic>> _parseCsv(String content) {
    final List<Map<String, dynamic>> schedules = [];
    final List<String> lines = const LineSplitter().convert(content);
    
    String? currentDay;
    
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.isEmpty) continue;

      // Detect Day headers (e.g., "MONDAY,,,,")
      final List<String> parts = line.split(',');
      final String firstPart = parts[0].toUpperCase();
      
      if (['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'].contains(firstPart)) {
        currentDay = firstPart;
        continue;
      }

      // Skip header lines like "TIME,COURSE,LECTURER,HALL"
      if (firstPart == 'TIME') continue;

      // Process data lines
      if (currentDay != null && parts.length >= 2) {
        String timeStr = parts[0].trim();
        // If time is empty, it might be a continuation of the previous time slot (CSV merge cells)
        if (timeStr.isEmpty && schedules.isNotEmpty) {
           timeStr = '${schedules.last['start_time']} - ${schedules.last['end_time']}';
        }

        if (timeStr.contains('-')) {
          final times = timeStr.split('-');
          final String startTime = _formatTime(times[0].trim());
          final String endTime = _formatTime(times[1].trim());
          
          final String courseRaw = parts.length > 1 ? parts[1].trim() : '';
          if (courseRaw.isEmpty) continue;

          // Extract Course Code and Name
          // Example: "JMC 3271 Digital Marketing" -> "JMC 3271" and "Digital Marketing"
          final String courseCode = _extractCourseCode(courseRaw);
          final String courseName = courseRaw.replaceFirst(courseCode, '').trim();
          
          final String lecturer = parts.length > 2 ? parts[2].trim() : '';
          final String hall = parts.length > 3 ? parts[3].trim() : '';
          
          // Extract Group
          String? groupName;
          if (courseName.contains('Group')) {
             final groupMatch = RegExp(r'Group\s+\d+').firstMatch(courseName);
             groupName = groupMatch?.group(0);
          }

          schedules.add({
            'course_code': courseCode,
            'course_name': courseName,
            'lecturer': lecturer,
            'hall': hall,
            'day_of_week': currentDay,
            'start_time': startTime,
            'end_time': endTime,
            'group_name': groupName,
          });
        }
      }
    }
    return schedules;
  }

  String _formatTime(String raw) {
    // Converts "8:00" or "08:00" or "8:00 AM" to "08:00:00"
    try {
      final cleanRaw = raw.toUpperCase().replaceAll(' ', '');
      final isPM = cleanRaw.contains('PM');
      final isAM = cleanRaw.contains('AM');
      
      String timePart = cleanRaw.replaceAll('AM', '').replaceAll('PM', '');
      final parts = timePart.split(':');
      
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      
      // Heuristic: if no AM/PM, and hour < 7, it's likely PM (e.g., 2:00 -> 14:00)
      if (!isAM && !isPM && hour < 7) hour += 12; 

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
    } catch (_) {
      return '00:00:00';
    }
  }

  String _extractCourseCode(String raw) {
    // Regex for typical codes: SEN 3243, ICT1210, JMC 2271, SWE 4112
    final match = RegExp(r'([A-Z]{2,4})\s?(\d{4})').firstMatch(raw.toUpperCase());
    if (match != null) {
      return '${match.group(1)} ${match.group(2)}';
    }
    return 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Timetable Management'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF58220).withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  size: 64,
                  color: Color(0xFFF58220),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Upload Master Timetable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select a CSV or Excel file formatted with Days (MONDAY-FRIDAY) and columns: TIME, COURSE, LECTURER, HALL.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 48),
              if (_isProcessing) ...[
                const CircularProgressIndicator(color: Color(0xFFF58220)),
                const SizedBox(height: 16),
                Text(
                  _statusMessage ?? '',
                  style: const TextStyle(color: Color(0xFFF58220)),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _pickAndUploadCsv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF58220),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text(
                      'Upload Timetable File',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _statusMessage!.startsWith('Error')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
