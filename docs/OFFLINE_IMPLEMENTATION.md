# Detailed Offline Architecture

This document provides a deep-dive into how the ICTU Community App maintains functionality during network outages.

---

## 🏗️ 1. Persistence Layer: Hive

We chose **Hive** as our local database because it is a lightweight and blazing-fast key-value store written in pure Dart, making it ideal for mobile performance without the overhead of SQLite.

### Box Configuration
We use separate "Boxes" (similar to tables) for different data domains to prevent corruption and improve lookup speeds:
1.  **`courses_cache`**: Stores `List<Map<String, dynamic>>` representing the user's enrolled or assigned courses.
2.  **`notes_cache`**: Stores metadata for lecture materials. Keys are prefixed with `notes_{courseId}`.
3.  **`alerts_cache`**: Stores announcements and deadlines.

### Data Serialization
Since Hive stores raw Dart objects, we use `toJson()` and `fromJson()` patterns to convert our Class models (e.g., `CourseNote`, `AlertItem`) into storable Maps.

---

## 📡 2. Connectivity Management

The `ConnectivityService` (lib/core/services/connectivity_service.dart) acts as the source of truth for the app's online state.

*   **Technology**: Uses the `connectivity_plus` package.
*   **Real-time Streaming**: It exposes a `Stream<bool> get onConnectivityChanged` which screens listen to.
*   **Active Probing**: Before critical write operations (like creating a course), the app calls `isOnline()` which performs an active network check to ensure the connection isn't just "connected to Wi-Fi without internet."

---

## 🔄 3. Synchronization Patterns

We implement a **Cache-Aside** strategy.

### Read Flow (GET Requests)
When a user opens their course list:
1.  **UI Request**: The Controller calls `repository.getMyCourses()`.
2.  **Network Check**: The Repository asks `ConnectivityService`.
3.  **Branch A (Online)**: 
    *   Fetch from Supabase Edge Function.
    *   On success, call `OfflineService.cacheCourses(...)` to update the local disk.
    *   Return fresh data to UI.
4.  **Branch B (Offline/Error)**:
    *   Call `OfflineService.getCachedCourses()`.
    *   If data exists, return to UI with an "Offline" flag.
    *   If no cache exists, throw a specific `OfflineException` to show the "No Internet" empty state.

### Write Flow (POST Requests)
*   **Strict Online Policy**: Operations that modify the shared database (Creating Alerts, Uploading Notes, Transcription) are **blocked** in offline mode.
*   **User Feedback**: Buttons are disabled or show a "Network Required" tooltip when the app detects no connection.

---

## 📂 4. File Caching (PDFs and Audio)

While text data is stored in Hive, large files (PDFs) are managed via the `path_provider` and `dio` libraries.

1.  **Check Local**: Before opening a PDF, the app checks the `getApplicationDocumentsDirectory()` for a file named `{note_id}.pdf`.
2.  **Download & Save**: If missing, it downloads the file once and saves it permanently.
3.  **Offline Open**: Subsequent clicks open the local file instantly without network usage.
