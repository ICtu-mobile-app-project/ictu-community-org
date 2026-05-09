/// <reference lib="deno.ns" />
// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type Role = 'student' | 'lecturer' | 'delegate';

const NOTE_SELECT = 'id, course_id, course_code, title, description, summary, status, content_url, file_name, file_size_bytes, uploaded_by, created_at, updated_at, profiles:uploaded_by(full_name)';

function asText(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function asInt(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  const parsed = Number.parseInt(String(value ?? '0'), 10);
  return Number.isFinite(parsed) ? parsed : 0;
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

function assertStorageObjectPath(value: unknown): string {
  const raw = asText(value);
  if (!raw) {
    throw new Error('contentUrl is required');
  }

  let v = raw.replace(/^\/+/, '');
  v = v.replace(/^lecture-notes\//i, '');

  if (/^https?:\/\//i.test(v) || v.startsWith('gs://')) {
    throw new Error(
      'contentUrl must be a Storage object path (e.g. notes/<uid>/file.pdf), not a full URL',
    );
  }

  if (v.includes('..') || v.includes('\\')) {
    throw new Error('Invalid contentUrl path');
  }

  return v;
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

  const roleRaw = asText(profile?.role).toLowerCase();
  const role: Role =
    roleRaw === 'lecturer' || roleRaw === 'delegate' ? (roleRaw as Role) : 'student';

  return {
    serviceClient,
    userId: user.id,
    fullName: asText(profile?.full_name || user.email || 'Unknown User'),
    role,
  };
}

async function canReadCourse(client: any, courseId: string, userId: string) {
  const [owner, enrolled, delegate] = await Promise.all([
    client
      .from('courses')
      .select('id', { count: 'exact', head: true })
      .eq('id', courseId)
      .eq('lecturer_id', userId),
    client
      .from('course_enrollments')
      .select('id', { count: 'exact', head: true })
      .eq('course_id', courseId)
      .eq('student_id', userId),
    client
      .from('course_delegates')
      .select('id', { count: 'exact', head: true })
      .eq('course_id', courseId)
      .eq('student_id', userId),
  ]);

  return (owner.count ?? 0) > 0 || (enrolled.count ?? 0) > 0 || (delegate.count ?? 0) > 0;
}

async function canUploadNote(client: any, courseId: string, userId: string) {
  const owner = await client
    .from('courses')
    .select('id', { count: 'exact', head: true })
    .eq('id', courseId)
    .eq('lecturer_id', userId);
  if ((owner.count ?? 0) > 0) {
    return true;
  }

  const delegate = await client
    .from('course_delegates')
    .select('id', { count: 'exact', head: true })
    .eq('course_id', courseId)
    .eq('student_id', userId)
    .eq('can_upload_notes', true);
  return (delegate.count ?? 0) > 0;
}

async function canEditNote(client: any, courseId: string, userId: string) {
  const owner = await client
    .from('courses')
    .select('id', { count: 'exact', head: true })
    .eq('id', courseId)
    .eq('lecturer_id', userId);
  if ((owner.count ?? 0) > 0) {
    return true;
  }

  const delegate = await client
    .from('course_delegates')
    .select('id', { count: 'exact', head: true })
    .eq('course_id', courseId)
    .eq('student_id', userId)
    .eq('can_edit_notes', true);
  return (delegate.count ?? 0) > 0;
}

async function canDeleteNote(client: any, courseId: string, userId: string) {
  const owner = await client
    .from('courses')
    .select('id', { count: 'exact', head: true })
    .eq('id', courseId)
    .eq('lecturer_id', userId);
  if ((owner.count ?? 0) > 0) {
    return true;
  }

  const delegate = await client
    .from('course_delegates')
    .select('id', { count: 'exact', head: true })
    .eq('course_id', courseId)
    .eq('student_id', userId)
    .eq('can_delete_notes', true);
  return (delegate.count ?? 0) > 0;
}

function mapNote(row: any) {
  return {
    id: row.id,
    courseId: row.course_id,
    courseCode: row.course_code ?? '',
    title: row.title,
    description: row.description ?? '',
    summary: row.summary ?? '',
    status: row.status ?? 'published',
    contentUrl: row.content_url,
    fileName: row.file_name,
    fileSizeBytes: row.file_size_bytes ?? 0,
    uploadedBy: row.uploaded_by,
    uploadedByName: row.profiles?.full_name ?? 'Unknown User',
    createdAt: row.created_at,
    updatedAt: row.updated_at,
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
    const arrayBuffer = await request.arrayBuffer();
    const decoder = new TextDecoder();
    const bodyText = decoder.decode(arrayBuffer);

    let body: any = {};
    if (bodyText) {
      try {
        body = JSON.parse(bodyText);
      } catch (e) {
        console.error('Failed to parse JSON body:', e);
      }
    }

    const action = asText(body?.action || body?.Action).toLowerCase();
    if (action === 'ping') {
      return json(200, { success: true, message: 'pong' });
    }

    if (!action) {
      return fail(400, 'action is required');
    }

    const auth = await resolveAuth(request);
    const client = auth.serviceClient;

    if (action === 'create_note') {
      const courseId = asText(body.courseId);
      const courseCode = asText(body.courseCode || body.course_code);
      const title = asText(body.title);
      const description = asText(body.description);
      const summary = asText(body.summary);
      const status = asText(body.status) || 'published';
      const contentUrl = assertStorageObjectPath(body.contentUrl);
      const fileName = asText(body.fileName);
      const fileSizeBytes = asInt(body.fileSizeBytes);

      if (!courseId || !title || !fileName) {
        return fail(400, 'courseId, title, and fileName are required');
      }

      if (!courseCode) {
        return fail(400, 'course_code is required');
      }

      const allowed = await canUploadNote(client, courseId, auth.userId);
      if (!allowed) {
        return fail(403, 'You are not allowed to upload notes for this course');
      }

      // Fetch course_code for denormalized storage
      const { data: course } = await client
        .from('courses')
        .select('course_code')
        .eq('id', courseId)
        .single();

      const { data, error } = await client
        .from('notes')
        .insert({
          course_id: courseId,
          course_code: course?.course_code,
          title,
          description,
          summary,
          status,
          content_url: contentUrl,
          file_name: fileName,
          file_size_bytes: Math.max(0, fileSizeBytes),
          uploaded_by: auth.userId,
        })
        .select(NOTE_SELECT)
        .single();

      if (error) {
        return fail(400, error.message);
      }

      return json(200, { success: true, data: mapNote(data) });
    }

    if (action === 'list_notes') {
      const courseId = asText(body.courseId);
      const search = asText(body.search).toLowerCase();
      const sort = asText(body.sort).toLowerCase();
      if (!courseId) {
        return fail(400, 'courseId is required');
      }

      const allowed = await canReadCourse(client, courseId, auth.userId);
      if (!allowed) {
        return fail(403, 'You are not allowed to view notes for this course');
      }

      let query = client
        .from('notes')
        .select(NOTE_SELECT)
        .eq('course_id', courseId);

      // Security: Students only see published notes
      if (auth.role === 'student') {
        query = query.eq('status', 'published');
      }

      if (search) {
        query = query.ilike('title', `%${search}%`);
      }

      if (sort === 'oldest') {
        query = query.order('created_at', { ascending: true });
      } else if (sort === 'title') {
        query = query.order('title', { ascending: true });
      } else {
        query = query.order('created_at', { ascending: false });
      }

      const { data, error } = await query;
      if (error) {
        return fail(400, error.message);
      }

      return json(200, {
        success: true,
        data: { items: (data ?? []).map((row: any) => mapNote(row)) },
      });
    }

    if (action === 'get_note_details') {
      const noteId = asText(body.noteId);
      if (!noteId) {
        return fail(400, 'noteId is required');
      }

      let query = client
        .from('notes')
        .select(NOTE_SELECT)
        .eq('id', noteId);

      if (auth.role === 'student') {
        query = query.eq('status', 'published');
      }

      const { data, error } = await query.maybeSingle();

      if (error) {
        return fail(400, error.message);
      }
      if (!data) {
        return fail(404, 'Note not found');
      }

      const allowed = await canReadCourse(client, data.course_id, auth.userId);
      if (!allowed) {
        return fail(403, 'You are not allowed to view this note');
      }

      return json(200, { success: true, data: mapNote(data) });
    }

    if (action === 'update_note' || action === 'update_note_title') {
      const noteId = asText(body.noteId);
      const title = asText(body.title);
      const description = body.description !== undefined ? asText(body.description) : undefined;
      const summary = body.summary !== undefined ? asText(body.summary) : undefined;
      const status = body.status !== undefined ? asText(body.status) : undefined;

      if (!noteId) {
        return fail(400, 'noteId is required');
      }

      const { data: existing, error: existingError } = await client
        .from('notes')
        .select('id, course_id')
        .eq('id', noteId)
        .maybeSingle();
      if (existingError) {
        return fail(400, existingError.message);
      }
      if (!existing) {
        return fail(404, 'Note not found');
      }

      const allowed = await canEditNote(client, existing.course_id, auth.userId);
      if (!allowed) {
        return fail(403, 'You are not allowed to edit this note');
      }

      const updates: any = {};
      if (title) updates.title = title;
      if (description !== undefined) updates.description = description;
      if (summary !== undefined) updates.summary = summary;
      if (status !== undefined) updates.status = status;

      if (Object.keys(updates).length === 0) {
        return fail(400, 'No fields to update');
      }

      const { data, error } = await client
        .from('notes')
        .update(updates)
        .eq('id', noteId)
        .select(NOTE_SELECT)
        .single();
      if (error) {
        return fail(400, error.message);
      }

      return json(200, { success: true, data: mapNote(data) });
    }

    if (action === 'delete_note') {
      const noteId = asText(body.noteId);
      if (!noteId) {
        return fail(400, 'noteId is required');
      }

      const { data: existing, error: existingError } = await client
        .from('notes')
        .select('id, course_id, content_url')
        .eq('id', noteId)
        .maybeSingle();
      if (existingError) {
        return fail(400, existingError.message);
      }
      if (!existing) {
        return fail(404, 'Note not found');
      }

      const allowed = await canDeleteNote(client, existing.course_id, auth.userId);
      if (!allowed) {
        return fail(403, 'You are not allowed to delete this note');
      }

      const { error } = await client.from('notes').delete().eq('id', noteId);
      if (error) {
        return fail(400, error.message);
      }

      await client.storage.from('lecture-notes').remove([existing.content_url]);

      return json(200, { success: true, data: { removed: true } });
    }

    if (action === 'create_download_url') {
      const noteId = asText(body.noteId);
      if (!noteId) {
        return fail(400, 'noteId is required');
      }

      const { data: note, error: noteError } = await client
        .from('notes')
        .select('id, course_id, content_url')
        .eq('id', noteId)
        .maybeSingle();
      if (noteError) {
        return fail(400, noteError.message);
      }
      if (!note) {
        return fail(404, 'Note not found');
      }

      const allowed = await canReadCourse(client, note.course_id, auth.userId);
      if (!allowed) {
        return fail(403, 'You are not allowed to download this note');
      }

      const { data: signedData, error: signedError } = await client.storage
        .from('lecture-notes')
        .createSignedUrl(note.content_url, 60 * 30);
      if (signedError || !signedData?.signedUrl) {
        return fail(
          400,
          signedError?.message ?? 'Could not create signed URL for note',
        );
      }

      return json(200, {
        success: true,
        data: {
          downloadUrl: signedData.signedUrl,
          expiresInSeconds: 1800,
        },
      });
    }

    return fail(400, `Unsupported action: ${action}`);
  } catch (error) {
    const message = (error as Error)?.message ?? 'Bad request';
    const status = message.toLowerCase().includes('token') ? 401 : 400;
    return fail(status, message);
  }
});
