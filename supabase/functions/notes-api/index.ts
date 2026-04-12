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

  let payload: NotesPayload = {};
  try {
    payload = (await request.json()) as NotesPayload;
  } catch (_) {
    return badRequest('Invalid request body.');
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser(token);

  if (userError || !user) {
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
});

