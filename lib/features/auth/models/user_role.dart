enum UserRole {
  student,
  lecturer,
  delegateRole,
  admin;

  String get dbValue {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.lecturer:
        return 'lecturer';
      case UserRole.delegateRole:
        return 'delegate';
      case UserRole.admin:
        return 'admin';
    }
  }

  bool get isDelegate => this == UserRole.delegateRole;
  bool get isAdmin => this == UserRole.admin;

  static UserRole fromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'lecturer':
        return UserRole.lecturer;
      case 'delegate':
        return UserRole.delegateRole;
      case 'admin':
        return UserRole.admin;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}

