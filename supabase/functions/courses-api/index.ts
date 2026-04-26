/// <reference lib="deno.ns" />
// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const COURSE_CODE_RE = /^[A-Z]{3}\d{4}$/;

type Role = 'student' | 'lecturer' | 'delegate';

function asText(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function asBool(value: unknown, fallback = false): boolean {
  return typeof value === 'boolean' ? value : fallback;
}

function normalizeCode(value: unknown): string {
  return asText(value).toUpperCase();
}

function json(status: number, payload: Record<string, unknown>) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function fail(status: number, error: string) {
  return json(status, { success: false, error });
}

async function resolveAuth(request: Request) {
  const authHeader = request.headers.get('Authorization') ?? '';
  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7).trim()
    : '';

  if (!token) {
    throw new Error('Missing bearer token');
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    throw new Error('Server not configured');
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser(token);

  if (userError || !user) {
    throw new Error(userError?.message ?? 'Invalid user session');
  }

  const { data: profile, error: profileError } = await serviceClient
    .from('profiles')
    .select('id, full_name, role')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError) {
    throw new Error(profileError.message);
  }

  const roleRaw = asText(profile?.role ?? 'student').toLowerCase();
  const role: Role =
    roleRaw === 'lecturer' || roleRaw === 'delegate' ? (roleRaw as Role) : 'student';

  return {
    serviceClient,
    userId: user.id,
    fullName: asText(profile?.full_name ?? user.email ?? 'Unknown User'),
    role,
  };
}

async function assertCourseOwner(
  client: any,
  courseId: string,
  lecturerId: string,
) {
  const { data, error } = await client
    .from('courses')
    .select('id, lecturer_id, course_code, title, description, semester, archived, created_at')
    .eq('id', courseId)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error('Course not found');
  }

  if (data.lecturer_id !== lecturerId) {
    throw new Error('Forbidden: course does not belong to this lecturer');
  }

  return data;
}

async function getCourseMetrics(client: any, courseId: string, courseCode: string) {
  const [studentsRes, delegatesRes, lecturesRes, notesRes, alertsRes] = await Promise.all([
    client
      .from('course_enrollments')
      .select('id', { count: 'exact', head: true })
      .eq('course_id', courseId),
    client
      .from('course_delegates')
      .select('id', { count: 'exact', head: true })
      .eq('course_id', courseId),
    client
      .from('lectures')
      .select('id', { count: 'exact', head: true })
      .eq('course_code', courseCode),
    client
      .from('lecture_notes')
      .select('id', { count: 'exact', head: true })
      .eq('course_id', courseId),
    client
      .from('alerts')
      .select('id', { count: 'exact', head: true })
      .eq('course_code', courseCode),
  ]);

  return {
    students: studentsRes.count ?? 0,
    delegates: delegatesRes.count ?? 0,
    lectures: lecturesRes.count ?? 0,
    notes: notesRes.count ?? 0,
    alerts: alertsRes.count ?? 0,
  };
}

