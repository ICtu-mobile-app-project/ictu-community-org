# Feature Workflow - Technical Deep Dive

This document outlines the end-to-end technical processes for the application's core systems, from user action to backend persistence.

---

## 🎙️ Audio Transcription Pipeline

The transcription feature is a multi-stage distributed process involving the Flutter client, Supabase Storage, Edge Functions, and the Gladia AI API.

### 1. Source Capture & Buffering
*   **User Action**: Lecturer initiates recording.
*   **Local State**: The `TranscriptionController` manages a `RecordingState` enum (`idle`, `recording`, `paused`, `uploading`, `processing`).
*   **Safety Backup**: As the recording progresses, a periodic background task (every 5 mins) flushes the current audio buffer to a recovery file. This ensures that even if the phone dies, the lecture is not lost.

### 2. The Upload Handshake
*   **Step A (Storage)**: `LectureUploadService` performs a binary upload to the `lecture-audio` bucket.
*   **Step B (Metadata)**: After a successful 200 OK from Storage, the client inserts a row into the `lectures` table.
*   **Database Constraints**: The `lectures` table has a Foreign Key to `courses.id`. The row is initialized with `status = 'processing'`.

### 3. Edge Function Execution (`transcribe-audio`)
*   **Normalization**: The function first checks the audio file's metadata.
*   **AI Submission**: It calls the Gladia `/v2/pre-recorded` endpoint.
*   **The 30-Minute Boundary**:
    *   If duration < 30m: Direct processing.
    *   If duration > 30m: The function uses Gladia's segmentation or manual partitioning logic to ensure high accuracy without timeout.
*   **LLM Enrichment**: After raw transcription, the text is passed to an LLM (Gpt-4o or similar) to generate:
    *   `action_items_for_students`
    *   `key_points`
    *   `summary`
*   **Completion**: The function performs a final `UPDATE` on the `lectures` row, setting `status = 'completed'` and populating the `result_json` column.

---

## 📶 Offline Data Synchronization

To handle poor connectivity, the app implements a **Write-Through/Read-Around** caching strategy.

### 1. Reading Data (The Cache-First Approach)
*   **Logic**: 
    1.  Request data from `OfflineService` (Hive).
    2.  Simultaneously, trigger a network request if `isOnline == true`.
    3.  If network succeeds, update Hive and notify listeners (UI updates).
    4.  If network fails, the UI remains on the cached data with an "Offline" warning.

### 2. Data Structures
*   **Courses**: Stored as a `List<Map>` in `courses_cache`.
*   **Notes**: Stored per-course ID to optimize lookups.
*   **Alerts**: Stored globally but filtered by the controller.

---

## 🔔 Alert Lifecycle

### 1. Creation & Validation
*   Lecturers create alerts with strict type-checking (`assignment`, `ca`, `exam`, `notice`).
*   The `alerts-api` function enforces that only the lecturer assigned to a course can create alerts for it.

### 2. Real-time Delivery
*   **Database Webhooks**: Supabase is configured with a webhook on the `alerts` table.
*   **Trigger**: On `INSERT`, the webhook notifies the `push-notification-service` (Future Extension).
*   **Client Refresh**: Flutter clients use a `RefreshIndicator` or manual trigger to pull the latest alerts into their local Hive store.

---

## 📂 Materials Management (Notes)

### 1. Multi-part Upload
*   Large PDF/Doc files are uploaded via a chunked retry mechanism in `NotesService`.
*   If a chunk fails, the app retries up to 3 times before prompting the user.
*   Once all chunks are merged in Supabase Storage, the `notes-api` is called to register the file in the database.

### 2. Intelligent Download
*   When a student opens a note, the app calculates the MD5 hash of the local file (if it exists) and compares it with the server's version. 
*   It only re-downloads if the lecturer has updated the file.

<<<<<<< Updated upstream
=======
## Failure Path
- If any pipeline step fails after lecture creation, row is updated to:
  - `status=failed`
  - `error_message=<reason>`

---

# Feature Workflow - Lecturer Courses Management

## End-to-End Flow
1. Lecturer opens `My Courses`.
2. `LecturerCoursesController` fetches paginated data (`limit=20`) via repository.
3. Search input is debounced and re-queries repository.
4. Lecturer creates new course:
   - validates course code format (`^[A-Z]{3}\d{4}$`)
   - checks uniqueness
   - verifies department eligibility
5. Repository persists course metadata and returns created course.
6. Course details screen loads tabs in parallel concerns:
   - content metrics
   - enrolled students
   - delegates
   - course settings
7. Students tab supports:
   - search by email and multi-enroll
   - remove enrollment
   - CSV batch enrollment
8. Delegates tab supports:
   - assign from enrolled students
   - permission updates
   - delegate removal
9. Delete course is blocked if course has content (lectures/notes/alerts).

## Error Handling Path
- Validation errors are shown inline/snackbar in UI.
- Repository exceptions are surfaced as user-friendly messages.
- Unsafe destructive actions require confirmation dialogs.

## Course Notes Feature Flow
1. Lecturer/delegate uploads note file to private Storage bucket `lecture-notes`.
2. Flutter calls `notes-api` with `create_note` including metadata + storage path.
3. Edge function validates role/course membership/permissions:
   - lecturer owner OR delegate with `can_upload_notes`.
4. Edge function writes to `public.lecture_notes`.
5. Both students and lecturers call `list_notes` to view notes for enrolled courses.
6. Download uses `create_download_url` signed URL flow (bucket remains private).
7. Edit/delete note actions are permission-gated by delegate flags and lecturer ownership.

>>>>>>> Stashed changes
