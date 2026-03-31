# ICTU Community - Software Requirements Specification (SRS)

**Version:** 1.0.0  
**Last Updated:** March 31, 2026  
**Status:** In Development

---

## 1. Executive Summary

ICTU Community is a university-ready mobile application designed to facilitate seamless communication, information sharing, and academic management within an educational institution. The application serves four distinct user roles (Students, Teachers, Staff, and Administrators) and provides role-based features for managing academic activities, announcements, and community engagement.

Currently implemented: **Flutter for cross-platform mobile development**
Planned: **Node.js/Express backend and Supabase (PostgreSQL) database**

---

## 2. Product Overview

### 2.1 Purpose
ICTU Community connects members of the university community in a single, unified platform for:
- Academic management and communication
- Real-time notifications and alerts
- Resource sharing and document management
- Community engagement and announcements

### 2.2 Current Implementation Status
- ✅ **Flutter/Dart Frontend**: Fully configured and ready for feature development
- ✅ **Basic UI Structure**: Splash Screen, Welcome Screen, Material Design Theme
- ⏳ **Backend**: Planned with Node.js/Express
- ⏳ **Database**: Planned with Supabase/PostgreSQL

---

## 3. Technology Stack

### 3.1 Frontend (Current)
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x+
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: Material Design 3
- **Min SDK**: Dart 3.11.0+
- **Key Dependencies**:
  - `cupertino_icons`: ^1.0.8
  - `flutter_lints`: ^6.0.0

### 3.2 Mobile Platform
- **Android**: 
  - Build System: Gradle (Flutter)
  - Embedding: Flutter Android Embedding v2
  - Min API: 21+
  - Target API: 34+

### 3.3 Backend (Planned)
- **Runtime**: Node.js 18+
- **Framework**: Express.js 4.x
- **Pattern**: RESTful API with JWT authentication
- **Architecture**: Microservices-ready

### 3.4 Database (Planned)
- **Primary**: PostgreSQL via Supabase
- **Authentication**: Supabase Auth with JWT
- **Real-time**: Supabase Real-time subscriptions
- **Storage**: Supabase Storage for files

### 3.5 Additional Services (Planned)
- **Push Notifications**: Firebase Cloud Messaging
- **Authentication**: Supabase Auth
- **Analytics**: Firebase Analytics
- **Error Tracking**: Sentry

---

## 4. User Roles & Requirements

### 4.1 Students
**Features**:
- View feeds and news
- Read field-specific newsletters (coding, marketing, etc.)
- Access class information and recorded lectures
- Receive notifications for:
  - Exam schedules
  - Continuous Assessment (CA) announcements
  - Assignment deadlines
  - Resit exam information
- Register for classes
- Submit assignments
- View personal dashboard and grades

### 4.2 Teachers
**Features**:
- Publish course materials and resources
- Create and distribute assignments
- View class-related feeds and news
- Assign class delegates from students
- Track assignment submissions
- Grade work and provide feedback
- Manage course schedule

### 4.3 Staff
**Features** (Planned):
- Manage timetables and classroom allocations
- Process student administrative requests
- Issue transcripts and handle registrations
- Publish campus-wide announcements
- Manage facility bookings
- Generate administrative reports

### 4.4 Administrators
**Features** (Planned):
- User account management (CRUD operations)
- Role and permission management
- System configuration (semester dates, policies)
- Content moderation (feeds, news)
- Analytics and reporting
- Backup and recovery management
- Audit logs and activity tracking

---

## 5. System Architecture

### 5.1 High-Level System Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        A["📱 Mobile App<br/>Flutter + Dart"]
    end
    
    subgraph "API Layer"
        B["🚀 API Gateway<br/>Express.js"]
        C["🔐 Auth Service<br/>JWT/Supabase"]
        D["⚙️ Business Logic<br/>Services"]
    end
    
    subgraph "Data Layer"
        E["🗄️ Database<br/>PostgreSQL"]
        F["💾 File Storage<br/>Supabase Storage"]
    end
    
    subgraph "External Services"
        G["📢 Push Notifications<br/>FCM"]
        H["📊 Analytics<br/>Firebase"]
    end
    
    A -->|REST API| B
    B --> C
    B --> D
    D --> E
    D --> F
    B -.->|Notifications| G
    A -.->|Events| H
