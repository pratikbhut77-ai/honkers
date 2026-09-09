-- ─── honkers_reports table ────────────────────────────────────────────────
-- Stores community reports for inappropriate questions or replies.

CREATE TABLE IF NOT EXISTS public.honkers_reports (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   UUID NOT NULL REFERENCES public.honkers_users(id) ON DELETE CASCADE,
  content_type  TEXT NOT NULL CHECK (content_type IN ('question', 'reply')),
  content_id    UUID NOT NULL,
  reason        TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  admin_note    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at   TIMESTAMPTZ
);

-- Index for fast lookups by content
CREATE INDEX IF NOT EXISTS idx_honkers_reports_content
  ON public.honkers_reports (content_type, content_id);

CREATE INDEX IF NOT EXISTS idx_honkers_reports_status
  ON public.honkers_reports (status);

-- RLS
ALTER TABLE public.honkers_reports ENABLE ROW LEVEL SECURITY;

-- Anyone can insert a report (authenticated via app)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'honkers_reports' AND policyname = 'honkers_reports_insert'
  ) THEN
    CREATE POLICY honkers_reports_insert ON public.honkers_reports
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

-- Anyone can read reports (admin screen reads them)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'honkers_reports' AND policyname = 'honkers_reports_select'
  ) THEN
    CREATE POLICY honkers_reports_select ON public.honkers_reports
      FOR SELECT USING (true);
  END IF;
END $$;

-- Anyone can update reports (admin actions)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'honkers_reports' AND policyname = 'honkers_reports_update'
  ) THEN
    CREATE POLICY honkers_reports_update ON public.honkers_reports
      FOR UPDATE USING (true);
  END IF;
END $$;

-- Anyone can delete reports (admin dismiss/cleanup)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'honkers_reports' AND policyname = 'honkers_reports_delete'
  ) THEN
    CREATE POLICY honkers_reports_delete ON public.honkers_reports
      FOR DELETE USING (true);
  END IF;
END $$;
