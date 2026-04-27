-- 1. Create alerts table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_code TEXT NOT NULL REFERENCES public.courses(course_code) ON DELETE CASCADE,
    lecturer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT DEFAULT 'announcement',
    deadline TIMESTAMPTZ,
    requirements JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Ensure notes has the correct FK to courses using course_code
-- This aligns with your current schema where notes uses course_code
DO $$
BEGIN
    -- Remove old FKs if they exist to avoid conflicts
    ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS lecture_notes_course_id_fkey;
    ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS notes_course_id_fkey;

    -- Ensure the FK to courses(course_code) exists
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notes_course_code_fkey') THEN
        ALTER TABLE public.notes
        ADD CONSTRAINT notes_course_code_fkey
        FOREIGN KEY (course_code)
        REFERENCES public.courses(course_code)
        ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
