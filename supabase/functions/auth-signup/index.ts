// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type UserRole = 'student' | 'lecturer' | 'delegate';
const SCHOOL_DOMAIN = '@ictuniversity.edu.cm';

function isAllowedRole(value: string): value is UserRole {
  return value === 'student' || value === 'lecturer' || value === 'delegate';
}

function isSchoolEmail(email: string): boolean {
  return email.toLowerCase().endsWith(SCHOOL_DOMAIN);
}

function isAllowedRoleEmail(email: string, _role: UserRole): boolean {
  return isSchoolEmail(email);
}

type SignupPayload = {
  user_id: string;
  full_name: string;
  email: string;
  role: string;
  faculty: string;
  program: string;
  year_level: number;
};

function isNonEmptyText(value: unknown): value is string {
  return typeof value === 'string' && value.trim().length > 0;
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed.' }, { status: 405 });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !serviceRoleKey) {
    return Response.json({ error: 'Server not configured.' }, { status: 500 });
  }

  let payload: SignupPayload;
  try {
    payload = (await request.json()) as SignupPayload;
  } catch (_) {
    return Response.json({ error: 'Invalid request body.' }, { status: 400 });
  }

  const normalizedPayload = {
    user_id: typeof payload.user_id === 'string' ? payload.user_id.trim() : '',
    full_name: typeof payload.full_name === 'string' ? payload.full_name.trim() : '',
    email: typeof payload.email === 'string' ? payload.email.trim().toLowerCase() : '',
    role: typeof payload.role === 'string' ? payload.role.trim() : '',
    faculty: typeof payload.faculty === 'string' ? payload.faculty.trim() : '',
    program: typeof payload.program === 'string' ? payload.program.trim() : '',
    year_level: Number(payload.year_level),
  };

  if (!isNonEmptyText(normalizedPayload.user_id)) {
    return Response.json({ error: 'user_id is required.' }, { status: 400 });
  }

  if (!isNonEmptyText(normalizedPayload.full_name)) {
    return Response.json({ error: 'full_name is required.' }, { status: 400 });
  }

  if (!isAllowedRole(normalizedPayload.role)) {
    return Response.json({ error: 'Invalid role.' }, { status: 400 });
  }

  if (!isSchoolEmail(normalizedPayload.email)) {
    return Response.json(
      { error: 'Use your ICT University email ending with @ictuniversity.edu.cm.' },
      { status: 400 },
    );
  }

  if (!isAllowedRoleEmail(normalizedPayload.email, normalizedPayload.role)) {
    return Response.json(
      { error: 'Use your ICT University email ending with @ictuniversity.edu.cm.' },
      { status: 400 },
    );
  }

  if (
    !Number.isInteger(normalizedPayload.year_level) ||
    normalizedPayload.year_level < 1 ||
    normalizedPayload.year_level > 4
  ) {
    return Response.json({ error: 'year_level must be between 1 and 4.' }, { status: 400 });
  }

  if (!isNonEmptyText(normalizedPayload.program)) {
    return Response.json({ error: 'program is required.' }, { status: 400 });
  }

  if (!isNonEmptyText(normalizedPayload.faculty)) {
    return Response.json({ error: 'faculty is required.' }, { status: 400 });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const profileRow = {
    id: normalizedPayload.user_id,
    full_name: normalizedPayload.full_name,
    email: normalizedPayload.email,
    role: normalizedPayload.role,
    faculty: normalizedPayload.faculty,
    program: normalizedPayload.program,
    year_level: normalizedPayload.year_level,
  };

  const { error: upsertError } = await adminClient
    .from('profiles')
    .upsert(profileRow, { onConflict: 'id' });

  if (upsertError?.message.includes('profiles_email_key')) {
    const profileUpdate = {
      full_name: normalizedPayload.full_name,
      role: normalizedPayload.role,
      faculty: normalizedPayload.faculty,
      program: normalizedPayload.program,
      year_level: normalizedPayload.year_level,
    };

    const { error: updateError } = await adminClient
      .from('profiles')
      .update(profileUpdate)
      .eq('email', normalizedPayload.email);

    if (updateError) {
      return Response.json({ error: updateError.message }, { status: 400 });
    }
  } else if (upsertError) {
    return Response.json({ error: upsertError.message }, { status: 400 });
  }

  return Response.json({ ok: true }, { status: 200 });
});

