# UI Workflow - Detailed Implementation

This document describes the step-by-step logic, state management, and user interaction flows for the core features of the ICTU Community App.

---

## 🎙️ Audio/AI Transcription Flow

The transcription feature allows lecturers to record or upload lecture audio, which is then processed by a Supabase Edge Function using the Gladia AI engine to generate transcripts, summaries, and action items.

### 1. Recording Phase (`AudioAiTranscriptionScreen` - Record Tab)
*   **Initialization**: The app checks for microphone permissions using `permission_handler`. If denied, it shows a rationale dialog.
*   **Recording Engine**: Uses the `record` package. 
    *   **Format**: `.m4a` (AAC) for high quality at low bitrates.
    *   **Settings**: 16kHz sample rate, Mono, 64kbps. This ensures a 1-hour lecture is ~30MB.
*   **Live UI State**:
    *   A `Stopwatch` tracks duration. 
    *   `ValueNotifier` updates the UI every 100ms with a wave visualizer (simulated or real amplitude).
    *   **Safety Limits**: A warning appears at 2h 45m. At 3h, the recording auto-stops to prevent storage overflow.
*   **Finalization**: On "Stop", the `AudioRecorder` flushes bytes to a temporary file. A "Durable Queue" copy is saved in the app's internal cache to prevent data loss if the app crashes before upload.

### 2. Upload & Processing Phase (Upload Tab)
*   **File Selection**: Supports the recorded file or external files via `file_picker`.
*   **Course Context**: The lecturer selects a course from a dropdown (populated by `NotesService.getLecturerCourses()`).
*   **Multi-Stage Upload**:
    1.  **Storage**: The file is uploaded to the `lecture-audio` bucket. We use a path format: `lectures/<user_id>/<timestamp>_<filename>`.
    2.  **Database Entry**: A record is created in the `lectures` table with `status = 'processing'`.
    3.  **Edge Function Trigger**: The app calls the `transcribe-audio` function.
*   **Wait State**: The UI shows a "Processing..." state with a rotating progress indicator. For audio >30 mins, a "Large file: Segmenting..." notice is shown.
*   **Result Display**: Once complete, the controller parses the complex JSON result and renders:
    *   **Title & Summary Card**: High-level overview.
    *   **Key Points**: Bulleted list.
    *   **Action Items**: Specific tasks for students.
    *   **Full Transcript**: Expandable section with search capability.

---

## 🔔 Alerts & Notifications Flow (Lecturer)

### 1. Alert Management (`LecturerAlertsListScreen`)
*   **Data Fetching**: Uses `AlertsService.listLecturerAlerts`. 
    *   **Caching**: If offline, Hive provides the last synced alerts. 
    *   **Filtering**: Clientside filtering via `ValueNotifier` for immediate UI response across Types (Assignments, CAs, Exams).
*   **Sorting**: Supports sorting by `Deadline` (most urgent first) or `Created Date`.

### 2. Creation Workflow (`CreateAlertScreen`)
*   **Form Validation**: 
    *   Title (min 5 chars).
    *   Deadline: Must be in the future.
    *   Requirements: A dynamic list where users can add/remove "Requirement Chips".
*   **Submission**: Calls `alerts-api` with action `create_alert`.
*   **User Feedback**: Uses a `SnackBar` with a "Success" theme (Green/Glass) and triggers an immediate list refresh in the parent screen.

### 3. Detail View (`AlertDetailsScreen`)
*   **Real-time Countdown**: A timer calculates the time remaining until the deadline and updates every minute.
*   **Dynamic Styling**: If the deadline is < 24 hours away, the badge turns red/pulsing. If > 3 days, it remains green/neutral.

---

## 📚 Course Materials (Notes)

### 1. Student View (`EnrolledCoursesScreen` -> `CourseNotesListScreen`)
*   **Offline Access**: Students can see the list of all available notes even without internet.
*   **Download Logic**: When a student taps a note, the app checks if the file exists in the local cache. If not, it generates a signed URL via `NotesService.createDownloadUrl` and downloads it using `dio`.
*   **PDF Viewing**: Integrated `syncfusion_flutter_pdfviewer` for an in-app reading experience without needing external apps.

---

## 🔑 Authentication Workflow
*   **Domain Lock**: The signup screen enforces `@ictuniversity.edu.cm` or `@student.ictu-university.cm` emails.
*   **Session Persistence**: On app restart, `SplashScreen` checks `Supabase.instance.client.auth.currentSession`. If valid, it skips login. If invalid or expired, it routes to `WelcomeScreen`.

