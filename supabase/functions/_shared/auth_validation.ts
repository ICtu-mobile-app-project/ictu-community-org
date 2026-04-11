export type UserRole = 'student' | 'lecturer' | 'delegate';

const SCHOOL_DOMAIN = '@ictuniversity.edu.cm';

export function isAllowedRole(value: string): value is UserRole {
  return value === 'student' || value === 'lecturer' || value === 'delegate';
}

export function isSchoolEmail(email: string): boolean {
  const normalized = email.toLowerCase();
  return normalized.endsWith(SCHOOL_DOMAIN);
}

export function isAllowedRoleEmail(email: string, _role: UserRole): boolean {
  return isSchoolEmail(email);
}