function mapCourseRow(row: any) {
  return {
    id: row.id,
    courseCode: row.course_code,
    title: row.title,
    description: row.description ?? '',
    semester: row.semester,
    lecturerId: row.lecturer_id,
    lecturerName: row.profiles?.full_name ?? 'Lecturer',
    archived: !!row.archived,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    studentCount: row.course_enrollments?.[0]?.count ?? 0,
    delegateCount: row.course_delegates?.[0]?.count ?? 0,
    lectureCount: 0,
    notesCount: row.lecture_notes?.[0]?.count ?? 0,
    alertCount: row.alerts?.[0]?.count ?? 0,
    lastActivity: row.updated_at ?? row.created_at,
  };
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return fail(405, 'Method not allowed');
  }

  try {
    // Raw HTTP Bypass: Use arrayBuffer to avoid issues with some clients stripping bodies
    const arrayBuffer = await request.arrayBuffer();
    const decoder = new TextDecoder();
    const bodyText = decoder.decode(arrayBuffer);

    // Diagnostic logging for body delivery issues
    const contentLength = request.headers.get('content-length');
    console.log(`LEN: ${contentLength} | BYTES: ${arrayBuffer.byteLength}`);

    let body: any = {};
    if (bodyText) {
      try {
        body = JSON.parse(bodyText);
      } catch (e) {
        console.error('Failed to parse JSON body:', e);
      }
    }

    const action = asText(body?.action || body?.Action).toLowerCase();

    // Ping action for health checks (doesn't require auth)
    if (action === 'ping') {
      return json(200, { success: true, message: 'pong', bytes: arrayBuffer.byteLength });
    }

    const auth = await resolveAuth(request);
    const client = auth.serviceClient;

    if (!action) {
      return fail(400, 'action is required');
    }

    if (
      action !== 'list_my_courses' &&
      action !== 'search_students' &&
      auth.role !== 'lecturer'
    ) {
      return fail(403, 'Only lecturers can perform this action');
    }

    if (action === 'create_course') {
      const courseCode = normalizeCode(body.courseCode);
      const title = asText(body.title);
      const description = asText(body.description);
      const semester = asText(body.semester);

      if (!COURSE_CODE_RE.test(courseCode)) {
        return fail(400, 'Course code must match format XXX####');
      }
      if (!title) {
        return fail(400, 'title is required');
      }
      if (!semester) {
        return fail(400, 'semester is required');
      }

      const { data: existing, error: existingError } = await client
        .from('courses')
        .select('id')
        .eq('course_code', courseCode)
        .maybeSingle();
      if (existingError && existingError.code !== 'PGRST116') {
        return fail(400, existingError.message);
      }
      if (existing) {
        return fail(409, 'Course code already exists');
      }

      const { data: inserted, error: insertError } = await client
        .from('courses')
        .insert({
          course_code: courseCode,
          title,
          description,
          semester,
          lecturer_id: auth.userId,
        })
        .select(
          'id, course_code, title, description, semester, lecturer_id, archived, created_at, updated_at, profiles:lecturer_id(full_name), course_enrollments(count), course_delegates(count), lecture_notes(count), alerts(count)',
        )
        .single();

      if (insertError) {
        return fail(400, insertError.message);
      }

      return json(200, {
        success: true,
        data: mapCourseRow(inserted),
      });
    }

    if (action === 'list_my_courses') {
      const page = Number.parseInt(String(body.page ?? 0), 10);
      const limit = Math.max(
        1,
        Math.min(50, Number.parseInt(String(body.limit ?? 20), 10)),
      );
      const search = asText(body.search).toLowerCase();
      const from = Math.max(0, page) * limit;
      const to = from + limit - 1;

      let query = client
        .from('courses')
        .select(
          'id, course_code, title, description, semester, lecturer_id, archived, created_at, updated_at, profiles:lecturer_id(full_name), course_enrollments(count), course_delegates(count), lecture_notes(count), alerts(count)',
          { count: 'exact' },
        )
        .eq('lecturer_id', auth.userId)
        .order('updated_at', { ascending: false })
        .range(from, to);

      if (search) {
        query = query.or(
          `course_code.ilike.%${search}%,title.ilike.%${search}%`,
        );
      }

      const { data: rows, error, count } = await query;
      if (error) {
        return fail(400, error.message);
      }

      const items = (rows ?? []).map((row: any) => mapCourseRow(row));
      return json(200, {
        success: true,
        data: {
          items,
          hasMore: from + items.length < (count ?? 0),
        },
      });
    }

    if (action === 'get_course_details') {
      const courseId = asText(body.courseId);
      if (!courseId) {
        return fail(400, 'courseId is required');
      }

      const row = await assertCourseOwner(client, courseId, auth.userId);
      const metrics = await getCourseMetrics(client, courseId, row.course_code);

      const { data: lecturerProfile } = await client
        .from('profiles')
        .select('full_name')
        .eq('id', row.lecturer_id)
        .maybeSingle();

      return json(200, {
        success: true,
        data: {
          id: row.id,
          courseCode: row.course_code,
          title: row.title,
          description: row.description ?? '',
          semester: row.semester,
          lecturerId: row.lecturer_id,
          lecturerName: asText(lecturerProfile?.full_name || auth.fullName),
          archived: !!row.archived,
          studentCount: metrics.students,
          lectureCount: metrics.lectures,
          notesCount: metrics.notes,
          alertCount: metrics.alerts,
          lastActivity: row.updated_at ?? row.created_at,
        },
      });
    }

    if (action === 'update_course') {
      const courseId = asText(body.courseId);
      const title = asText(body.title);
      const description = asText(body.description);
      const semester = asText(body.semester);
      const archived = asBool(body.archived, false);

      if (!courseId) return fail(400, 'courseId is required');
      if (!title) return fail(400, 'title is required');
      if (!semester) return fail(400, 'semester is required');

      await assertCourseOwner(client, courseId, auth.userId);

      const { data: updated, error } = await client
        .from('courses')
        .update({ title, description, semester, archived })
        .eq('id', courseId)
        .select('id, course_code, title, description, semester, lecturer_id, archived, created_at, updated_at, profiles:lecturer_id(full_name), course_enrollments(count), course_delegates(count), lecture_notes(count), alerts(count)')
        .single();
      if (error) return fail(400, error.message);

      return json(200, { success: true, data: mapCourseRow(updated) });
    }

    if (action === 'delete_course') {
      const courseId = asText(body.courseId);
      if (!courseId) return fail(400, 'courseId is required');

      await assertCourseOwner(client, courseId, auth.userId);

      const [enrollments, delegates, lectures, notes] = await Promise.all([
        client
          .from('course_enrollments')
          .select('id', { count: 'exact', head: true })
          .eq('course_id', courseId),
        client
          .from('course_delegates')
          .select('id', { count: 'exact', head: true })
          .eq('course_id', courseId),
        client
          .from('lectures')
          .select('id', { count: 'exact', head: true })
          .eq('course_code', courseId),
        client
          .from('lecture_notes')
          .select('id', { count: 'exact', head: true })
          .eq('course_id', courseId),
      ]);

      const hasContent =
        (enrollments.count ?? 0) > 0 ||
        (delegates.count ?? 0) > 0 ||
        (lectures.count ?? 0) > 0 ||
        (notes.count ?? 0) > 0;
      if (hasContent) {
        return fail(400, 'Cannot delete course with existing content');
      }

      const { error } = await client.from('courses').delete().eq('id', courseId);
      if (error) return fail(400, error.message);
      return json(200, { success: true, data: { deleted: true } });
    }

    if (action === 'list_students') {
      const courseId = asText(body.courseId);
      if (!courseId) return fail(400, 'courseId is required');
      await assertCourseOwner(client, courseId, auth.userId);

      const { data, error } = await client
        .from('course_enrollments')
        .select('id, enrolled_at, student_id, profiles:student_id(id, full_name, email)')
        .eq('course_id', courseId)
        .order('enrolled_at', { ascending: false });
      if (error) return fail(400, error.message);

      const items = (data ?? []).map((r: any) => ({
        id: r.profiles?.id,
        fullName: r.profiles?.full_name ?? 'Unknown Student',
        email: r.profiles?.email ?? '',
        enrolledAt: r.enrolled_at,
      }));

      return json(200, { success: true, data: { items } });
    }

    if (action === 'search_students') {
      const query = asText(body.query).toLowerCase();
      if (!query) return json(200, { success: true, data: { items: [] } });

      const { data, error } = await client
        .from('profiles')
        .select('id, full_name, email, role')
        .eq('role', 'student')
        .ilike('email', `%${query}%`)
        .limit(25);
      if (error) return fail(400, error.message);

      const items = (data ?? []).map((r: any) => ({
        id: r.id,
        fullName: r.full_name ?? 'Unknown Student',
        email: r.email ?? '',
        enrolledAt: new Date().toISOString(),
      }));

      return json(200, { success: true, data: { items } });
    }

    if (action === 'add_students') {
      const courseId = asText(body.courseId);
      const studentIds = Array.isArray(body.studentIds)
        ? body.studentIds.map((x: unknown) => asText(x)).filter(Boolean)
        : [];
      if (!courseId) return fail(400, 'courseId is required');
      if (studentIds.length === 0) return fail(400, 'studentIds is required');
      await assertCourseOwner(client, courseId, auth.userId);

      const rows = studentIds.map((id: string) => ({
        course_id: courseId,
        student_id: id,
      }));

      const { error } = await client
        .from('course_enrollments')
        .upsert(rows, { onConflict: 'course_id,student_id', ignoreDuplicates: true });
      if (error) return fail(400, error.message);

      return json(200, { success: true, data: { added: studentIds.length } });
    }

    if (action === 'remove_student') {
      const courseId = asText(body.courseId);
      const studentId = asText(body.studentId);
      if (!courseId || !studentId) return fail(400, 'courseId and studentId are required');
      await assertCourseOwner(client, courseId, auth.userId);

      const { error: deleteEnrollmentError } = await client
        .from('course_enrollments')
        .delete()
        .eq('course_id', courseId)
        .eq('student_id', studentId);
      if (deleteEnrollmentError) return fail(400, deleteEnrollmentError.message);

      await client
        .from('course_delegates')
        .delete()
        .eq('course_id', courseId)
        .eq('student_id', studentId);

      return json(200, { success: true, data: { removed: true } });
    }

    if (action === 'list_delegates') {
      const courseId = asText(body.courseId);
      if (!courseId) return fail(400, 'courseId is required');
      await assertCourseOwner(client, courseId, auth.userId);

      const { data, error } = await client
        .from('course_delegates')
        .select('id, student_id, can_upload_notes, can_edit_notes, can_delete_notes, profiles:student_id(full_name, email)')
        .eq('course_id', courseId)
        .order('created_at', { ascending: false });
      if (error) return fail(400, error.message);

      const items = (data ?? []).map((r: any) => ({
        id: r.id,
        studentId: r.student_id,
        studentName: r.profiles?.full_name ?? 'Unknown Student',
        studentEmail: r.profiles?.email ?? '',
        canUploadNotes: !!r.can_upload_notes,
        canEditNotes: !!r.can_edit_notes,
        canDeleteNotes: !!r.can_delete_notes,
      }));

      return json(200, { success: true, data: { items } });
    }

    if (action === 'assign_delegate') {
      const courseId = asText(body.courseId);
      const studentId = asText(body.studentId);
      if (!courseId || !studentId) return fail(400, 'courseId and studentId are required');
      await assertCourseOwner(client, courseId, auth.userId);

      const payload = {
        course_id: courseId,
        student_id: studentId,
        can_upload_notes: asBool(body.canUploadNotes, true),
        can_edit_notes: asBool(body.canEditNotes, false),
        can_delete_notes: asBool(body.canDeleteNotes, false),
      };

      const { data, error } = await client
        .from('course_delegates')
        .upsert(payload, { onConflict: 'course_id,student_id' })
        .select('id, student_id, can_upload_notes, can_edit_notes, can_delete_notes, profiles:student_id(full_name, email)')
        .single();
      if (error) return fail(400, error.message);

      return json(200, {
        success: true,
        data: {
          id: data.id,
          studentId: data.student_id,
          studentName: data.profiles?.full_name ?? 'Unknown Student',
          studentEmail: data.profiles?.email ?? '',
          canUploadNotes: !!data.can_upload_notes,
          canEditNotes: !!data.can_edit_notes,
          canDeleteNotes: !!data.can_delete_notes,
        },
      });
    }

    if (action === 'update_delegate') {
      const courseId = asText(body.courseId);
      const delegateId = asText(body.delegateId);
      if (!courseId || !delegateId) return fail(400, 'courseId and delegateId are required');
      await assertCourseOwner(client, courseId, auth.userId);

      const { data, error } = await client
        .from('course_delegates')
        .update({
          can_upload_notes: asBool(body.canUploadNotes, false),
          can_edit_notes: asBool(body.canEditNotes, false),
          can_delete_notes: asBool(body.canDeleteNotes, false),
        })
        .eq('id', delegateId)
        .eq('course_id', courseId)
        .select('id, student_id, can_upload_notes, can_edit_notes, can_delete_notes, profiles:student_id(full_name, email)')
        .single();
      if (error) return fail(400, error.message);

      return json(200, {
        success: true,
        data: {
          id: data.id,
          studentId: data.student_id,
          studentName: data.profiles?.full_name ?? 'Unknown Student',
          studentEmail: data.profiles?.email ?? '',
          canUploadNotes: !!data.can_upload_notes,
          canEditNotes: !!data.can_edit_notes,
          canDeleteNotes: !!data.can_delete_notes,
        },
      });
    }

    if (action === 'remove_delegate') {
      const courseId = asText(body.courseId);
      const delegateId = asText(body.delegateId);
      if (!courseId || !delegateId) return fail(400, 'courseId and delegateId are required');
      await assertCourseOwner(client, courseId, auth.userId);

      const { error } = await client
        .from('course_delegates')
        .delete()
        .eq('id', delegateId)
        .eq('course_id', courseId);
      if (error) return fail(400, error.message);

      return json(200, { success: true, data: { removed: true } });
    }

    return fail(400, `Unsupported action: ${action}`);
  } catch (error) {
    const message = (error as Error)?.message ?? 'Bad request';
    const status = message.toLowerCase().includes('token') ? 401 : 400;
    return fail(status, message);
  }
});

