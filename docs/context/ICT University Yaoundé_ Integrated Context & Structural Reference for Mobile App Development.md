# ICT University Yaoundé: Integrated Context & Structural Reference for Mobile App Development

This document provides a unified, comprehensive reference for the "ICTU Community" mobile application, combining official university data, the provided SRS, and the detailed academic structural analysis.

---

## 1. Academic Structure & Semester System
The ICT University operates on a **Trimester System** (three main semesters per year).

| Semester | Duration | Activity | Key Milestones |
| :--- | :--- | :--- | :--- |
| **Fall** | 12 Weeks (Oct – Jan) | Main intake | Orientation (Oct), Matriculation (Nov 14), Exams (Jan). |
| **Spring** | 12 Weeks (Feb – May) | Core session | Vetting of Exams (Apr), Exams (May), Commencement (Jul 25). |
| **Summer** | 9 Weeks (Jun – Aug) | Accelerated | Top-up courses, Exams (Aug/Sep). |

### Course Load & Credits
- **Course Weight**: Most courses carry **6 credits**.
- **Semester Load**: Students typically take **6 courses** per semester, totaling **36 credits**.
- **Curriculum**: US-based curriculum adapted for developing economies.

---

## 2. Organizational Hierarchy & Role Responsibilities
The university's hierarchy is designed to support academic quality and administrative efficiency.

### Management Team
- **Vice-Chancellor (Prof. Jean-Emmanuel Pondi)**: Overall head of academic and administrative affairs.
- **Deputy VC (Academics/Admin) (Prof. Alain Vilard Ndi Isoh)**: Oversees program delivery and research.
- **Registrar (Prof. Pierre Fonkoua)**: Manages academic records, enrollment, and results publication.
- **Director of Quality Assurance (Dr. Irene S. Mbarika)**: Ensures pedagogical standards and ethics.

### App Role Mapping & Workflow
| Role | Responsibilities | Key App Tasks |
| :--- | :--- | :--- |
| **Student** | Learning & Progression | View timetable, access materials, track grades, check financial status. |
| **Lecturer** | Instruction & Assessment | Upload notes/audio, assign delegates, publish alerts, submit grades. |
| **Course Delegate** | Peer Support | Upload/edit notes (with approval), publish announcements. |
| **Staff (Admin)** | Infrastructure & Data | Manage timetables, verify bank receipts, handle document requests. |
| **Administrator** | System Control | Manage user roles, configure semester dates, moderate content. |

---

## 3. Evaluation & Grading System
The grading follows a weighted structure that must be reflected in the student and lecturer dashboards.

| Component | Weight | Responsibility |
| :--- | :--- | :--- |
| **Attendance & Participation** | 10% | Recorded by Lecturer |
| **Assignments / Group Work** | 20% | Published & Graded via App |
| **Continuous Assessment (CA)** | 30% | Scheduled via Alerts |
| **Final Examination** | 40% | Vetted by UB; results approved by Senate |

---

## 4. Administrative Workflows (The "Student Journey")
Integrating these workflows is critical for the app's success in replacing manual processes.

### Financial Clearance Workflow
1. Student pays fees via bank transfer.
2. Student uploads bank receipt to the **Finance Module** in the app.
3. Finance Office verifies and grants **Financial Clearance**.
4. Clearance is shared with the Registrar's module for academic document eligibility.

### Results & Document Request Workflow
1. Exams are completed and graded by lecturers.
2. Grades are submitted to the **Registrar's Office** via the secure portal.
3. Senate approves results; Registrar publishes them on the app.
4. Students have a **1-week window** to file complaints/petitions via the app.
5. Once final, students can request transcripts/certificates through the **Document Request** feature.

---

## 5. Major Programs (Undergraduate)
The app should organize materials and forums by these specific majors.

| Faculty | Departments / Majors |
| :--- | :--- |
| **ICT (FICT)** | Software Engineering, Information Systems & Networking, Data Communication, Telecommunications, ICT Education. |
| **Business (FBMS)** | Accounting IT, Business Management & Sustainable Development, Accounting (English/French). |
| **Engineering** | Electronics Engineering (Power/Renewable Energy). |
| **Sciences** | Natural Medicine, Health Information Technology (Diploma). |

---

## 6. Feature Refinement (Based on SRS & Analysis)
- **AI Integration**: The app should transcribe audio recordings uploaded by lecturers into searchable summaries.
- **Course Delegate Workflow**: Lecturers must have a "Designate Delegate" button. Content submitted by delegates should enter a "Pending Approval" queue for the lecturer.
- **Offline Caching**: Given the local context, lecture notes and timetables should be available offline once downloaded.
- **Notification Engine**: Must be linked to the academic calendar (e.g., auto-reminder 48h before CA dates).

---
*Note: This integrated report serves as the final context source for development. For course-specific codes (SWE, ISN, etc.), refer to the attached Spring Semester course list.*
