<<<<<<< Updated upstream
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type NotesAction = 'create_note' | 'list_notes' | 'update_note_title' | 'delete_note';

type NotesPayload = {
  action?: NotesAction;
  course_code?: string;
  title?: string;
  description?: string;
  content_url?: string;
  status?: string;
  search?: string;
  sort?: 'newest' | 'oldest' | 'title';
  note_id?: string;
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
  if (request.method !== 'POST') {
    return Response.json({ ok: false, error: 'Method not allowed.' }, { status: 405 });
=======
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
>>>>>>> Stashed changes
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
<<<<<<< Updated upstream
    return Response.json({ ok: false, error: 'Server not configured.' }, { status: 500 });
  }

  const token = extractBearerToken(request);
  if (token.length === 0) {
    return Response.json({ ok: false, error: 'Missing bearer token.' }, { status: 401 });
  }

  let payload: NotesPayload = {};
  try {
    payload = (await request.json()) as NotesPayload;
  } catch (_) {
    return badRequest('Invalid request body.');
=======
    throw new Error('Server not configured');
>>>>>>> Stashed changes
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
<<<<<<< Updated upstream
=======
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
>>>>>>> Stashed changes

  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser(token);

  if (userError || !user) {
<<<<<<< Updated upstream
    return Response.json({ ok: false, error: userError?.message ?? 'Invalid user session.' }, { status: 401 });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const action = payload.action;
  if (!action) {
    return badRequest('action is required.');
  }

  if (action === 'create_note') {
    const courseCode = (payload.course_code ?? '').trim().toUpperCase();
    const title = (payload.title ?? '').trim();
    const description = (payload.description ?? '').trim();
    const contentUrl = (payload.content_url ?? '').trim();
    const status = (payload.status ?? 'published').trim();

    if (courseCode.length === 0) {
      return badRequest('course_code is required.');
    }
    if (title.length === 0) {
      return badRequest('title is required.');
    }
    if (contentUrl.length === 0) {
      return badRequest('content_url is required.');
    }

    const { data, error } = await adminClient
      .from('notes')
      .insert({
        lecturer_id: user.id,
        course_code: courseCode,
        title,
        description,
        content_url: contentUrl,
        status,
      })
      .select('id, title, description, content_url, created_at')
      .single();

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    return Response.json(
      {
        ok: true,
        note: {
          ...data,
          uploaded_by_name: 'You',
        },
      },
      { status: 200 },
    );
  }

  if (action === 'list_notes') {
    const courseCode = (payload.course_code ?? '').trim().toUpperCase();
    const search = (payload.search ?? '').trim();
    const sort = payload.sort ?? 'newest';

    if (courseCode.length === 0) {
      return badRequest('course_code is required.');
    }

    let query = adminClient
      .from('notes')
      .select('id, title, description, content_url, created_at, profiles:lecturer_id(full_name)')
      .eq('course_code', courseCode);

    if (search.length > 0) {
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
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    const notes = (data ?? []).map((row: Record<string, unknown>) => {
      const profiles = (row['profiles'] as Record<string, unknown> | null) ?? null;
      return {
        id: row['id'],
        title: row['title'],
        description: row['description'],
        content_url: row['content_url'],
        created_at: row['created_at'],
        uploaded_by_name: (profiles?.['full_name'] as string | undefined) ?? 'Unknown',
      };
    });

    return Response.json({ ok: true, notes }, { status: 200 });
  }

  if (action === 'update_note_title') {
    const noteId = (payload.note_id ?? '').trim();
    const title = (payload.title ?? '').trim();

    if (noteId.length === 0 || title.length === 0) {
      return badRequest('note_id and title are required.');
    }

    const { error } = await adminClient
      .from('notes')
      .update({ title })
      .eq('id', noteId)
      .eq('lecturer_id', user.id);

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    return Response.json({ ok: true }, { status: 200 });
  }

  if (action === 'delete_note') {
    const noteId = (payload.note_id ?? '').trim();
    if (noteId.length === 0) {
      return badRequest('note_id is required.');
    }

    const { error } = await adminClient
      .from('notes')
      .delete()
      .eq('id', noteId)
      .eq('lecturer_id', user.id);

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    return Response.json({ ok: true }, { status: 200 });
  }

  return badRequest('Unsupported action.');
=======
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
    title: row.title,
    description: row.description ?? '',
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
    const body = await request.json();
    const action = asText(body?.action).toLowerCase();
    if (!action) {
      return fail(400, 'action is required');
    }

    const auth = await resolveAuth(request);
    const client = auth.serviceClient;

    if (action === 'create_note') {
      const courseId = asText(body.courseId);
      const title = asText(body.title);
      const description = asText(body.description);
      const contentUrl = assertStorageObjectPath(body.contentUrl);
      const fileName = asText(body.fileName);
      const fileSizeBytes = asInt(body.fileSizeBytes);

      if (!courseId || !title || !fileName) {
        return fail(400, 'courseId, title, and fileName are required');
      }

      const allowed = await canUploadNote(client, courseId, auth.userId);
      if (!allowed) {
        return fail(403, 'You are not allowed to upload notes for this course');
      }

      const { data, error } = await client
        .from('lecture_notes')
        .insert({
          course_id: courseId,
          title,
          description,
          content_url: contentUrl,
          file_name: fileName,
          file_size_bytes: Math.max(0, fileSizeBytes),
          uploaded_by: auth.userId,
        })
        .select('id, course_id, title, description, content_url, file_name, file_size_bytes, uploaded_by, created_at, updated_at, profiles:uploaded_by(full_name)')
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
        .from('lecture_notes')
        .select('id, course_id, title, description, content_url, file_name, file_size_bytes, uploaded_by, created_at, updated_at, profiles:uploaded_by(full_name)')
        .eq('course_id', courseId);

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

      const { data, error } = await client
        .from('lecture_notes')
        .select('id, course_id, title, description, content_url, file_name, file_size_bytes, uploaded_by, created_at, updated_at, profiles:uploaded_by(full_name)')
        .eq('id', noteId)
        .maybeSingle();
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

    if (action === 'update_note_title') {
      const noteId = asText(body.noteId);
      const title = asText(body.title);
      if (!noteId || !title) {
        return fail(400, 'noteId and title are required');
      }

      const { data: existing, error: existingError } = await client
        .from('lecture_notes')
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

      const { data, error } = await client
        .from('lecture_notes')
        .update({ title })
        .eq('id', noteId)
        .select('id, course_id, title, description, content_url, file_name, file_size_bytes, uploaded_by, created_at, updated_at, profiles:uploaded_by(full_name)')
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
        .from('lecture_notes')
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

      const { error } = await client.from('lecture_notes').delete().eq('id', noteId);
      if (error) {
        return fail(400, error.message);
      }

      // Best-effort storage cleanup.
      await client.storage.from('lecture-notes').remove([existing.content_url]);

      return json(200, { success: true, data: { removed: true } });
    }

    if (action === 'create_download_url') {
      const noteId = asText(body.noteId);
      if (!noteId) {
        return fail(400, 'noteId is required');
      }

      const { data: note, error: noteError } = await client
        .from('lecture_notes')
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
>>>>>>> Stashed changes
});

