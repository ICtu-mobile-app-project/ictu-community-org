-- Rename lecture_notes to notes if it exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'lecture_notes') AND
       NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notes') THEN
        ALTER TABLE public.lecture_notes RENAME TO notes;
    END IF;
END $$;

-- Add summary and status columns to notes
ALTER TABLE public.notes
ADD COLUMN IF NOT EXISTS summary TEXT,
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'draft';

-- Add course_code column to notes if it doesn't exist
-- (Some migrations seem to use course_code for joins)
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS course_code TEXT;

-- Populate course_code from courses table if it's null
UPDATE public.notes n
SET course_code = c.course_code
FROM public.courses c
WHERE n.course_id = c.id AND n.course_code IS NULL;

-- Update description to be optional (it was NOT NULL DEFAULT '')
ALTER TABLE public.notes ALTER COLUMN description DROP NOT NULL;

-- Ensure status is one of the allowed values
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notes_status_check') THEN
        ALTER TABLE public.notes ADD CONSTRAINT notes_status_check CHECK (status IN ('draft', 'published'));
    END IF;
END $$;

-- Update RLS policies for students to only see published notes
DROP POLICY IF EXISTS "lecture_notes_select_course_members" ON public.notes;
CREATE POLICY "notes_select_course_members"
ON public.notes
FOR SELECT
USING (
  (
    -- Lecturer owner sees everything
    EXISTS (
      SELECT 1 FROM public.courses c
      WHERE c.id = notes.course_id AND c.lecturer_id = auth.uid()
    )
    -- Delegates with specific permissions see everything
    OR EXISTS (
      SELECT 1 FROM public.course_delegates cd
      WHERE cd.course_id = notes.course_id AND cd.student_id = auth.uid()
    )
  )
  OR (
    -- Students and regular course members only see published notes
    status = 'published' AND
    EXISTS (
      SELECT 1 FROM public.course_enrollments ce
      WHERE ce.course_id = notes.course_id AND ce.student_id = auth.uid()
    )
  )
);

-- Update other policies to use the new name (Postgres usually handles this, but let's be explicit if needed)
-- Standard practice is to rename them for clarity.

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
