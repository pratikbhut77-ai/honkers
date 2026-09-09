-- ============================================================
-- Honkers MVP Migration
-- Tables: honkers_users, honkers_questions, honkers_replies, honkers_seen_questions
-- ============================================================

-- 1. ENUM TYPES
DROP TYPE IF EXISTS public.honkers_question_status CASCADE;
CREATE TYPE public.honkers_question_status AS ENUM ('pending', 'approved', 'rejected');

-- 2. CORE TABLES

-- Honkers users (phone-number based, no Supabase Auth)
CREATE TABLE IF NOT EXISTS public.honkers_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL DEFAULT '',
  bio TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  community TEXT NOT NULL DEFAULT 'AhmedabadHonkers',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Questions
CREATE TABLE IF NOT EXISTS public.honkers_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.honkers_users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  details TEXT NOT NULL DEFAULT '',
  status public.honkers_question_status NOT NULL DEFAULT 'pending',
  photo_urls TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  community TEXT NOT NULL DEFAULT 'AhmedabadHonkers',
  reply_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Replies
CREATE TABLE IF NOT EXISTS public.honkers_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.honkers_questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.honkers_users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Seen questions (per-user tracking)
CREATE TABLE IF NOT EXISTS public.honkers_seen_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.honkers_users(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.honkers_questions(id) ON DELETE CASCADE,
  seen_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, question_id)
);

-- 3. INDEXES
CREATE INDEX IF NOT EXISTS idx_honkers_questions_user_id ON public.honkers_questions(user_id);
CREATE INDEX IF NOT EXISTS idx_honkers_questions_status ON public.honkers_questions(status);
CREATE INDEX IF NOT EXISTS idx_honkers_questions_created_at ON public.honkers_questions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_honkers_replies_question_id ON public.honkers_replies(question_id);
CREATE INDEX IF NOT EXISTS idx_honkers_replies_user_id ON public.honkers_replies(user_id);
CREATE INDEX IF NOT EXISTS idx_honkers_seen_user_id ON public.honkers_seen_questions(user_id);
CREATE INDEX IF NOT EXISTS idx_honkers_seen_question_id ON public.honkers_seen_questions(question_id);

-- 4. FUNCTIONS

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.honkers_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Auto-update reply_count on honkers_questions
CREATE OR REPLACE FUNCTION public.honkers_update_reply_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.honkers_questions
    SET reply_count = reply_count + 1
    WHERE id = NEW.question_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.honkers_questions
    SET reply_count = GREATEST(reply_count - 1, 0)
    WHERE id = OLD.question_id;
  END IF;
  RETURN NULL;
END;
$$;

-- 5. ENABLE RLS
ALTER TABLE public.honkers_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.honkers_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.honkers_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.honkers_seen_questions ENABLE ROW LEVEL SECURITY;

-- 6. RLS POLICIES (open access — phone-based auth, no Supabase Auth JWT)

DROP POLICY IF EXISTS "honkers_users_open" ON public.honkers_users;
CREATE POLICY "honkers_users_open"
ON public.honkers_users FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "honkers_questions_open" ON public.honkers_questions;
CREATE POLICY "honkers_questions_open"
ON public.honkers_questions FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "honkers_replies_open" ON public.honkers_replies;
CREATE POLICY "honkers_replies_open"
ON public.honkers_replies FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "honkers_seen_open" ON public.honkers_seen_questions;
CREATE POLICY "honkers_seen_open"
ON public.honkers_seen_questions FOR ALL TO public USING (true) WITH CHECK (true);

-- 7. TRIGGERS

DROP TRIGGER IF EXISTS honkers_users_updated_at ON public.honkers_users;
CREATE TRIGGER honkers_users_updated_at
  BEFORE UPDATE ON public.honkers_users
  FOR EACH ROW EXECUTE FUNCTION public.honkers_set_updated_at();

DROP TRIGGER IF EXISTS honkers_questions_updated_at ON public.honkers_questions;
CREATE TRIGGER honkers_questions_updated_at
  BEFORE UPDATE ON public.honkers_questions
  FOR EACH ROW EXECUTE FUNCTION public.honkers_set_updated_at();

DROP TRIGGER IF EXISTS honkers_replies_updated_at ON public.honkers_replies;
CREATE TRIGGER honkers_replies_updated_at
  BEFORE UPDATE ON public.honkers_replies
  FOR EACH ROW EXECUTE FUNCTION public.honkers_set_updated_at();

DROP TRIGGER IF EXISTS honkers_replies_count_insert ON public.honkers_replies;
CREATE TRIGGER honkers_replies_count_insert
  AFTER INSERT ON public.honkers_replies
  FOR EACH ROW EXECUTE FUNCTION public.honkers_update_reply_count();

