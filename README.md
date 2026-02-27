# ICTU Community

ICTU Community is a university-ready mobile application built with Kotlin for the frontend, Node.js for the backend/API, and Supabase as the database. The app is designed to serve four types of users: **students**, **teachers**, **staff**, and **administrators**. It facilitates communication, information sharing, and academic management within the university.

##  User Roles & Features

### Students
- View feeds and news.
- Read newsletters related to their field of study (e.g., coding, marketing).
- Access class information and recorded lectures.
- Receive alerts about exams, continuous assessment (CA), and resits.
- Get notifications about assignments and experimental registration features.

### Teachers
- Post course materials and send assignments.
- Read feeds and news.
- Assign class delegates from the student body.

### Staff
(Features to be implemented easy to develop)
- Manage timetables and classroom allocations.
- Handle student administrative requests (e.g., transcript requests, registration inquiries).
- Publish campus-wide announcements.

### Administrators
(Features to be implemented easy to develop)
- Manage user accounts and roles (create, read, update, delete).
- Configure system-wide settings (e.g., semester dates, exam policies).
- Oversee content moderation on feeds and news.

##  Architecture Overview

The recommended architecture follows a clean separation between frontend, backend, and database layers:

1. **Frontend (Kotlin/Android)**
   - MVVM (Model-View-ViewModel) pattern.
   - Retrofit for API communication.
   - Jetpack components for UI and state management.

2. **Backend (Node.js/Express)**
   - RESTful API with endpoints for authentication, feeds, classes, assignments, notifications, etc.
   - JWT for user authentication and role-based access control.
   - Services and controllers organized by domain (users, courses, notifications).

3. **Database (Supabase/PostgreSQL)**
   - Tables: users, roles, feeds, news, newsletters, classes, recordings, assignments, notifications.
   - Policies for row-level security to enforce access control.

Dependencies are managed via Gradle (frontend) and npm/yarn (backend).

##  Functional Requirements

1. User authentication and role management.
2. CRUD operations for feeds, news, assignments, classes.
3. Notification system for alerts (exams, assignments, registrations).
4. File upload for course materials and recordings.
5. Role-based access to different features.
6. Search and filter capabilities within feeds and news.

##  Non-Functional Requirements

- **Performance:** Fast load times on mobile devices; API responses under 200ms.
- **Scalability:** Support thousands of concurrent users; database optimized with indexes.
- **Security:** Use HTTPS, JWT for auth, RLS policies in Supabase.
- **Usability:** Intuitive UI with accessibility features.
- **Maintainability:** Modular codebase, clear separation of concerns, use of design patterns.

##  Design Patterns & Best Practices

- MVVM on the frontend with LiveData/StateFlow.
- Repository pattern to abstract data sources.
- Observer pattern for notification subscriptions.
- Singleton pattern for shared services (e.g., API client).
- Dependency Injection using Hilt or Koin.

##  Suggested User Stories

1. **As a student**, I want to log in and see the latest news so I stay informed.
2. **As a student**, I want to register for classes and get notified about assignments.
3. **As a teacher**, I want to upload course materials so students can access them.
4. **As a teacher**, I want to assign a class representative.
5. **As staff**, I want to publish an announcement to the entire university.
6. **As an administrator**, I want to deactivate a user account.

##  UML & Diagrams

- **Use case diagrams** for the four user types.
- **Class diagrams** showing entities like `User`, `NewsItem`, `Assignment`, `Notification`.
- **Sequence diagrams** for login flow, posting a feed, sending a notification.

*(Diagrams can be drawn with tools like draw.io or PlantUML and linked here.)*

---

##  Project Setup

1. Clone repository.
2. Frontend: open in Android Studio, sync Gradle.
3. Backend: `npm install`, configure `.env` with Supabase URL/keys.
4. Run Supabase locally or use hosted instance.

---

##  Presentation Material

A LaTeX file `ICTU_Community.tex` contains extended documentation, requirements, diagrams, and notes prepared for generating a PDF or DOC for presentations.

---

##  Future Enhancements

- Real-time chat between users.
- Analytics dashboard for admin and teachers.
- Offline caching of feeds and classes.
- Localization and multi-language support.

---

**ICTU Community** aims to create a unified, responsive platform for university stakeholders to interact and manage academic life effectively.
