# alerts-api

Supabase Edge Function for alerts CRUD (lecturer-first rollout).

## Invoke Pattern

```dart
await Supabase.instance.client.functions.invoke('alerts-api', body: {...});
```

## Actions

### `create_alert`
Request fields:
- `title` (string, required)
- `description` (string, required)
- `type` (`assignment|ca|exam|notice`, required)
- `course_code` (string, required)
- `deadline` (ISO datetime, optional)
- `requirements` (string array, optional)

### `list_alerts`
Request fields:
- `course_code` (optional)
- `type` (optional)
- `search` (optional)
- `sort` (`deadline|created`)
- `page`, `limit`

### `get_alert`
Request fields:
- `alert_id` (required)

### `update_alert`
Request fields:
- `alert_id` (required)
- any of `title`, `description`, `deadline`

### `delete_alert`
Request fields:
- `alert_id` (required)

