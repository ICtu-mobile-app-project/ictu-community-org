/// <reference lib="deno.ns" />
// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function assertStorageObjectPath(value: unknown): string {
  if (typeof value !== 'string') {
    throw new Error('audioUrl must be a string storage object path');
  }

  const raw = value.trim();
  if (!raw) {
    throw new Error('audioUrl is required');
  }

  let v = raw.replace(/^\/+/, '');
  v = v.replace(/^lecture-audio\//i, '');

  if (/^https?:\/\//i.test(v) || v.startsWith('gs://')) {
    throw new Error(
      'audioUrl must be a Supabase Storage object path (e.g. "lectures/abc.mp3"), not a full URL',
    );
  }

  if (v.includes('..') || v.includes('\\')) {
    throw new Error('Invalid audioUrl path');
  }

  return v;
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function guessAudioMimeType(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith('.mp3')) return 'audio/mpeg';
  if (lower.endsWith('.m4a') || lower.endsWith('.mp4')) return 'audio/mp4';
  if (lower.endsWith('.wav')) return 'audio/wav';
  if (lower.endsWith('.aac')) return 'audio/aac';
  if (lower.endsWith('.ogg')) return 'audio/ogg';
  return 'application/octet-stream';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }

  try {
    const body = await req.json();
    const audioUrl = assertStorageObjectPath(body.audioUrl);
    const lectureId = body.lectureId;

    if (!lectureId) {
      throw new Error('lectureId is required');
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    if (!serviceRoleKey) {
      throw new Error('SUPABASE_SERVICE_ROLE_KEY not configured');
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const gladiaApiKey = Deno.env.get('GLADIA_API_KEY');
    if (!gladiaApiKey) {
      throw new Error('GLADIA_API_KEY not configured');
    }

    const gladiaBaseUrl = (
      Deno.env.get('GLADIA_BASE_URL') || 'https://api.gladia.io/v2'
    ).replace(/\/+$/, '');
    const pollIntervalMs = Number.parseInt(
      Deno.env.get('GLADIA_POLL_INTERVAL_MS') || '2500',
      10,
    );
    const timeoutMs = Number.parseInt(
      Deno.env.get('GLADIA_TIMEOUT_MS') || '180000',
      10,
    );

    let audioData: Blob | null = null;
    let lastDownloadError: any = null;

    for (let attempt = 1; attempt <= 3; attempt += 1) {
      const { data, error } = await supabase.storage
        .from('lecture-audio')
        .download(audioUrl);

      if (!error && data) {
        audioData = data;
        lastDownloadError = null;
        break;
      }

      lastDownloadError = error;
      await sleep(350 * attempt);
    }

    if (!audioData) {
      throw new Error(
        `Download failed: ${lastDownloadError?.message ?? lastDownloadError ?? 'Object not found'} (bucket=lecture-audio, path=${audioUrl})`,
      );
    }

    const { data: signedData, error: signedError } = await supabase.storage
      .from('lecture-audio')
      .createSignedUrl(audioUrl, 60 * 30);

    if (signedError || !signedData?.signedUrl) {
      throw new Error(
        `Could not create signed URL for transcription: ${signedError?.message ?? 'unknown error'}`,
      );
    }

    const signedAudioUrl = signedData.signedUrl;
    const inferredMimeType = guessAudioMimeType(audioUrl);

    const gladiaHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      'x-gladia-key': gladiaApiKey,
    };

    const richPayload = {
      audio_url: signedAudioUrl,
      diarization: true,
      sentiment_analysis: true,
      named_entity_recognition: true,
      language_config: { detect_language: true },
    };

    let submitResp = await fetch(`${gladiaBaseUrl}/pre-recorded`, {
      method: 'POST',
      headers: gladiaHeaders,
      body: JSON.stringify(richPayload),
    });

    if (!submitResp.ok) {
      submitResp = await fetch(`${gladiaBaseUrl}/pre-recorded`, {
        method: 'POST',
        headers: gladiaHeaders,
        body: JSON.stringify({ audio_url: signedAudioUrl }),
      });
    }

    if (!submitResp.ok) {
      const errTxt = await submitResp.text();
      throw new Error(`Gladia submit failed: ${errTxt}`);
    }

    const submitJson = await submitResp.json();
    const jobId = String(
      submitJson?.id ??
        submitJson?.job_id ??
        submitJson?.result?.id ??
        submitJson?.prediction_id ??
        '',
    ).trim();
    const resultUrl = (submitJson?.result_url as string | undefined)?.trim();

    let gladiaResultPayload: any = null;
    const initialStatus = String(
      submitJson?.status ?? submitJson?.result?.status ?? '',
    ).toLowerCase();
    if (
      initialStatus === 'done' ||
      initialStatus === 'completed' ||
      initialStatus === 'finished'
    ) {
      gladiaResultPayload = submitJson;
    }

    if (!gladiaResultPayload) {
      if (!jobId && !resultUrl) {
        throw new Error('Gladia submit did not return a job id or result URL');
      }

      const pollStart = Date.now();
      while (Date.now() - pollStart < timeoutMs) {
        const pollUrl =
          resultUrl && /^https?:\/\//i.test(resultUrl)
            ? resultUrl
            : `${gladiaBaseUrl}/pre-recorded/${jobId}`;

        const pollResp = await fetch(pollUrl, {
          method: 'GET',
          headers: { 'x-gladia-key': gladiaApiKey },
        });

        if (!pollResp.ok) {
          const pollErr = await pollResp.text();
          throw new Error(`Gladia polling failed: ${pollErr}`);
        }

        const pollJson = await pollResp.json();
        const status = String(
          pollJson?.status ??
            pollJson?.result?.status ??
            pollJson?.transcription?.status ??
            '',
        ).toLowerCase();

        if (
          status === 'done' ||
          status === 'completed' ||
          status === 'finished' ||
          status === 'succeeded'
        ) {
          gladiaResultPayload = pollJson;
          break;
        }

        if (
          status === 'error' ||
          status === 'failed' ||
          status === 'canceled' ||
          status === 'cancelled'
        ) {
          throw new Error(
            `Gladia job failed with status=${status}: ${pollJson?.error ?? pollJson?.message ?? 'unknown'}`,
          );
        }

        await sleep(pollIntervalMs);
      }
    }

    if (!gladiaResultPayload) {
      throw new Error(`Gladia transcription timeout after ${timeoutMs}ms`);
    }

    const candidateTranscript =
      gladiaResultPayload?.result?.transcription?.full_transcript ??
      gladiaResultPayload?.result?.transcription?.text ??
      gladiaResultPayload?.result?.text ??
      gladiaResultPayload?.transcription?.full_transcript ??
      gladiaResultPayload?.transcription?.text ??
      gladiaResultPayload?.text;

    const utterances =
      gladiaResultPayload?.result?.transcription?.utterances ??
      gladiaResultPayload?.transcription?.utterances ??
      gladiaResultPayload?.utterances ??
      [];

    const transcript =
      typeof candidateTranscript === 'string' &&
      candidateTranscript.trim().length > 0
        ? candidateTranscript.trim()
        : Array.isArray(utterances)
          ? utterances
              .map((u: any) => (u?.text ?? '').toString().trim())
              .filter((s: string) => s.length > 0)
              .join(' ')
          : '';

    if (!transcript) {
      throw new Error('Gladia response was missing transcript text');
    }

    const firstSentence =
      transcript
        .split(/[.!?]/)
        .map((s: string) => s.trim())
        .find((s: string) => s.length > 0) ?? '';
    const title = firstSentence
      ? firstSentence.split(/\s+/).slice(0, 8).join(' ')
      : 'Lecture Transcription';

    const summaryFromProvider =
      gladiaResultPayload?.result?.summary ?? gladiaResultPayload?.summary;
    const summary =
      typeof summaryFromProvider === 'string' &&
      summaryFromProvider.trim().length > 0
        ? summaryFromProvider.trim()
        : transcript.length > 320
          ? `${transcript.slice(0, 317)}...`
          : transcript;

    const keyPointsFromProvider =
      gladiaResultPayload?.result?.key_points ??
      gladiaResultPayload?.key_points ??
      [];

    const result = {
      title,
      summary,
      key_points: Array.isArray(keyPointsFromProvider)
        ? keyPointsFromProvider
            .map((x: any) => String(x))
            .filter((x: string) => x.trim().length > 0)
            .slice(0, 8)
        : [],
      assignments_and_assessments: {
        assignments: [],
        cas: [],
      },
      action_items_for_students: [],
      previous_topics_mentioned: [],
      full_transcript: transcript,
    };

    const { error: updateError } = await supabase
      .from('lectures')
      .update({
        transcription: result.full_transcript,
        summary: result.summary,
        transcription_result: result,
        status: 'completed',
        processed_at: new Date().toISOString(),
      })
      .eq('id', lectureId);

    if (updateError) {
      await supabase
        .from('lectures')
        .update({
          status: 'failed',
          error_message: updateError.message,
        })
        .eq('id', lectureId);

      throw new Error(`Database update failed: ${updateError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Audio transcribed successfully',
        data: {
          transcription: result.full_transcript,
          summary: result.summary,
          transcription_result: result,
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: (error as Error)?.message ?? 'Bad request',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    );
  }
});
