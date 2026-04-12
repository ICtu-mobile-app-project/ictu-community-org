import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SCHOOL_DOMAIN = '@ictuniversity.edu.cm';
const ALLOWED_SEMESTERS = new Set<string>(['Fall 2025', 'Spring 2026', 'Summer 2025']);

type CreateCoursePayload = {
  course_code?: string;
  title?: string;
  description?: string;
  semester?: string;
};

function extractBearerToken(request: Request): string {
  const authHeader = request.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return '';
  }
  return authHeader.replace('Bearer ', '').trim();
}

function isSchoolEmail(email: string): boolean {
  return email.toLowerCase().endsWith(SCHOOL_DOMAIN);
}

async function insertCourse(
  client: ReturnType<typeof createClient>,
  row: Record<string, unknown>,
): Promise<{ data: Record<string, unknown> | null; error: { message: string } | null }> {
  const firstTry = await client
    .from('courses')
    .insert(row)
    .select('id, course_code, title, description, semester, created_at')
    .single();

  if (
    firstTry.error &&
    firstTry.error.message.toLowerCase().includes('column') &&
    firstTry.error.message.toLowerCase().includes('semester')
  ) {
    const fallback = { ...row };
    delete fallback.semester;

    const retry = await client
      .from('courses')
      .insert(fallback)
      .select('id, course_code, title, description, created_at')
      .single();

    return {
      data: retry.data as Record<string, unknown> | null,
      error: retry.error ? { message: retry.error.message } : null,
    };
  }

  return {
    data: firstTry.data as Record<string, unknown> | null,
    error: firstTry.error ? { message: firstTry.error.message } : null,
  };
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed.' }, { status: 405 });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return Response.json({ error: 'Server not configured.' }, { status: 500 });
  }

  const token = extractBearerToken(request);
  if (token.length === 0) {
    return Response.json({ error: 'Missing bearer token.' }, { status: 401 });
  }

  let payload: CreateCoursePayload = {};
  try {
    payload = (await request.json()) as CreateCoursePayload;
  } catch (_) {
    return Response.json({ error: 'Invalid request body.' }, { status: 400 });
  }

  const courseCode = (payload.course_code ?? '').trim().toUpperCase();
  const title = (payload.title ?? '').trim();
  const description = (payload.description ?? '').trim();
  const semester = (payload.semester ?? '').trim();

  if (!RegExp('^[A-Z]{3}\\d{4}$').test(courseCode)) {
    return Response.json({ error: 'course_code must match format XXX####.' }, { status: 400 });
  }

  if (title.length === 0) {
    return Response.json({ error: 'title is required.' }, { status: 400 });
  }

  if (semester.length > 0 && !ALLOWED_SEMESTERS.has(semester)) {
    return Response.json({ error: 'Invalid semester value.' }, { status: 400 });
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser(token);

  if (userError || !user) {
    return Response.json(
      { error: userError?.message ?? 'Invalid user session.' },
      { status: 401 },
    );
  }

  if (!user.email || !isSchoolEmail(user.email)) {
    return Response.json(
      { error: 'Use your ICT University email ending with @ictuniversity.edu.cm.' },
      { status: 403 },
    );
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: profile, error: profileError } = await adminClient
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError && profileError.code !== 'PGRST116') {
    return Response.json({ error: profileError.message }, { status: 400 });
  }

  const role = typeof profile?.role === 'string' ? profile.role.trim() : '';
  if (role !== 'lecturer') {
    return Response.json({ error: 'Only lecturers can create courses.' }, { status: 403 });
  }

  const row: Record<string, unknown> = {
    course_code: courseCode,
    title,
    description,
    lecturer_id: user.id,
    semester,
  };

  const { data, error } = await insertCourse(adminClient, row);

  if (error) {
    const isDuplicate = error.message.toLowerCase().includes('duplicate');
    return Response.json(
      {
        error: isDuplicate
            ? 'A course with this code already exists for your account.'
            : error.message,
      },
      { status: isDuplicate ? 409 : 400 },
    );
  }

  return Response.json({ ok: true, course: data }, { status: 200 });
});


