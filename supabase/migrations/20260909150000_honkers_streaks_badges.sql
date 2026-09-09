-- ============================================================
-- Honkers Streaks & Badges Migration
-- Adds: honkers_activity_log, honkers_user_badges
-- Computes streaks from activity log, badges from milestones
-- ============================================================

-- 1. Activity log — one row per user per day they were active
CREATE TABLE IF NOT EXISTS public.honkers_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.honkers_users(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE(user_id, activity_date)
);

CREATE INDEX IF NOT EXISTS idx_honkers_activity_user_date
  ON public.honkers_activity_log(user_id, activity_date DESC);

-- 2. User badges table
CREATE TABLE IF NOT EXISTS public.honkers_user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.honkers_users(id) ON DELETE CASCADE,
  badge_key TEXT NOT NULL,
  badge_label TEXT NOT NULL,
  badge_icon TEXT NOT NULL DEFAULT 'star',
  earned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, badge_key)
);

CREATE INDEX IF NOT EXISTS idx_honkers_badges_user_id
  ON public.honkers_user_badges(user_id);

-- 3. RLS
ALTER TABLE public.honkers_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.honkers_user_badges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "honkers_activity_open" ON public.honkers_activity_log;
CREATE POLICY "honkers_activity_open"
ON public.honkers_activity_log FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "honkers_badges_open" ON public.honkers_user_badges;
CREATE POLICY "honkers_badges_open"
ON public.honkers_user_badges FOR ALL TO public USING (true) WITH CHECK (true);

-- 4. Function: record activity and auto-award badges
CREATE OR REPLACE FUNCTION public.honkers_record_activity(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_reply_count INTEGER;
  v_approved_count INTEGER;
  v_streak INTEGER;
BEGIN
  -- Upsert today's activity
  INSERT INTO public.honkers_activity_log(user_id, activity_date)
  VALUES (p_user_id, CURRENT_DATE)
  ON CONFLICT (user_id, activity_date) DO NOTHING;

  -- Compute current streak (consecutive days ending today or yesterday)
  SELECT COUNT(*)::INTEGER INTO v_streak
  FROM (
    SELECT activity_date,
           activity_date - (ROW_NUMBER() OVER (ORDER BY activity_date DESC))::INTEGER AS grp
    FROM public.honkers_activity_log
    WHERE user_id = p_user_id
      AND activity_date >= CURRENT_DATE - INTERVAL '365 days'
  ) t
  WHERE grp = (
    SELECT activity_date - (ROW_NUMBER() OVER (ORDER BY activity_date DESC))::INTEGER
    FROM public.honkers_activity_log
    WHERE user_id = p_user_id
    ORDER BY activity_date DESC
    LIMIT 1
  );

  -- Reply count for milestone badges
  SELECT COUNT(*)::INTEGER INTO v_reply_count
  FROM public.honkers_replies
  WHERE user_id = p_user_id;

  -- Approved question count for approval badges
  SELECT COUNT(*)::INTEGER INTO v_approved_count
  FROM public.honkers_questions
  WHERE user_id = p_user_id AND status = 'approved';

  -- Streak badges
  IF v_streak >= 3 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'streak_3', '3-Day Streak', 'local_fire_department')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;
  IF v_streak >= 7 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'streak_7', '7-Day Streak', 'local_fire_department')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;
  IF v_streak >= 30 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'streak_30', '30-Day Streak', 'local_fire_department')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;

  -- Reply milestone badges
  IF v_reply_count >= 1 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'reply_1', 'First Reply', 'chat_bubble')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;
  IF v_reply_count >= 10 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'reply_10', '10 Replies', 'chat_bubble')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;
  IF v_reply_count >= 50 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'reply_50', '50 Replies', 'chat_bubble')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;

  -- Approval badges
  IF v_approved_count >= 1 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'approved_1', 'First Approval', 'verified')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;
  IF v_approved_count >= 5 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'approved_5', '5 Approvals', 'verified')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;
  IF v_approved_count >= 10 THEN
    INSERT INTO public.honkers_user_badges(user_id, badge_key, badge_label, badge_icon)
    VALUES (p_user_id, 'approved_10', 'Trusted Voice', 'verified')
    ON CONFLICT (user_id, badge_key) DO NOTHING;
  END IF;
END;
$$;
