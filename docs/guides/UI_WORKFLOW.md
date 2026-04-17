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

<<<<<<< Updated upstream
=======
## Upload Tab
1. User picks a file or uses pre-filled recording from Record tab queue.
2. User optionally sets course code.
3. User taps `Transcribe`.
4. UI queue states:
   - selected file
   - uploaded object path
   - created lecture ID
5. For recordings longer than `30 minutes`, UI shows segmented-processing notice.
6. During processing, button displays `Working...`.
7. On success, UI renders title + summary tile from `transcription_result`.
8. On failure, error banner displays user-friendly message.

---

# UI Workflow - Lecturer Courses Management

## My Courses Screen (`LecturerMyCoursesScreen`)
1. Lecturer opens `Courses` tab from bottom navigation.
2. Screen shows responsive grid:
   - 2 columns on phone
   - 3 columns on tablet
3. Each card displays:
   - course code (bold, orange)
   - title
   - students count
   - lectures count
   - last activity timestamp
4. Lecturer can:
   - search by code/title (debounced)
   - pull to refresh
   - scroll to auto-load next page (20 items/page)
5. FAB `Create New Course` opens `CreateCourseScreen`.

## Create Course Screen (`CreateCourseScreen`)
1. Lecturer fills:
   - course code (auto-uppercase, XXX####)
   - title (required)
   - description (optional)
   - semester dropdown
2. Suggestion list offers ICTU sample courses.
3. On submit, app validates:
   - code format
   - code uniqueness
   - department eligibility
4. On success:
   - success snackbar
   - navigate back and open Course Details.

## Course Details Screen (`LecturerCourseDetailsScreen`)
1. Header shows code/title with edit and delete actions.
2. Stats row shows students, lectures, notes, alerts.
3. Tabs:
   - `Content` (overview of lectures/notes/alerts)
   - `Students` (list, add, remove, CSV batch)
   - `Delegates` (assign, edit permissions, remove)
   - `Settings` (edit/archive/delete)
4. Delete button is disabled when course has content.

## Students Management
1. `Add Students` opens search by email with multi-select.
2. `CSV Upload` parses email list from csv file and enrolls matches.
3. Student rows support remove action (swipe and icon).

## Delegates Management
1. `Assign Delegate` selects an enrolled student.
2. Permissions toggles:
   - can upload notes
   - can edit notes
   - can delete notes
3. Existing delegates can be edited or removed.

## Course Notes Workflow
1. Lecturer opens Course Details -> Content -> `Open Notes`.
2. Notes screen supports search and sort (`Newest`, `Oldest`, `Title A-Z`).
3. Lecturer/delegate (with upload permission) taps `Upload Note`:
   - enters title/description
   - picks PDF/DOC/DOCX file (<=10MB)
   - app uploads to bucket `lecture-notes` path `notes/<uid>/<timestamp>_<file>`
   - app calls `notes-api` action `create_note`.
4. Students open notes list as read-only and use download button.
5. Download button calls `notes-api` action `create_download_url` and opens signed URL.

>>>>>>> Stashed changes
