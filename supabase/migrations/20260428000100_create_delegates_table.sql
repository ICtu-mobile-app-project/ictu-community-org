-- Create Delegates table to link students to courses with specific permissions

CREATE TABLE IF NOT EXISTS public.course_delegates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    can_upload_notes BOOLEAN DEFAULT TRUE,
    can_edit_notes BOOLEAN DEFAULT FALSE,
    can_delete_notes BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(course_id, student_id)
);

-- Enable RLS
ALTER TABLE public.course_delegates ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
    CREATE POLICY "Delegates are viewable by authenticated users"
    ON public.course_delegates FOR SELECT TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Only course lecturers can manage delegates
DO $$ BEGIN
    CREATE POLICY "Lecturers can manage their course delegates"
    ON public.course_delegates FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.courses
            WHERE id = course_delegates.course_id
            AND lecturer_id = auth.uid()
        )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_course_delegates_course_id ON public.course_delegates(course_id);
CREATE INDEX IF NOT EXISTS idx_course_delegates_student_id ON public.course_delegates(student_id);
