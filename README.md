<p align="center">
   <img src="https://capsule-render.vercel.app/api?type=waving&height=260&color=0:00f3ff,50:ff2f6d,100:08090f&text=ICT%20COMMUNITY&fontColor=ffffff&fontSize=78&fontAlignY=40&animation=twinkling&desc=Student%20infront%20and%20access&descAlignY=64&descSize=19" alt="NEON GRID banner" />

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
  <img src="https://img.shields.io/badge/Language-flutter-7F52FF?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Backend-Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white"/>
  <img src="https://img.shields.io/badge/Database-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
  <img src="https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge"/>
</p>

> A centralized mobile platform for students, lecturers, and staff of **The ICT University (ICTU)** — connecting the campus community through alerts, events, newsletters, and AI-powered lecture materials.

---

## 📋 Table of Contents

- [Problem Statement](#-problem-statement)
- [Our Solution](#-our-solution)
- [Features Overview](#-features-overview)
- [Architecture](#-architecture)
- [Use Case Diagrams](#-use-case-diagrams)
- [Tech Stack](#-tech-stack)
- [Non-Functional Requirements](#-non-functional-requirements)
- [Getting Started](#-getting-started)
- [Contributing](#-contributing)

---

## ❗ Problem Statement

Students and lecturers at The ICT University rely heavily on **fragmented, informal channels** — primarily WhatsApp groups and word-of-mouth — for academic communication and information sharing. This leads to several compounding problems:

- 📢 **Missed Alerts:** Assignment deadlines, CA dates, and exam schedules get buried in noisy group chats, causing students to miss critical academic information.
- 🗓️ **Event Invisibility:** Campus events organized by clubs, the marketing department, and faculty go unnoticed by large portions of the student body.
- 📚 **Inaccessible Learning Materials:** Lecture notes are distributed inconsistently, and there is no standardized way for students to access or revisit lecture content after class.
- 🗞️ **No Targeted News:** Students have no structured way to receive news or resources relevant to their faculty or field of study.
- 🔗 **Disconnected Community:** Without a unified platform, the campus community lacks a shared digital space that fosters collaboration and belonging.

---

## 💡 Our Solution

**The ICTU Community** is a native Android mobile application that acts as a **single, unified hub** for all academic and campus life activities at The ICT University. It replaces scattered informal channels with a purpose-built platform that serves students, lecturers, and authorized staff.

Key pillars of the solution:

- **Role-based access** — tailored experiences for Students, Lecturers, and Authorized users (delegates, club captains, ICTO staff).
- **Real-time push notifications** — ensures no alert, event, or news update is ever missed.
- **AI-powered lecture summaries** — lecturers upload audio recordings and an integrated AI service automatically transcribes and summarizes them, making review effortless for students.
- **Faculty-targeted newsletter** — news and resources are filtered to match each student's faculty, reducing noise and improving relevance.
- **Secure, institution-verified authentication** — all accounts are tied to official university email addresses.

---

## ✨ Features Overview

### 🔐 Authentication
| Feature | Description |
|---|---|
| Student & Lecturer Login | Secure sign-in using official university email and password |
| New Account Registration | Self-service registration for newly admitted students and new faculty |
| Password Recovery | Email-based secure password reset flow |

### 🔔 Alerts & Notifications
| Feature | Description |
|---|---|
| Create Academic Alerts | Lecturers publish assignment, CA, and exam notifications |
| Real-time Push Notifications | Students receive instant alerts as soon as they are published |
| Alert Details | Full instructions, deadlines, and course information per alert |

### 📰 Feeds & Events
| Feature | Description |
|---|---|
| Event Feed | Chronological, university-wide feed of announcements and events |
| Rich Event Content | Events support text, images, videos, and external links |
| Category Filtering | Students filter events by type (academic, social, sports, etc.) |
| Add to Calendar | One-tap export of event details to the device calendar |

### 🗞️ Newsletter
| Feature | Description |
|---|---|
| Faculty-targeted News | Articles are surfaced based on the student's faculty |
| Content Variety | Covers tech industry trends, free resources, and faculty news |
| Article Sharing | Students share articles via social media or messaging apps |

### 📚 Lecture Materials
| Feature | Description |
|---|---|
| Upload & Manage Notes | Lecturers upload PDFs and documents for each course |
| AI Audio Summarization | Uploaded lecture recordings are transcribed and summarized by AI |
| Summary Review & Publish | Lecturers review AI summaries before releasing them to students |
| Offline Access | Students download notes for offline reading |

### 👥 Course Delegate Management
| Feature | Description |
|---|---|
| Assign Delegates | Lecturers designate a student as a course delegate |
| Delegate Permissions | Delegates can edit notes and publish materials with lecturer approval |
| Revoke Access | Lecturers can remove delegate privileges at any time |

---

## 🏗️ Architecture

The application follows a **client-server architecture** with a clear separation between the mobile frontend, a RESTful backend API, and managed cloud services.

```mermaid
graph TB
    subgraph Mobile["📱 Android Client (Kotlin)"]
        UI[UI Layer]
        VM[ViewModel / State]
        Repo[Repository]
    end

    subgraph Backend["⚙️ Backend (Node.js)"]
        API[REST API - HTTPS]
        BL[Business Logic]
        NotiSvc[Push Notification Service]
    end

    subgraph Cloud["☁️ Cloud Services"]
        SB_Auth[Supabase Auth]
        SB_DB[(Supabase Database)]
        SB_Store[Supabase Storage]
        AI[AI Service\nWhisper / AssemblyAI]
        FCM[Firebase Cloud Messaging]
    end

    UI --> VM --> Repo
    Repo -->|HTTPS / REST| API
    API --> BL
    BL --> SB_Auth
    BL --> SB_DB
    BL --> SB_Store
    BL -->|Upload audio| AI
    AI -->|Transcript + Summary| SB_DB
    BL --> NotiSvc
    NotiSvc -->|Push| FCM
    FCM -->|Notification| Mobile
```

### Data Flow — AI Lecture Summarization

```mermaid
sequenceDiagram
    participant L as 👨‍🏫 Lecturer
    participant App as 📱 ICTU App
    participant API as ⚙️ Node.js API
    participant AI as 🤖 AI Service
    participant DB as 🗄️ Supabase
    participant S as 👨‍🎓 Student

    L->>App: Upload lecture audio file
    App->>API: POST /lectures/audio
    API->>AI: Send audio for transcription
    AI-->>API: Return transcript + summary
    API->>DB: Save summary & status
    API-->>App: Summarization complete
    App-->>L: Notify: review your summary
    L->>App: Review & approve summary
    App->>API: PATCH /lectures/publish
    API->>DB: Mark as published
    S->>App: Open lecture notes
    App->>API: GET /lectures/:courseId
    API->>DB: Fetch notes + summary
    DB-->>API: Return data
    API-->>App: Lecture material
    App-->>S: Read notes + play AI summary
```

---

## 📊 Use Case Diagrams

### Authentication Module

```mermaid
graph LR
    Student(["👨‍🎓 Student"])
    Lecturer(["👨‍🏫 Lecturer"])

    subgraph Auth["Authentication"]
        UC1([Login])
        UC2([Register Account])
        UC3([Reset Password])
    end

    Student --> UC1
    Student --> UC2
    Student --> UC3
    Lecturer --> UC1
    Lecturer --> UC2
    Lecturer --> UC3
```

### Student Module

```mermaid
graph LR
    Student(["👨‍🎓 Student"])

    subgraph SM["Student Features"]
        UC1([View Dashboard])
        UC2([Browse Alerts])
        UC3([View Alert Details])
        UC4([Browse Events Feed])
        UC5([Filter Events])
        UC6([Add Event to Calendar])
        UC7([Read Newsletter])
        UC8([Share Article])
        UC9([Browse Lecture Notes])
        UC10([Listen to AI Summary])
        UC11([Download Notes])
    end

    Student --> UC1
    Student --> UC2
    UC2 --> UC3
    Student --> UC4
    UC4 --> UC5
    UC4 --> UC6
    Student --> UC7
    UC7 --> UC8
    Student --> UC9
    UC9 --> UC10
    UC9 --> UC11
```

### Lecturer Module

```mermaid
graph LR
    Lecturer(["👨‍🏫 Lecturer"])

    subgraph LM["Lecturer Features"]
        UC1([View Dashboard])
        UC2([Create Alert])
        UC3([Edit Alert])
        UC4([Upload Lecture Notes])
        UC5([Edit / Delete Notes])
        UC6([Upload Audio Recording])
        UC7([Review AI Summary])
        UC8([Publish Summary])
        UC9([Assign Delegate])
        UC10([Revoke Delegate])
        UC11([View Delegate Permissions])
    end

    Lecturer --> UC1
    Lecturer --> UC2
    Lecturer --> UC3
    Lecturer --> UC4
    UC4 --> UC5
    Lecturer --> UC6
    UC6 --> UC7
    UC7 --> UC8
    Lecturer --> UC9
    Lecturer --> UC10
    Lecturer --> UC11
```

### Authorized Users (Delegates / Staff)

```mermaid
graph LR
    AuthUser(["🧑‍💼 Authorized User\n(Delegate / Club Captain / Staff)"])

    subgraph AU["Authorized User Features"]
        UC1([Create & Publish Events])
        UC2([Manage Event Content])
        UC3([Edit Course Notes])
        UC4([Publish Course Materials])
    end

    AuthUser --> UC1
    UC1 --> UC2
    AuthUser --> UC3
    AuthUser --> UC4
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Mobile** | Kotlin (Android) | Native Android application |
| **Backend** | Node.js | RESTful API & business logic |
| **Database** | Supabase (PostgreSQL) | Persistent data storage |
| **Auth** | Supabase Auth | Email-based user authentication |
| **File Storage** | Supabase Storage | Lecture notes & audio files |
| **AI Service** | OpenAI Whisper / AssemblyAI | Audio transcription & summarization |
| **Push Notifications** | Firebase Cloud Messaging | Real-time alerts delivery |
| **API Communication** | HTTPS / REST | Encrypted client-server communication |

---

## ⚡ Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | UI transitions and data loading < 2 seconds |
| **Scalability** | Backend handles high concurrency without performance degradation |
| **Security** | All traffic encrypted over HTTPS; passwords hashed & salted |
| **Reliability** | High uptime with resilient backend infrastructure |
| **Usability** | Consistent with Android Material Design guidelines |
| **Maintainability** | Well-structured, documented, and modular codebase |

---

## 🚀 Getting Started

### Prerequisites

- Android Studio Hedgehog or newer
- Node.js v18+
- A Supabase project (with Auth and Storage enabled)
- Firebase project (for push notifications)

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/ictu-community/backend.git
cd backend

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Fill in your Supabase URL, keys, AI service key, and FCM credentials

# Start the server
npm run dev
```

### Mobile Setup

```bash
# Clone the mobile repository
git clone https://github.com/ictu-community/android.git

# Open in Android Studio
# Sync Gradle dependencies
# Update local.properties with your backend API base URL

# Run on emulator or physical device
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add: your feature description'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

Please ensure your code follows the project's style guide and all tests pass before submitting.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<p align="center">Made with ❤️ for The ICT University Community</p>
