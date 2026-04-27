-- Add Foreign Key constraints for notes and alerts to enable auto-joins in PostgREST

-- 1. Ensure courses(course_code) has a UNIQUE constraint (required for FK reference)
-- This might already exist, but we ensure it here.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'courses_course_code_key'
    ) THEN
        ALTER TABLE public.courses ADD CONSTRAINT courses_course_code_key UNIQUE (course_code);
    END IF;
END $$;

-- 2. Add FK to notes table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'notes_course_code_fkey'
    ) THEN
        ALTER TABLE public.notes
        ADD CONSTRAINT notes_course_code_fkey
        FOREIGN KEY (course_code)
        REFERENCES public.courses(course_code)
        ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Add FK to alerts table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'alerts_course_code_fkey'
    ) THEN
        ALTER TABLE public.alerts
        ADD CONSTRAINT alerts_course_code_fkey
        FOREIGN KEY (course_code)
        REFERENCES public.courses(course_code)
        ON DELETE CASCADE;
    END IF;
END $$;

-- 4. Verify/Add indexes for join performance
CREATE INDEX IF NOT EXISTS idx_notes_course_code ON public.notes(course_code);
CREATE INDEX IF NOT EXISTS idx_alerts_course_code ON public.alerts(course_code);
