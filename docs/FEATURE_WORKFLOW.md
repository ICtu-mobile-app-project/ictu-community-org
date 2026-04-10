# Feature Workflow - Audio/AI Transcription

## End-to-End Flow
1. Flutter records/picks audio file.
2. For recorder flow, stop action finalizes audio bytes and persists a queue-safe local copy before upload.
3. `LectureUploadService.uploadAudioFile/uploadAudioBytes` uploads to bucket `lecture-audio`.
4. `LectureUploadService.createLectureRow` inserts `public.lectures` row with `status=processing`.
5. Flutter calls `transcribe-audio` with `lectureId` + bucket-relative `audioUrl`.
6. Edge function validates object path, downloads object (retry x3), creates signed URL.
7. Edge function submits Gladia job (`/v2/pre-recorded`) and polls job status.
8. Edge function normalizes result into:
   - title
   - summary
   - key_points
   - assignments_and_assessments
   - action_items_for_students
   - previous_topics_mentioned
   - full_transcript
   - translated_full_transcript
   - segments (for audio duration >30 minutes)
   - segmentation metadata
9. Edge function updates `public.lectures` with transcript/summary/result JSON and final status.
10. Flutter updates UI via `TranscriptionController.lastResult`.

## Failure Path
- If any pipeline step fails after lecture creation, row is updated to:
  - `status=failed`
  - `error_message=<reason>`