DROP TRIGGER IF EXISTS honkers_replies_count_delete ON public.honkers_replies;
CREATE TRIGGER honkers_replies_count_delete
  AFTER DELETE ON public.honkers_replies
  FOR EACH ROW EXECUTE FUNCTION public.honkers_update_reply_count();

-- 8. MOCK DATA
DO $$
DECLARE
  user1_id UUID := gen_random_uuid();
  user2_id UUID := gen_random_uuid();
  user3_id UUID := gen_random_uuid();
  user4_id UUID := gen_random_uuid();
  user5_id UUID := gen_random_uuid();
  q1_id UUID := gen_random_uuid();
  q2_id UUID := gen_random_uuid();
  q3_id UUID := gen_random_uuid();
  q4_id UUID := gen_random_uuid();
  q5_id UUID := gen_random_uuid();
  q6_id UUID := gen_random_uuid();
BEGIN
  -- Users
  INSERT INTO public.honkers_users (id, phone, full_name, bio, avatar_url)
  VALUES
    (user1_id, '9876543210', 'Priya Desai', 'Ahmedabad local. Foodie. Love discovering hidden gems in the city.', 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=200'),
    (user2_id, '9876543211', 'Mihir Shah', 'Small business owner in Ahmedabad.', 'https://img.rocket.new/generatedImages/rocket_gen_img_114a0b323-1763293803610.png'),
    (user3_id, '9876543212', 'Ruchita Patel', 'Ahmedabad explorer and community helper.', 'https://images.unsplash.com/photo-1590189560762-bac17bed589e'),
    (user4_id, '9876543213', 'Arjun Mehta', 'Tech enthusiast from Ahmedabad.', 'https://images.unsplash.com/photo-1635789531654-8d0404549bfe'),
    (user5_id, '9876543214', 'Kavita Joshi', 'Parent and educator in Ahmedabad.', 'https://img.rocket.new/generatedImages/rocket_gen_img_1ccfe0794-1772147307895.png')
  ON CONFLICT (phone) DO NOTHING;

  -- Questions
  INSERT INTO public.honkers_questions (id, user_id, title, details, status, reply_count)
  VALUES
    (q1_id, user1_id, 'Best misal pav in Navrangpura area?', 'Looking for authentic Ahmedabadi misal, preferably open on weekday mornings.', 'approved', 0),
    (q2_id, user2_id, 'Which CA firm is good for GST filing near SG Highway?', 'Small business owner, need help with monthly GST returns. Budget under Rs 2000/month.', 'approved', 0),
    (q3_id, user3_id, 'Is Riverfront park open on Sunday evenings?', 'Planning a family outing this weekend. Any parking tips welcome.', 'approved', 0),
    (q4_id, user4_id, 'Good dentist near Bopal for root canal?', 'Need an affordable but experienced dentist. Emergency visit.', 'approved', 0),
    (q5_id, user5_id, 'Any Gujarati tuition classes for Class 10 in Satellite?', 'My daughter needs extra help with Gujarati grammar.', 'pending', 0),
    (q6_id, user1_id, 'Best place to buy organic vegetables in Ahmedabad?', 'Prefer home delivery but open to weekly market visits too.', 'approved', 0)
  ON CONFLICT (id) DO NOTHING;

  -- Replies for q1
  INSERT INTO public.honkers_replies (question_id, user_id, text)
  VALUES
    (q1_id, user2_id, 'Try Shyam Misal on Stadium Circle road — they open at 7 AM and the misal is absolutely fantastic!'),
    (q1_id, user3_id, 'Laxmi Misal near Navrangpura crossroads is also great. Open from 8 AM. Ask for extra sev.'),
    (q1_id, user4_id, 'Honestly, the one inside Gujarat College campus canteen is underrated. Very affordable too.')
  ON CONFLICT (id) DO NOTHING;

  -- Replies for q2
  INSERT INTO public.honkers_replies (question_id, user_id, text)
  VALUES
    (q2_id, user3_id, 'Try Mehta and Associates near Prahlad Nagar — very professional and affordable.'),
    (q2_id, user5_id, 'I use CA Sharma near Iscon. Good for small businesses.')
  ON CONFLICT (id) DO NOTHING;

  -- Replies for q3
  INSERT INTO public.honkers_replies (question_id, user_id, text)
  VALUES
    (q3_id, user2_id, 'Yes, Riverfront is open till 10 PM on Sundays. Parking is available near the east gate.'),
    (q3_id, user4_id, 'Go early evening around 5-6 PM for the best experience. Not too crowded then.')
  ON CONFLICT (id) DO NOTHING;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;
