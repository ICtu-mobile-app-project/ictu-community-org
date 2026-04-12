# transcribe-audio

## Endpoint
- **Function**: `transcribe-audio`
- **Method**: `POST`
- **Invocation**: `SupabaseClient.functions.invoke('transcribe-audio', body: {...})`

## Request Body
```json
{
  "lectureId": "<uuid>",
  "audioUrl": "lectures/<uid>/<timestamp>_lecture.m4a"
}
```

## Validation Rules
- `lectureId` must be a non-empty UUID string.
- `audioUrl` must be a bucket-relative object path.
- Full URLs are rejected.
- Path traversal is rejected (`..`, `\\`).

## Processing Notes
- Edge function submits audio to Gladia `/v2/pre-recorded` and polls completion.
- If detected duration is greater than `30 minutes`, transcription output is partitioned into 30-minute segments and recombined into one final transcript.
- Segment payload includes both `transcript` and `translated_transcript` (when available from provider/fallback).

## Success Response
```json
{
  "success": true,
  "message": "Audio transcribed successfully",
  "data": {
    "transcription": "<full transcript>",
    "summary": "<summary>",
    "transcription_result": {
      "title": "<title>",
      "summary": "<summary>",
      "key_points": [],
      "assignments_and_assessments": {
        "assignments": [],
        "cas": []
      },
      "action_items_for_students": [],
      "previous_topics_mentioned": [],
      "full_transcript": "<combined full transcript>",
      "translated_full_transcript": "<combined translated transcript>",
      "segments": [
        {
          "segment_index": 1,
          "start_seconds": 0,
          "end_seconds": 1800,
          "transcript": "...",
          "translated_transcript": "...",
          "summary": "..."
        }
      ],
      "segmentation": {
        "enabled": true,
        "segment_window_minutes": 30,
        "total_segments": 1,
        "audio_duration_seconds": 1850
      }
    }
  }
}
```

## Error Response
```json
{
  "success": false,
  "error": "<message>"
}
```

- Returns HTTP `400` for validation/runtime errors.
- Returns HTTP `405` for unsupported methods.
