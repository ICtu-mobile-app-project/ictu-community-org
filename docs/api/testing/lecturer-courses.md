# Lecturer Courses - Test Log

## Scope
- Lecturer My Courses grid and pagination
- Create course validation and success flow
- Course details tabs (Content, Students, Delegates, Settings)
- Students add/remove and CSV enrollment path
- Delegates assign/edit/remove

## Manual Verification Notes
1. Open app as lecturer and navigate to `Courses` tab.
2. Confirm course cards show code/title/stats/last activity.
3. Pull-to-refresh updates list.
4. Search returns filtered results after debounce.
5. Create course with invalid code -> validation message appears.
6. Create course with valid code -> success snackbar and open details screen.
7. Try deleting a course with content -> blocked with message.
8. Add students through dialog search + multi-select.
9. Remove student by swipe or remove icon.
10. Assign delegate and toggle permissions.

## Current Implementation Notes
- Uses in-memory repository for local/demo mode.
- Repository interface is ready to swap with Supabase-backed implementation.

