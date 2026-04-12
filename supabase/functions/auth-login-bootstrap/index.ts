import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SCHOOL_DOMAIN = '@ictuniversity.edu.cm';

function isSchoolEmail(email: string): boolean {
  return email.toLowerCase().endsWith(SCHOOL_DOMAIN);
}

type LoginBootstrapPayload = {
  user_id?: string;
  access_token?: string;
};

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed.' }, { status: 405 });
  }

  let payload: LoginBootstrapPayload = {};
  try {
    payload = (await request.json()) as LoginBootstrapPayload;
  } catch (_) {
    payload = {};
  }

  const authHeader = request.headers.get('Authorization');
  const tokenFromHeader = authHeader?.startsWith('Bearer ')
    ? authHeader.replace('Bearer ', '').trim()
    : '';
  const tokenFromBody =
      typeof payload.access_token == 'string' ? payload.access_token.trim() : '';
  const token = tokenFromHeader.length > 0 ? tokenFromHeader : tokenFromBody;

  if (token.length === 0) {
    return Response.json({ error: 'Missing bearer token.' }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return Response.json({ error: 'Server not configured.' }, { status: 500 });
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
      {
        error: userError?.message ?? 'Invalid user session.',
      },
      { status: 401 },
    );
  }

  if (payload.user_id && payload.user_id !== user.id) {
    return Response.json({ error: 'User mismatch.' }, { status: 403 });
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
    .select('role, full_name')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError && profileError.code !== 'PGRST116') {
    return Response.json({ error: profileError.message }, { status: 400 });
  }

  const userMetadata = user.user_metadata as
    | Record<string, unknown>
    | null
    | undefined;
  const fallbackName =
    typeof userMetadata?.['full_name'] === 'string'
      ? (userMetadata['full_name'] as string)
      : null;
  const resolvedRole =
    typeof profile?.role === 'string' && profile.role.trim().length > 0
      ? profile.role
      : 'student';

  return Response.json(
    {
      role: resolvedRole,
      full_name: profile?.full_name ?? fallbackName,
    },
    { status: 200 },
  );
});

