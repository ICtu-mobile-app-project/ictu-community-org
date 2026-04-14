import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type AlertsAction =
  | 'create_alert'
  | 'list_alerts'
  | 'get_alert'
  | 'update_alert'
  | 'delete_alert';

type AlertsPayload = {
  action?: AlertsAction;
  alert_id?: string;
  title?: string;
  description?: string;
  type?: 'assignment' | 'ca' | 'exam' | 'notice';
  course_code?: string;
  deadline?: string;
  requirements?: string[];
  search?: string;
  sort?: 'deadline' | 'created';
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

  let payload: AlertsPayload = {};
  try {
    payload = (await request.json()) as AlertsPayload;
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
    return Response.json(
      { ok: false, error: userError?.message ?? 'Invalid user session.' },
      { status: 401 },
    );
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const action = payload.action;
  if (!action) {
    return badRequest('action is required.');
  }

  if (action === 'create_alert') {
    const title = (payload.title ?? '').trim();
    const description = (payload.description ?? '').trim();
    const type = payload.type ?? 'notice';
    const courseCode = (payload.course_code ?? '').trim().toUpperCase();
    const deadline = (payload.deadline ?? '').trim();
    const requirements = Array.isArray(payload.requirements)
      ? payload.requirements.map((item) => item.toString().trim()).filter((item) => item.length > 0)
      : [];

    if (title.length === 0) {
      return badRequest('title is required.');
    }
    if (description.length === 0) {
      return badRequest('description is required.');
    }
    if (courseCode.length === 0) {
      return badRequest('course_code is required.');
    }

    const { data, error } = await adminClient
      .from('alerts')
      .insert({
        lecturer_id: user.id,
        title,
        description,
        type,
        deadline: deadline.length > 0 ? deadline : null,
        course_code: courseCode,
        requirements,
      })
      .select('id, title, description, type, course_code, deadline, requirements, created_at')
      .single();

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    // Future push notification integration point.
    return Response.json({ ok: true, alert: data }, { status: 200 });
  }

  if (action === 'list_alerts') {
    const courseCode = (payload.course_code ?? '').trim().toUpperCase();
    const type = (payload.type ?? '').trim();
    const search = (payload.search ?? '').trim();
    const sort = payload.sort ?? 'deadline';
    const page = Math.max(0, Number(payload.page ?? 0));
    const limit = Math.max(1, Math.min(50, Number(payload.limit ?? 20)));

    let query = adminClient
      .from('alerts')
      .select('id, title, description, type, course_code, deadline, requirements, created_at')
      .eq('lecturer_id', user.id)
      .range(page * limit, page * limit + limit - 1);

    if (courseCode.length > 0) {
      query = query.eq('course_code', courseCode);
    }

    if (type.length > 0) {
      query = query.eq('type', type);
    }

    if (search.length > 0) {
      query = query.or(`title.ilike.%${search}%,course_code.ilike.%${search}%`);
    }

    if (sort === 'created') {
      query = query.order('created_at', { ascending: false });
    } else {
      query = query.order('deadline', { ascending: true, nullsFirst: false });
    }

    const { data, error } = await query;

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    return Response.json({ ok: true, alerts: data ?? [] }, { status: 200 });
  }

  if (action === 'get_alert') {
    const alertId = (payload.alert_id ?? '').trim();
    if (alertId.length === 0) {
      return badRequest('alert_id is required.');
    }

    const { data, error } = await adminClient
      .from('alerts')
      .select('id, title, description, type, course_code, deadline, requirements, created_at')
      .eq('id', alertId)
      .eq('lecturer_id', user.id)
      .single();

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    return Response.json({ ok: true, alert: data }, { status: 200 });
  }

  if (action === 'update_alert') {
    const alertId = (payload.alert_id ?? '').trim();
    if (alertId.length === 0) {
      return badRequest('alert_id is required.');
    }

    const updates: Record<string, unknown> = {};
    if (typeof payload.title === 'string' && payload.title.trim().length > 0) {
      updates.title = payload.title.trim();
    }
    if (typeof payload.description === 'string' && payload.description.trim().length > 0) {
      updates.description = payload.description.trim();
    }
    if (typeof payload.deadline === 'string') {
      updates.deadline = payload.deadline.trim().length > 0 ? payload.deadline : null;
    }

    if (Object.keys(updates).length === 0) {
      return badRequest('No update fields provided.');
    }

    const { error } = await adminClient
      .from('alerts')
      .update(updates)
      .eq('id', alertId)
      .eq('lecturer_id', user.id);

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    return Response.json({ ok: true }, { status: 200 });
  }

  if (action === 'delete_alert') {
    const alertId = (payload.alert_id ?? '').trim();
    if (alertId.length === 0) {
      return badRequest('alert_id is required.');
    }

    const { error } = await adminClient
      .from('alerts')
      .delete()
      .eq('id', alertId)
      .eq('lecturer_id', user.id);

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 });
    }

    return Response.json({ ok: true }, { status: 200 });
  }

  return badRequest('Unsupported action.');
});

