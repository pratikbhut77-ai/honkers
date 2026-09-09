-- Notification preferences per user
CREATE TABLE IF NOT EXISTS public.honkers_notification_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.honkers_users(id) ON DELETE CASCADE,
  notify_replies boolean NOT NULL DEFAULT true,
  notify_mentions boolean NOT NULL DEFAULT true,
  notify_badges boolean NOT NULL DEFAULT true,
  quiet_hours_enabled boolean NOT NULL DEFAULT false,
  quiet_start_hour integer NOT NULL DEFAULT 22 CHECK (quiet_start_hour >= 0 AND quiet_start_hour <= 23),
  quiet_end_hour integer NOT NULL DEFAULT 8 CHECK (quiet_end_hour >= 0 AND quiet_end_hour <= 23),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);

-- RLS
ALTER TABLE public.honkers_notification_preferences ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'honkers_notification_preferences'
      AND policyname = 'Users can manage own notification preferences'
  ) THEN
    CREATE POLICY "Users can manage own notification preferences"
      ON public.honkers_notification_preferences
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
