import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type StudentAction =
  | 'list_available_courses'
  | 'enroll_in_course'
  | 'list_my_courses'
  | 'get_course_content';

type StudentPayload = {
  action?: StudentAction;
  course_id?: string;
  course_code?: string;
  search?: string;
  page?: number;
  limit?: number;
};

function extractBearerToken(request: Request): string {
  const authHeader = request.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return '';
  }
  return authHeader.replace('Bearer ', '').trim();
}

function badRequest(message: string): Response {
  return Response.json({ ok: false, error: message }, { status: 400 });
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
    });
  }

  if (request.method !== 'POST') {
    return Response.json({ ok: false, error: 'Method not allowed.' }, { status: 405 });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return Response.json({ ok: false, error: 'Server not configured.' }, { status: 500 });
  }

  const token = extractBearerToken(request);
  if (token.length === 0) {
    return Response.json({ ok: false, error: 'Missing bearer token.' }, { status: 401 });
  }

  // Raw HTTP Bypass for stability
  const arrayBuffer = await request.arrayBuffer();
  const decoder = new TextDecoder();
  const bodyText = decoder.decode(arrayBuffer);

  let payload: any = {};
  if (bodyText) {
    try {
      payload = JSON.parse(bodyText);
    } catch (_) {
      return badRequest('Invalid JSON body.');
    }
  }

  const action = (payload.action || payload.Action || '').toLowerCase();
  if (!action) return badRequest('action is required.');

  if (action === 'ping') {
    return Response.json({ ok: true, message: 'pong', bytes: arrayBuffer.byteLength });
  }

  // 1. List all available courses in the university (Filtered by student's major)
  if (action === 'list_available_courses') {
    const search = (payload.search ?? '').trim();
    const page = payload.page ?? 0;
    const limit = payload.limit ?? 20;
    const from = page * limit;
    const to = from + limit - 1;

    let query = adminClient
      .from('courses')
      .select('id, course_code, title, description, semester, created_at, profiles:lecturer_id(full_name)')
      .order('course_code', { ascending: true })
      .range(from, to);

    if (search.length > 0) {
      query = query.or(`course_code.ilike.%${search}%,title.ilike.%${search}%`);
    }

    const { data, error } = await query;
    if (error) return Response.json({ ok: false, error: error.message }, { status: 400 });

    // Check enrollment status for each course for this user using course_enrollments
    const { data: enrollments } = await adminClient
        .from('course_enrollments')
        .select('course_code')
        .eq('student_id', user.id);

    const enrolledCodes = new Set((enrollments ?? []).map(e => e.course_code));

    const courses = (data ?? []).map((row: any) => ({
      id: row.id,
      course_code: row.course_code,
      title: row.title,
      description: row.description,
      semester: row.semester,
      lecturer_name: row.profiles?.full_name ?? 'Unknown Lecturer',
      is_enrolled: enrolledCodes.has(row.course_code),
      created_at: row.created_at,
    }));

    return Response.json({ ok: true, courses }, { status: 200 });
  }

  // 2. Enroll in a course
  if (action === 'enroll_in_course') {
    const courseId = payload.course_id;
    if (!courseId) return badRequest('course_id is required.');

    // Fetch the course to get its course_code
    const { data: course, error: courseError } = await adminClient
      .from('courses')
      .select('course_code')
      .eq('id', courseId)
      .single();

    if (courseError || !course) {
      return Response.json({ ok: false, error: 'Course not found.' }, { status: 404 });
    }

    // Add to course_enrollments (Code based) as requested
    const { error: enrollError } = await adminClient
      .from('course_enrollments')
      .insert({
        student_id: user.id,
        course_code: course.course_code,
      });

    // Also add to enrollments (UUID based) for backward compatibility/consistency if it exists
    await adminClient
      .from('enrollments')
      .upsert({
        student_id: user.id,
        course_id: courseId,
      }, { onConflict: 'student_id,course_id' });

    if (enrollError) return Response.json({ ok: false, error: enrollError.message }, { status: 400 });
    return Response.json({ ok: true, message: 'Enrolled successfully.' }, { status: 200 });
  }

  // 3. List courses the student is enrolled in (with summary info)
  if (action === 'list_my_courses') {
    const { data, error } = await adminClient
      .from('course_enrollments')
      .select(`
        course_code,
        course:courses!course_code(
          id,
          course_code,
          title,
          description,
          semester,
          profiles:lecturer_id(full_name)
        )
      `)
      .eq('student_id', user.id);

    if (error) return Response.json({ ok: false, error: error.message }, { status: 400 });

    const coursesWithSummary = await Promise.all((data ?? []).map(async (row: any) => {
      const course = row.course;
      if (!course) return null;

      // Get counts for "features"
      const [{ count: notesCount }, { count: alertsCount }] = await Promise.all([
        adminClient
          .from('notes')
          .select('*', { count: 'exact', head: true })
          .eq('course_code', course.course_code)
          .eq('status', 'published'),
        adminClient
          .from('alerts')
          .select('*', { count: 'exact', head: true })
          .eq('course_code', course.course_code)
      ]);

      return {
        id: course.id,
        course_code: course.course_code,
        title: course.title,
        description: course.description,
        semester: course.semester,
        lecturer_name: course.profiles?.full_name ?? 'Unknown Lecturer',
        notes_count: notesCount ?? 0,
        alerts_count: alertsCount ?? 0,
      };
    }));

    return Response.json({ ok: true, courses: coursesWithSummary.filter(c => c !== null) }, { status: 200 });
  }

  // 4. Get course content (Notes, Assignments, Exams)
  if (action === 'get_course_content') {
    const courseCode = payload.course_code;
    const courseId = payload.course_id;
    if (!courseCode || !courseId) return badRequest('course_code and course_id are required.');

    // Fetch notes
    const { data: notes, error: notesError } = await adminClient
      .from('notes')
      .select('id, title, description, content_url, created_at')
      .eq('course_code', courseCode)
      .eq('status', 'published');

    // Fetch alerts (Assignments, Exams, CAs)
    const { data: alerts, error: alertsError } = await adminClient
      .from('alerts')
      .select('id, title, description, type, deadline, requirements, created_at')
      .eq('course_code', courseCode);

    if (notesError || alertsError) {
      return Response.json({
        ok: false,
        error: notesError?.message || alertsError?.message
      }, { status: 400 });
    }

    return Response.json({
      ok: true,
      notes: notes ?? [],
      alerts: alerts ?? [],
    }, { status: 200 });
  }

  return badRequest('Unsupported action.');
});
