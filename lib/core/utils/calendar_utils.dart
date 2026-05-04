import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class CalendarUtils {
  static Future<void> addToCalendar({
    required String title,
    required String description,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    // Basic ISO8601 formatting for Google Calendar (YYYYMMDDTHHMMSSZ)
    String formatDateTime(DateTime dt) {
      return dt.toUtc().toIso8601String()
          .replaceAll('-', '')
          .replaceAll(':', '')
          .split('.')
          .first + 'Z';
    }

    final start = formatDateTime(startTime);
    final end = formatDateTime(endTime ?? startTime.add(const Duration(hours: 1)));
    
    final String queryParams = 'action=TEMPLATE'
        '&text=${Uri.encodeComponent(title)}'
        '&details=${Uri.encodeComponent(description)}'
        '&dates=$start/$end';

    if (Platform.isAndroid) {
      // Construction of an Android Intent URL that targets the Google Calendar package specifically.
      // This is the most reliable way to bypass the browser on Android.
      final String intentUrl = 'intent://calendar.google.com/calendar/render'
          '?$queryParams'
          '#Intent;scheme=https;package=com.google.android.calendar;end';
      
      try {
        final Uri intentUri = Uri.parse(intentUrl);
        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Native Intent failed: $e');
      }
    }

    // Fallback URL (Works on iOS if Google Calendar is installed, or defaults to browser)
    // Using calendar.google.com/calendar/r/eventedit is sometimes better for triggering the app
    final Uri fallbackUri = Uri.parse('https://calendar.google.com/calendar/r/eventedit?$queryParams');
    
    try {
      await launchUrl(
        fallbackUri, 
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (e) {
      // Final fallback to standard web
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }
}
