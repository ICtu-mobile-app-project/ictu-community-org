# Notes API Contract

## Supabase Edge Function
- Function name: `notes-api`
- Method: `POST`
- Payload shape:
```json
{
  "action": "list_notes",
  "...actionFields": "..."
}
```

## Actions
- `create_note`
  - fields: `courseId`, `title`, `description`, `contentUrl`, `fileName`, `fileSizeBytes`
- `list_notes`
  - fields: `courseId`, `search` (optional), `sort` (`newest|oldest|title`)
- `get_note_details`
  - fields: `noteId`
- `update_note_title`
  - fields: `noteId`, `title`
- `delete_note`
  - fields: `noteId`
- `create_download_url`
  - fields: `noteId`

## Authorization Model
- `create_note`: lecturer owner or delegate with `can_upload_notes`
- `list/get/download`: lecturer owner, enrolled students, or delegates
- `update_note_title`: lecturer owner or delegate with `can_edit_notes`
- `delete_note`: lecturer owner or delegate with `can_delete_notes`

