# Lecturer Courses API Contract

## Supabase Edge Function
- Function name: `courses-api`
- Method: `POST`
- Transport payload format:
```json
{
  "action": "create_course",
  "...actionFields": "..."
}
```

## Action Mapping
- `create_course` -> `POST /api/courses`
- `list_my_courses` -> `GET /api/courses/my-courses`
- `get_course_details` -> `GET /api/courses/:id`
- `update_course` -> `PUT /api/courses/:id`
- `delete_course` -> `DELETE /api/courses/:id`
- `list_students` -> `GET /api/courses/:id/students`
- `search_students` -> `GET /api/students?email=<query>`
- `add_students` -> `POST /api/courses/:id/students`
- `remove_student` -> `DELETE /api/courses/:id/students/:studentId`
- `assign_delegate` -> `POST /api/courses/:id/delegates`
- `list_delegates` -> `GET /api/courses/:id/delegates`
- `update_delegate` -> `PUT /api/courses/:id/delegates/:delegateId`
- `remove_delegate` -> `DELETE /api/courses/:id/delegates/:delegateId`

## Create Course
- `POST /api/courses`
- Body:
```json
{
  "course_code": "SEN3141",
  "title": "Software Design and Modelling",
  "description": "Optional",
  "semester": "Fall 2025"
}
```

## Get Lecturer Courses
- `GET /api/courses/my-courses?page=0&limit=20&search=SEN`

## Get Course Details
- `GET /api/courses/:id`

## Update Course
- `PUT /api/courses/:id`
- Body:
```json
{
  "title": "Updated title",
  "description": "Updated description",
  "semester": "Spring 2026",
  "archived": false
}
```

## Delete Course
- `DELETE /api/courses/:id`
- Constraint: reject when course has lectures/notes/alerts.

## Add Students
- `POST /api/courses/:id/students`
- Body:
```json
{
  "student_ids": ["stu-1", "stu-2"]
}
```

## Remove Student
- `DELETE /api/courses/:id/students/:studentId`

## Assign Delegate
- `POST /api/courses/:id/delegates`
- Body:
```json
{
  "student_id": "stu-1",
  "permissions": {
    "can_upload_notes": true,
    "can_edit_notes": false,
    "can_delete_notes": false
  }
}
```

## Get Delegates
- `GET /api/courses/:id/delegates`

