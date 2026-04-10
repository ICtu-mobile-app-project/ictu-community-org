import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../controllers/transcription_controller.dart';
import '../data/lecture_upload_service.dart';

const Duration _maxRecordingDuration = Duration(hours: 3);
const Duration _segmentedTranscriptionThreshold = Duration(minutes: 30);

class AudioAiTranscriptionScreen extends StatefulWidget {
  const AudioAiTranscriptionScreen({super.key});

  @override
  State<AudioAiTranscriptionScreen> createState() =>
      _AudioAiTranscriptionScreenState();
}

class _AudioAiTranscriptionScreenState extends State<AudioAiTranscriptionScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<_RecordedAudio?> _recordedAudio =
      ValueNotifier<_RecordedAudio?>(null);

  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  void _openUploadQueueTab() {
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _recordedAudio.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0C10),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Audio/AI Transcription',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: _DashboardTabBar(controller: _tabController),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RecordTab(
            recordedAudio: _recordedAudio,
            onContinue: () => _tabController.animateTo(1),
            onRecordingStopped: _openUploadQueueTab,
          ),
          _UploadTab(recordedAudio: _recordedAudio),
        ],
      ),
    );
  }
}

class _DashboardTabBar extends StatelessWidget {
  const _DashboardTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFF58220), Color(0xFF1A2235)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Record'),
          Tab(text: 'Upload'),
        ],
      ),
    );
  }
}

enum _RecordUiState { idle, recording, paused, stopped }

enum _TranscribeStep {
  idle,
  uploading,
  creatingLecture,
  invokingEdge,
  completed,
}

class _RecordTab extends StatefulWidget {
  const _RecordTab({
    required this.recordedAudio,
    required this.onContinue,
    required this.onRecordingStopped,
  });

  final ValueNotifier<_RecordedAudio?> recordedAudio;
  final VoidCallback onContinue;
  final VoidCallback onRecordingStopped;

  @override
  State<_RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<_RecordTab>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _courseCodeController = TextEditingController();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  _RecordUiState _state = _RecordUiState.idle;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  bool _isStopping = false;
  Timer? _timer;
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((Duration value) {
      if (!mounted) {
        return;
      }
      setState(() => _playbackPosition = value);
    });
    _player.onDurationChanged.listen((Duration value) {
      if (!mounted) {
        return;
      }
      setState(() => _playbackDuration = value);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _player.dispose();
    _recorder.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final PermissionStatus micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (!mounted) {
          return;
        }
        _showSnack('Microphone permission is required to record audio.', true);
        return;
      }

      final Directory dir = await getTemporaryDirectory();
      final String filePath = p.join(
        dir.path,
        'ictu_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 64000,
        ),
        path: filePath,
      );

