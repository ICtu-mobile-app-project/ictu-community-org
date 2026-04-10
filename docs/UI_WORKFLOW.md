# UI Workflow - Audio/AI Transcription

## Screen
- `AudioAiTranscriptionScreen`
- Tabs: `Record` and `Upload`

## Record Tab
1. User taps record button.
2. App requests microphone permission.
3. Recording starts in `.m4a` at 16kHz, mono, 64kbps.
4. UI shows live timer (`HH:MM:SS`) + estimated file size.
5. Max duration is `3 hours`:
   - warning banner appears near `2h45m`
   - auto-stop happens at `3h`
6. User can pause/resume, stop, cancel.
7. On stop, app finalizes audio bytes, writes a durable queue copy in app storage, and pre-fills Upload tab.
8. UI shows playback + speed controls.

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
