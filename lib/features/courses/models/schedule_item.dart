class ScheduleItem {
  final String id;
  final String courseCode;
  final String courseName;
  final String? lecturer;
  final String? hall;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? groupName;
  final bool isEnrolled;

  ScheduleItem({
    required this.id,
    required this.courseCode,
    required this.courseName,
    this.lecturer,
    this.hall,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.groupName,
    this.isEnrolled = false,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json, {bool isEnrolled = false}) {
    return ScheduleItem(
      id: json['id'],
      courseCode: json['course_code'],
      courseName: json['course_name'],
      lecturer: json['lecturer'],
      hall: json['hall'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      groupName: json['group_name'],
      isEnrolled: isEnrolled,
    );
  }

  String get timeRange => '${_formatTime(startTime)} - ${_formatTime(endTime)}';

  String _formatTime(String time) {
    // time is usually HH:mm:ss
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0]}:${parts[1]}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_code': courseCode,
      'course_name': courseName,
      'lecturer': lecturer,
      'hall': hall,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'group_name': groupName,
    };
  }
}
