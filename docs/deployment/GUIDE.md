# ICTU Community App - Deployment & Offline Guide

This document details the implementation of offline capabilities and the process for distributing app updates to users.

---

## 📶 1. Offline Capabilities Implementation

We have implemented a robust offline-first strategy to ensure students and lecturers can access critical information (courses, notes, alerts) even with unstable campus Wi-Fi.

### Key Components:
1.  **Local Persistence (Hive)**: 
    *   Initializes in `main.dart` using `Hive.initFlutter()`.
    *   Uses specialized boxes (`courses_cache`, `notes_cache`, `alerts_cache`) to store JSON data locally.
2.  **Connectivity Monitoring**:
    *   `ConnectivityService` (in `lib/core/services/`) uses the `connectivity_plus` package to detect network changes.
    *   The app listens to this stream to toggle between "Live" and "Cache" modes.
3.  **Offline Service**:
    *   `OfflineService` acts as the manager for reading and writing to the local Hive database.
4.  **Repository Logic (The "Hybrid" Pattern)**:
    *   Repositories (`StudentCoursesRepository`, `NotesService`, etc.) check for internet before every request.
    *   **Online**: Fetch from Supabase -> Update Local Cache -> Return Data.
    *   **Offline**: Fetch from Local Cache -> Return Data.
    *   **Error Fallback**: If an online request fails (timeout/server error), the app automatically falls back to cached data.

### UI Indicators:
*   An **Offline Badge** (Orange Chip) appears on the "My Courses" screens when the device loses connection.
*   Data automatically refreshes the moment the user comes back online.

---

## 🚀 2. App Updates (Firebase App Distribution)

We use **Firebase App Distribution** to share new versions of the app with testers and students without going through the Play Store.

### Prerequisites (Do these once):
1.  **Install Firebase CLI**:
    ```bash
    npm install -g firebase-tools
    ```
2.  **Login to your Google Account**:
    ```bash
    firebase login
    ```
3.  **Initialize App Distribution**:
    Run this in the project root and select your Firebase project:
    ```bash
    firebase init appdistribution
    ```

### How to Send an Update:
We have provided a automation script `distribute.ps1` to make this a one-step process.

**Command:**
```powershell
./distribute.ps1 -appId "YOUR_FIREBASE_APP_ID" -notes "Added offline mode and performance fixes"
```

**What the script does:**
1.  Cleans the project and fetches dependencies.
2.  Builds a production-ready Release APK.
3.  Uploads the APK to Firebase.
4.  Notifies all registered testers (Students/Staff) via email that a new version is ready for download.

---

## 🛠 3. Project Configuration Status

*   **Offline Logic**: ✅ Fully Configured and Integrated into the code.
*   **Distribution Script**: ✅ Created (`distribute.ps1`).
*   **Firebase Tools**: ⚠️ **User Action Required**. 
    *   The *logic* is ready, but you must manually run `firebase login` on your machine to authorize the upload.
    *   You must provide your **Firebase App ID** (found in Project Settings in the Firebase Console) when running the distribution script.