      _timer?.cancel();
      _recordingDuration = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });

        if (_recordingDuration >= _maxRecordingDuration) {
          _stopRecording(durationLimitReached: true);
        }
      });

      setState(() {
        _recordingPath = filePath;
        _state = _RecordUiState.recording;
        _playbackPosition = Duration.zero;
        _playbackDuration = Duration.zero;
        _isPlaying = false;
      });
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      _showSnack(
        'Recorder plugin is not loaded. Fully stop the app and run again.',
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        'Could not start recording: ${error.toString().replaceFirst('Exception: ', '')}',
        true,
      );
    }
  }

  Future<void> _pauseOrResume() async {
    if (_state == _RecordUiState.recording) {
      await _recorder.pause();
      setState(() => _state = _RecordUiState.paused);
      return;
    }

    if (_state == _RecordUiState.paused) {
      await _recorder.resume();
      setState(() => _state = _RecordUiState.recording);
    }
  }

  Future<void> _stopRecording({bool durationLimitReached = false}) async {
    if (_isStopping) {
      return;
    }

    setState(() => _isStopping = true);
    _timer?.cancel();

    try {
      final String? stoppedPath = await _recorder.stop().timeout(
        const Duration(seconds: 10),
        onTimeout: () => _recordingPath,
      );
      final _FinalizedRecording finalized = await _finalizeRecording(
        stoppedPath: stoppedPath,
      );

      final _RecordedAudio recorded = _RecordedAudio(
        path: finalized.path,
        bytes: finalized.bytes.length,
        dataBytes: finalized.bytes,
        duration: _recordingDuration,
        fileName: finalized.fileName,
        courseCode: _courseCodeController.text.trim().toUpperCase(),
      );

      widget.recordedAudio.value = recorded;
      widget.onRecordingStopped();

      if (!mounted) {
        return;
      }

      setState(() {
        _recordingPath = finalized.path;
        _state = _RecordUiState.stopped;
        _playbackDuration = _recordingDuration;
        _isStopping = false;
      });

      if (durationLimitReached) {
        _showSnack('Recording stopped at the 3-hour maximum duration.', false);
      }
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      setState(() => _isStopping = false);
      _showSnack(
        'Recorder stop is unavailable. Fully stop the app and run again.',
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isStopping = false);
      _showSnack('Recording could not be finalized. Please try again.', true);
    }
  }

  Future<_FinalizedRecording> _finalizeRecording({String? stoppedPath}) async {
    final List<String> candidates = <String>{
      LectureUploadService.normalizeLocalPath((stoppedPath ?? '').trim()),
      LectureUploadService.normalizeLocalPath((_recordingPath ?? '').trim()),
    }.where((String path) => path.isNotEmpty).toList();

    for (final String candidate in candidates) {
      final Uint8List? bytes = await _readRecordedBytes(candidate);
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      final String persistedPath = await _persistRecording(bytes, candidate);
      return _FinalizedRecording(
        path: persistedPath,
        bytes: bytes,
        fileName: p.basename(persistedPath),
      );
    }

    throw Exception('Recorded file was not found on device storage.');
  }

  Future<String> _persistRecording(Uint8List bytes, String sourcePath) async {
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory queueDir = Directory(p.join(root.path, 'recordings_queue'));
    if (!await queueDir.exists()) {
      await queueDir.create(recursive: true);
    }

    final String extension = p.extension(sourcePath).isEmpty
        ? '.m4a'
        : p.extension(sourcePath);
    final String persistedPath = p.join(
      queueDir.path,
      'ictu_${DateTime.now().millisecondsSinceEpoch}$extension',
    );

    await File(persistedPath).writeAsBytes(bytes, flush: true);
    return persistedPath;
  }

  Future<Uint8List?> _readRecordedBytes(String path) async {
    final File file = File(path);
    for (int i = 0; i < 20; i += 1) {
      if (await file.exists()) {
        try {
          final Uint8List bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            return bytes;
          }
        } catch (_) {
          // Some devices expose transient read errors immediately after stop.
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() {
      _state = _RecordUiState.idle;
      _recordingDuration = Duration.zero;
      _recordingPath = null;
    });
  }

  Future<void> _togglePlayback() async {
    if (_recordingPath == null) {
      return;
    }

    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    if (_playbackPosition == Duration.zero) {
      await _player.play(DeviceFileSource(_recordingPath!));
    } else {
      await _player.resume();
    }
    setState(() => _isPlaying = true);
  }

  Future<void> _seekPlayback(double millis) async {
    await _player.seek(Duration(milliseconds: millis.round()));
  }

  Future<void> _setSpeed(double speed) async {
    await _player.setPlaybackRate(speed);
    setState(() => _speed = speed);
  }

  int get _estimatedBytes {
    const int bitRate = 64000;
    final int bits = bitRate * _recordingDuration.inSeconds;
    return bits ~/ 8;
  }

  @override
  Widget build(BuildContext context) {
    final bool showDurationWarning =
        _recordingDuration >= const Duration(hours: 2, minutes: 45) &&
        _state != _RecordUiState.stopped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        if (_state != _RecordUiState.stopped) ...[
          _glassCard(
            child: TextField(
              controller: _courseCodeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'Course code (e.g. SEN3142)',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (showDurationWarning)
          _WarningBanner(
            message:
                'Recording is close to 3 hours. It will auto-stop at 03:00:00.',
          ),
        if (_state == _RecordUiState.idle) _buildIdle(),
        if (_state == _RecordUiState.recording ||
            _state == _RecordUiState.paused)
          _buildRecording(),
        if (_state == _RecordUiState.stopped) _buildStopped(),
      ],
    );
  }

  Widget _buildIdle() {
    return Column(
      children: [
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1AF58220),
              border: Border.all(color: const Color(0x66F58220), width: 2),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Color(0xFFF58220),
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tap to start recording',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Tips'),
        const SizedBox(height: 10),
        const _GlassTile(
          icon: Icons.hearing_rounded,
          title: 'Find a quiet place',
          subtitle: 'Background noise lowers transcript quality.',
        ),
        const SizedBox(height: 10),
        const _GlassTile(
          icon: Icons.settings_voice_rounded,
          title: 'Keep consistent mic distance',
          subtitle: 'Try to keep 15-30 cm between speaker and microphone.',
        ),
        const SizedBox(height: 10),
        const _GlassTile(
          icon: Icons.sd_storage_rounded,
          title: 'Max duration is 3 hours',
          subtitle:
              'Recordings above 30 minutes are transcribed in AI segments.',
        ),
      ],
    );
  }

  Widget _buildRecording() {
    final bool isPaused = _state == _RecordUiState.paused;
    final bool busy = _isStopping;
    return Column(
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 1, end: 1.1).animate(_pulse),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x33F87171),
              border: Border.all(color: const Color(0xFFF87171), width: 2),
            ),
            child: Icon(
              isPaused
                  ? Icons.pause_rounded
                  : Icons.fiber_manual_record_rounded,
              color: const Color(0xFFF87171),
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _formatDuration(_recordingDuration, includeHours: true),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 48,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Estimated size: ${_formatSize(_estimatedBytes)}',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                data: _ActionCardData(
                  icon: isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  title: isPaused ? 'Resume' : 'Pause',
                  subtitle: isPaused
                      ? 'Continue recording'
                      : 'Temporarily pause',
                  tint: const Color(0x1AF58220),
                  border: const Color(0x33F58220),
                  iconColor: const Color(0xFFF58220),
                ),
                onTap: busy ? null : _pauseOrResume,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                data: _ActionCardData(
                  icon: busy ? Icons.hourglass_top_rounded : Icons.stop_rounded,
                  title: busy ? 'Stopping...' : 'Stop',
                  subtitle: busy ? 'Finalizing audio file' : 'Finish recording',
                  tint: const Color(0x14F87171),
                  border: const Color(0x33F87171),
                  iconColor: const Color(0xFFF87171),
                ),
                onTap: busy ? null : _stopRecording,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : _cancelRecording,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildStopped() {
    final _RecordedAudio? recorded = widget.recordedAudio.value;
    if (recorded == null) {
      return const SizedBox.shrink();
    }

    final double maxMillis = max<double>(
      1,
      _playbackDuration.inMilliseconds.toDouble(),
    );
    final double currentMillis = _playbackPosition.inMilliseconds
        .toDouble()
        .clamp(0, maxMillis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassTile(
          icon: Icons.music_note_rounded,
          title: recorded.fileName,
          subtitle:
              '${_format(recorded.duration)} • ${_formatSize(recorded.bytes)}',
        ),
        const SizedBox(height: 10),
        _GlassTile(
          icon: Icons.folder_open_rounded,
          title: 'File path',
          subtitle: recorded.path,
        ),
        const SizedBox(height: 12),
        _glassCard(
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x1AF58220),
                        border: Border.all(color: const Color(0x55F58220)),
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFFF58220),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: currentMillis,
                      max: maxMillis,
                      activeColor: const Color(0xFFF58220),
                      inactiveColor: const Color(0x331E293B),
                      onChanged: _seekPlayback,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(_playbackPosition),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _format(_playbackDuration),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final double speed in const [0.5, 1.0, 1.5, 2.0]) ...[
                    _SpeedChip(
                      value: speed,
                      active: _speed == speed,
                      onTap: () => _setSpeed(speed),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                data: const _ActionCardData(
                  icon: Icons.replay_rounded,
                  title: 'Re-record',
                  subtitle: 'Discard and start over',
                  tint: Color(0x1A334155),
                  border: Color(0x22334155),
                  iconColor: Color(0xFF94A3B8),
                ),
                onTap: () {
                  widget.recordedAudio.value = null;
                  setState(() {
                    _state = _RecordUiState.idle;
                    _recordingDuration = Duration.zero;
                    _recordingPath = null;
                    _playbackPosition = Duration.zero;
                    _playbackDuration = Duration.zero;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                data: const _ActionCardData(
                  icon: Icons.north_east_rounded,
                  title: 'Continue',
                  subtitle: 'Use this audio in Upload',
                  tint: Color(0x1AF58220),
                  border: Color(0x33F58220),
                  iconColor: Color(0xFFF58220),
                ),
                onTap: widget.onContinue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  String _format(Duration value) {
    return _formatDuration(value, includeHours: false);
  }

  String _formatDuration(Duration value, {required bool includeHours}) {
    if (includeHours || value.inHours > 0) {
      final String hh = value.inHours.toString().padLeft(2, '0');
      final String mm = (value.inMinutes % 60).toString().padLeft(2, '0');
      final String ss = (value.inSeconds % 60).toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    final String mm = value.inMinutes.toString().padLeft(2, '0');
    final String ss = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _formatSize(int bytes) {
    final double kb = bytes / 1024;
    final double mb = kb / 1024;
    if (mb >= 1) {
      return '${mb.toStringAsFixed(2)} MB';
    }
    return '${kb.toStringAsFixed(0)} KB';
  }

  void _showSnack(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD14343)
            : const Color(0xFFF58220),
      ),
    );
  }
}

class _UploadTab extends StatefulWidget {
  const _UploadTab({required this.recordedAudio});

  final ValueNotifier<_RecordedAudio?> recordedAudio;

  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  final LectureUploadService _uploadService = LectureUploadService();
  final TranscriptionController _transcriptionController =
      TranscriptionController();
  final TextEditingController _courseCodeController = TextEditingController();

  _SelectedAudio? _selectedAudio;
  String? _uploadedPath;
  String? _lectureId;
  String? _localError;
  _TranscribeStep _transcribeStep = _TranscribeStep.idle;
  late final VoidCallback _recordedAudioListener;

  @override
  void initState() {
    super.initState();
    _recordedAudioListener = () {
      final _RecordedAudio? recorded = widget.recordedAudio.value;
      if (recorded == null) {
        return;
      }
      setState(() {
        _selectedAudio = _SelectedAudio(
          fileName: recorded.fileName,
          path: recorded.path.trim().isEmpty ? null : recorded.path,
          bytes: recorded.dataBytes,
          fileSize: recorded.bytes,
          duration: recorded.duration,
        );
        if (recorded.courseCode.trim().isNotEmpty) {
          _courseCodeController.text = recorded.courseCode.trim().toUpperCase();
        }
        _transcribeStep = _TranscribeStep.idle;
      });
    };
    widget.recordedAudio.addListener(_recordedAudioListener);
    _recordedAudioListener();
  }

  @override
  void dispose() {
    widget.recordedAudio.removeListener(_recordedAudioListener);
    _transcriptionController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.single;
      setState(() {
        _selectedAudio = _SelectedAudio(
          fileName: file.name,
          path: file.path,
          bytes: file.bytes,
          fileSize: file.size,
          duration: null,
        );
        _uploadedPath = null;
        _lectureId = null;
        _localError = null;
        _transcriptionController.lastResult.value = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localError =
            'Could not open file picker: ${error.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _transcribe() async {
    final _SelectedAudio? selected = _selectedAudio;
    if (selected == null) {
      setState(() => _localError = 'Please choose an audio file first.');
      return;
    }

    final String courseCode = _courseCodeController.text.trim().toUpperCase();
    if (courseCode.isNotEmpty && !_isValidCourseCode(courseCode)) {
      setState(() {
        _localError =
            'Invalid course code format. Use 3 letters + 4 digits (e.g. SEN3142).';
      });
      return;
    }

    setState(() {
      _localError = null;
      _uploadedPath = null;
      _lectureId = null;
      _transcribeStep = _TranscribeStep.uploading;
    });

    try {
      final String path;
      if (selected.bytes != null) {
        path = await _uploadService.uploadAudioBytes(
          bytes: selected.bytes!,
          fileName: selected.fileName,
        );
      } else {
        if (selected.path == null || selected.path!.isEmpty) {
          throw Exception(
            'Selected file path is unavailable on this platform.',
          );
        }
        path = await _uploadService.uploadAudioPath(
          path: selected.path!,
          fallbackFileName: selected.fileName,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _uploadedPath = path;
        _transcribeStep = _TranscribeStep.creatingLecture;
      });

      final String lectureId = await _uploadService.createLectureRow(
        audioPath: path,
        title: p.basenameWithoutExtension(selected.fileName),
        courseCode: courseCode,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lectureId = lectureId;
        _transcribeStep = _TranscribeStep.invokingEdge;
      });

      await _transcriptionController.transcribeAudio(
        lectureId: lectureId,
        audioPath: path,
      );

      final String? edgeError = _transcriptionController.errorMessage.value;
      if (edgeError != null && edgeError.trim().isNotEmpty) {
        throw Exception(edgeError.trim());
      }

      if (mounted) {
        setState(() => _transcribeStep = _TranscribeStep.completed);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        final String baseMessage = error
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
        _localError = '${_stepLabel(_transcribeStep)} failed: $baseMessage';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _transcriptionController.isLoading,
      builder: (BuildContext context, bool isLoading, _) {
        return ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: _transcriptionController.lastResult,
          builder: (BuildContext context, Map<String, dynamic>? result, _) {
            final String? controllerError =
                _transcriptionController.errorMessage.value;
            final String? error = _localError ?? controllerError;
            final Map<String, dynamic>? data =
                result?['data'] as Map<String, dynamic>?;
            final Map<String, dynamic>? rich =
                data?['transcription_result'] as Map<String, dynamic>?;
            final Map<String, dynamic> analysis = rich ?? data ?? {};
            final String summary = (analysis['summary'] ?? '').toString();
            final String title = (rich?['title'] ?? 'Lecture transcription')
                .toString();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                const _SectionTitle('Upload Audio'),
                const SizedBox(height: 10),
                _glassCard(
                  child: TextField(
                    controller: _courseCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Course code (optional)',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        data: const _ActionCardData(
                          icon: Icons.audio_file_rounded,
                          title: 'Pick Audio File',
                          subtitle: 'mp3, m4a, wav, aac, ogg',
                          tint: Color(0x1A334155),
                          border: Color(0x22334155),
                          iconColor: Color(0xFF94A3B8),
                        ),
                        onTap: isLoading ? null : _pickAudio,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        data: _ActionCardData(
                          icon: isLoading
                              ? Icons.hourglass_top_rounded
                              : Icons.auto_awesome_rounded,
                          title: isLoading ? 'Working...' : 'Transcribe',
                          subtitle: 'Upload + AI processing',
                          tint: const Color(0x1AF58220),
                          border: const Color(0x33F58220),
                          iconColor: const Color(0xFFF58220),
                        ),
                        onTap: isLoading ? null : _transcribe,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Queue'),
                const SizedBox(height: 10),
                _GlassTile(
                  icon: Icons.queue_music_rounded,
                  title: _selectedAudio?.fileName ?? 'No file selected',
                  subtitle: _selectedAudio == null
                      ? 'Choose a local file or use Record tab output.'
                      : (_selectedAudio!.path == null ||
                            _selectedAudio!.path!.trim().isEmpty)
                      ? 'Queued from recorder. Path resolves when you tap Transcribe.'
                      : _selectedAudio!.path!,
                ),
                if ((_selectedAudio?.duration ?? Duration.zero) >=
                    _segmentedTranscriptionThreshold) ...[
                  const SizedBox(height: 10),
                  const _WarningBanner(
                    message:
                        'Long recording detected. AI will process 30-minute segments and combine the transcript.',
                  ),
                ],
                const SizedBox(height: 10),
                _GlassTile(
                  icon: Icons.cloud_upload_rounded,
                  title: _uploadedPath == null
                      ? 'Not uploaded yet'
                      : 'Uploaded path',
                  subtitle: _uploadedPath ?? 'Waiting for upload...',
                ),
                const SizedBox(height: 10),
                _GlassTile(
                  icon: Icons.badge_rounded,
                  title: _lectureId == null
                      ? 'Lecture ID pending'
                      : 'Lecture row created',
                  subtitle: _lectureId ?? 'Waiting for DB insert...',
                ),
                const SizedBox(height: 10),
                _GlassTile(
                  icon: Icons.route_rounded,
                  title: 'Pipeline step',
                  subtitle: _stepDescription(_transcribeStep),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(
                    message: error,
                    onCopy: () => _copyErrorDetails(error),
                  ),
                ],
                if (result != null && (summary.isNotEmpty || analysis.containsKey('full_transcript'))) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('Result'),
                  const SizedBox(height: 10),
                  _TranscriptionResultCard(
                    title: title,
                    data: analysis,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  bool _isValidCourseCode(String code) {
    final RegExp pattern = RegExp(r'^[A-Z]{3}[0-9]{4}$');
    return pattern.hasMatch(code);
  }

  String _stepLabel(_TranscribeStep step) {
    switch (step) {
      case _TranscribeStep.uploading:
        return 'Upload';
      case _TranscribeStep.creatingLecture:
        return 'Lecture insert';
      case _TranscribeStep.invokingEdge:
        return 'AI processing';
      case _TranscribeStep.completed:
        return 'Completed';
      case _TranscribeStep.idle:
        return 'Transcription';
    }
  }

  String _stepDescription(_TranscribeStep step) {
    switch (step) {
      case _TranscribeStep.uploading:
        return 'Uploading audio to Storage...';
      case _TranscribeStep.creatingLecture:
        return 'Creating lecture row in database...';
      case _TranscribeStep.invokingEdge:
        return 'Calling AI transcription Edge Function...';
      case _TranscribeStep.completed:
        return 'Completed successfully.';
      case _TranscribeStep.idle:
        return 'Waiting for transcription to start.';
    }
  }

  Future<void> _copyErrorDetails(String error) async {
    final String details = [
      'step=${_stepLabel(_transcribeStep)}',
      'lectureId=${_lectureId ?? 'pending'}',
      'uploadedPath=${_uploadedPath ?? 'pending'}',
      'error=$error',
    ].join('\n');

    try {
      await Clipboard.setData(ClipboardData(text: details));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error details copied'),
          backgroundColor: Color(0xFFF58220),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not copy error details.'),
          backgroundColor: Color(0xFFD14343),
        ),
      );
    }
  }
}

class _SelectedAudio {
  const _SelectedAudio({
    required this.fileName,
    this.path,
    this.bytes,
    required this.fileSize,
    required this.duration,
  });

  final String fileName;
  final String? path;
  final Uint8List? bytes;
  final int fileSize;
  final Duration? duration;
}

class _RecordedAudio {
  const _RecordedAudio({
    required this.path,
    required this.bytes,
    required this.dataBytes,
    required this.duration,
    required this.fileName,
    required this.courseCode,
  });

  final String path;
  final int bytes;
  final Uint8List? dataBytes;
  final Duration duration;
  final String fileName;
  final String courseCode;
}

class _FinalizedRecording {
  const _FinalizedRecording({
    required this.path,
    required this.bytes,
    required this.fileName,
  });

  final String path;
  final Uint8List bytes;
  final String fileName;
}

class _ActionCardData {
  const _ActionCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.border,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color border;
  final Color iconColor;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data, required this.onTap});

  final _ActionCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: data.tint,
          border: Border.all(color: data.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(data.icon, color: data.iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.north_east_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(icon, color: const Color(0xFFF58220)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: -0.25,
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.value,
    required this.active,
    required this.onTap,
  });

  final double value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? const Color(0x1AF58220)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: active
                ? const Color(0x55F58220)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          '${value}x',
          style: TextStyle(
            color: active ? const Color(0xFFF58220) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TranscriptionResultCard extends StatefulWidget {
  const _TranscriptionResultCard({required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  State<_TranscriptionResultCard> createState() => _TranscriptionResultCardState();
}

class _TranscriptionResultCardState extends State<_TranscriptionResultCard> {
  bool _isExpanded = false;
  String _selectedFormat = 'Summary';

  final List<String> _formats = [
    'Summary',
    'Key Points',
    'Past Topics',
    'CA/Exam Mentions',
    'Action Items',
    'Full Transcript',
  ];

  String _getContent() {
    final Map<String, dynamic> d = widget.data;
    switch (_selectedFormat) {
      case 'Key Points':
        return d['key_points']?.toString() ?? 'No key points available.';
      case 'Past Topics':
        return d['previous_topics_mentioned']?.toString() ?? 'No past topics mentioned.';
      case 'CA/Exam Mentions':
        return d['assignments_and_assessments']?.toString() ?? 'No CA/Exam mentions.';
      case 'Action Items':
        return d['action_items_for_students']?.toString() ?? 'No action items.';
      case 'Full Transcript':
        return d['full_transcript']?.toString() ?? d['transcript']?.toString() ?? 'Transcript unavailable.';
      case 'Summary':
      default:
        return d['summary']?.toString() ?? 'No summary available.';
    }
  }

  Future<void> _download() async {
    final String content = _getContent();
    final String safeTitle = widget.title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final String fileName = '${safeTitle}_${_selectedFormat.replaceAll(' ', '_')}.txt';

    try {
      final Directory targetDir = await getApplicationDocumentsDirectory();
      final File file = File(p.join(targetDir.path, fileName));
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to app documents: $fileName'),
            backgroundColor: const Color(0xFFF58220),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy Path',
              textColor: Colors.white,
              onPressed: () => Clipboard.setData(ClipboardData(text: file.path)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: const Color(0xFFD14343),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFF58220).withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF58220)),
            ),
            title: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              _isExpanded ? 'Tap to collapse' : 'Tap to view details & download',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ANALYSIS FORMAT',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _formats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final format = _formats[index];
                        final isSelected = _selectedFormat == format;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFormat = format),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? const Color(0xFFF58220)
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFF58220)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              format,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        _selectedFormat.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFF58220),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _download,
                        icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white70),
                        tooltip: 'Download as .txt',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Text(
                      _getContent(),
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'AI-generated content may contain inaccuracies.',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onCopy});

  final String message;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x1AF87171),
        border: Border.all(color: const Color(0x33F87171)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFFECACA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFECACA),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy details'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x1AF59E0B),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFDE68A),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
