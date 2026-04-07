enum UserRole {
  student,
  lecturer,
  delegateRole;

  String get dbValue {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.lecturer:
        return 'lecturer';
      case UserRole.delegateRole:
        return 'delegate';
    }
  }

  bool get isDelegate => this == UserRole.delegateRole;

  static UserRole fromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'lecturer':
        return UserRole.lecturer;
      case 'delegate':
        return UserRole.delegateRole;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}

