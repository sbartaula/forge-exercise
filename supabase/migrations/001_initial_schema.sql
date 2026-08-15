-- FORGE Training OS — initial schema
-- Run against a Supabase Postgres project (Auth must already be enabled).

-- ============================================================================
-- TABLES
-- ============================================================================

-- User profile and targets
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  weight_kg DECIMAL,
  height_cm INTEGER,
  body_fat_pct DECIMAL,
  lean_mass_kg DECIMAL,
  bmr INTEGER,
  start_date DATE,
  -- Calorie targets per day type
  target_kcal_gym INTEGER DEFAULT 1900,
  target_kcal_football INTEGER DEFAULT 1950,
  target_kcal_gymfootball INTEGER DEFAULT 2100,
  target_kcal_rest INTEGER DEFAULT 1650,
  -- Macro targets (grams)
  target_protein_g INTEGER DEFAULT 155,
  target_carbs_g INTEGER DEFAULT 180,
  target_fat_g INTEGER DEFAULT 52,
  -- Push notification subscription
  push_subscription JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Food library
CREATE TABLE foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  brand TEXT,
  -- All values per 100g
  protein_per_100g DECIMAL NOT NULL,
  carbs_per_100g DECIMAL NOT NULL,
  fat_per_100g DECIMAL NOT NULL,
  kcal_per_100g DECIMAL NOT NULL,
  -- Serving info (optional)
  serving_size_g DECIMAL,
  serving_name TEXT, -- e.g. "1 scoop", "1 slice"
  is_preloaded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily food log
CREATE TABLE food_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  meal_slot TEXT NOT NULL, -- Breakfast, Snack, Lunch, Post-workout, Dinner, Evening snack
  food_id UUID REFERENCES foods(id),
  food_name TEXT NOT NULL, -- Denormalized for history safety
  grams DECIMAL NOT NULL,
  -- Calculated at insert time
  protein_g DECIMAL NOT NULL,
  carbs_g DECIMAL NOT NULL,
  fat_g DECIMAL NOT NULL,
  kcal DECIMAL NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout programmes
CREATE TABLE programmes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, -- e.g. "3-day Push/Pull/Legs", "5-day PPL+Full"
  days_per_week INTEGER,
  description TEXT,
  is_preloaded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sessions within a programme
CREATE TABLE programme_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  programme_id UUID REFERENCES programmes(id) ON DELETE CASCADE,
  session_name TEXT NOT NULL, -- e.g. "Push", "Pull", "Legs", "Full Body"
  session_order INTEGER, -- 1, 2, 3...
  warm_up TEXT,
  cardio_after TEXT
);

-- Exercises within a session
CREATE TABLE session_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES programme_sessions(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  target_sets TEXT, -- e.g. "3"
  target_reps TEXT, -- e.g. "12-15"
  form_cue TEXT,
  why TEXT,
  exercise_order INTEGER
);

-- Logged workout sessions
CREATE TABLE workout_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  session_name TEXT NOT NULL,
  programme_id UUID REFERENCES programmes(id),
  programme_session_id UUID REFERENCES programme_sessions(id),
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Logged sets within a workout
CREATE TABLE set_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_log_id UUID REFERENCES workout_logs(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  set_number INTEGER NOT NULL,
  kg DECIMAL,
  reps INTEGER,
  completed BOOLEAN DEFAULT FALSE,
  rpe INTEGER, -- Rate of perceived exertion 1-10, optional
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Body weight and measurement log
CREATE TABLE body_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  weight_kg DECIMAL,
  body_fat_pct DECIMAL,
  waist_cm DECIMAL,
  chest_cm DECIMAL,
  arm_cm DECIMAL,
  thigh_cm DECIMAL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Supplement schedule
CREATE TABLE supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dose TEXT,
  notes TEXT,
  status TEXT DEFAULT 'continue', -- 'continue' or 'finish'
  display_order INTEGER
);

-- Reminders
CREATE TABLE reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL, -- e.g. "Morning smoothie", "Pre-gym creatine"
  time_of_day TIME NOT NULL, -- e.g. 07:00
  days TEXT[] DEFAULT ARRAY['mon','tue','wed','thu','fri','sat','sun'],
  -- Conditional: only on certain day types
  only_on TEXT, -- NULL = always, 'gym', 'football', 'rest'
  is_active BOOLEAN DEFAULT TRUE,
  message TEXT, -- notification body text
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily log of which day type was selected (drives calorie target + conditional reminders)
CREATE TABLE day_type_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  day_type TEXT NOT NULL, -- 'gym', 'football', 'gymfootball', 'rest'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, log_date)
);

-- Daily supplement-taken checklist state (drives the Dashboard checklist)
CREATE TABLE supplement_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  supplement_id UUID REFERENCES supplements(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  taken BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, supplement_id, log_date)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_foods_user_id ON foods(user_id);
CREATE INDEX idx_food_logs_user_date ON food_logs(user_id, log_date);
CREATE INDEX idx_workout_logs_user_date ON workout_logs(user_id, log_date);
CREATE INDEX idx_set_logs_workout_log_id ON set_logs(workout_log_id);
CREATE INDEX idx_body_logs_user_date ON body_logs(user_id, log_date);
CREATE INDEX idx_supplements_user_id ON supplements(user_id);
CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_programme_sessions_programme_id ON programme_sessions(programme_id);
CREATE INDEX idx_session_exercises_session_id ON session_exercises(session_id);
CREATE INDEX idx_day_type_logs_user_date ON day_type_logs(user_id, log_date);
CREATE INDEX idx_supplement_logs_user_date ON supplement_logs(user_id, log_date);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE programmes ENABLE ROW LEVEL SECURITY;
ALTER TABLE programme_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE set_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE day_type_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY;

-- profiles: a user can only see/edit their own row
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- foods: preloaded (user_id IS NULL) rows are readable by everyone; user rows are private
CREATE POLICY "foods_select" ON foods FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "foods_insert_own" ON foods FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "foods_update_own" ON foods FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "foods_delete_own" ON foods FOR DELETE USING (auth.uid() = user_id);

-- food_logs / workout_logs / set_logs / body_logs / supplements / reminders / day_type_logs: owner-only
CREATE POLICY "food_logs_all_own" ON food_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "workout_logs_all_own" ON workout_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "set_logs_all_own" ON set_logs FOR ALL USING (
  auth.uid() = (SELECT user_id FROM workout_logs WHERE workout_logs.id = set_logs.workout_log_id)
) WITH CHECK (
  auth.uid() = (SELECT user_id FROM workout_logs WHERE workout_logs.id = set_logs.workout_log_id)
);
CREATE POLICY "body_logs_all_own" ON body_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "supplements_all_own" ON supplements FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reminders_all_own" ON reminders FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "day_type_logs_all_own" ON day_type_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "supplement_logs_all_own" ON supplement_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- programmes / sessions / exercises: preloaded programmes are readable by all authenticated users;
-- writes are left open to any authenticated user since this is a single-user app.
CREATE POLICY "programmes_select" ON programmes FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "programmes_write" ON programmes FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "programme_sessions_select" ON programme_sessions FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "programme_sessions_write" ON programme_sessions FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "session_exercises_select" ON session_exercises FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "session_exercises_write" ON session_exercises FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- ============================================================================
-- PRELOADED DATA — shared library content (foods, programmes)
-- ============================================================================

INSERT INTO foods (name, brand, protein_per_100g, carbs_per_100g, fat_per_100g, kcal_per_100g, serving_size_g, serving_name, is_preloaded) VALUES
  ('SELF Micro Whey Active', 'SELF', 90, 3.3, 0, 377, 30, '1 scoop', TRUE),
  ('Oats dry', NULL, 12, 66, 6, 370, 30, '1 scoop', TRUE),
  ('Banana', NULL, 1.1, 23, 0.3, 95, 120, '1 medium', TRUE),
  ('Frozen blueberries', NULL, 0.7, 14, 0.3, 57, 50, 'portion', TRUE),
  ('Whole milk', NULL, 3.4, 4.8, 3.7, 65, NULL, 'per 100ml', TRUE),
  ('Whole egg', NULL, 13, 1.1, 11, 155, 55, '1 egg', TRUE),
  ('Egg white', NULL, 11, 0.7, 0.2, 52, 30, '1 white', TRUE),
  ('Chicken breast', NULL, 31, 0, 3, 165, NULL, 'per 100g', TRUE),
  ('Chicken leg', NULL, 25, 0, 10, 195, NULL, 'per 100g', TRUE),
  ('Chicken wings', NULL, 27, 0, 12, 215, NULL, 'per 100g', TRUE),
  ('Finnish oat bread (Täysjyvä)', NULL, 8, 40, 3, 220, 30, '1 slice', TRUE),
  ('Olive oil', NULL, 0, 0, 100, 884, NULL, 'per 100ml', TRUE),
  ('Glutamine powder', NULL, 0, 0, 0, 0, 5, '1 scoop', TRUE),
  ('Creatine monohydrate', NULL, 0, 0, 0, 0, 5, '1 scoop', TRUE),
  ('Electrolyte capsule', NULL, 0, 0, 0, 0, NULL, '1 capsule', TRUE);

-- Programme 1 — 3-day Push/Pull/Legs
WITH p1 AS (
  INSERT INTO programmes (name, days_per_week, description, is_preloaded)
  VALUES ('3-day Push/Pull/Legs', 3, 'Classic 3-day PPL split.', TRUE)
  RETURNING id
),
s_push AS (
  INSERT INTO programme_sessions (programme_id, session_name, session_order)
  SELECT id, 'Push', 1 FROM p1 RETURNING id
),
s_pull AS (
  INSERT INTO programme_sessions (programme_id, session_name, session_order)
  SELECT id, 'Pull', 2 FROM p1 RETURNING id
),
s_legs AS (
  INSERT INTO programme_sessions (programme_id, session_name, session_order)
  SELECT id, 'Legs + Core', 3 FROM p1 RETURNING id
)
INSERT INTO session_exercises (session_id, exercise_name, exercise_order)
SELECT id, name, ord FROM s_push, (VALUES
  ('Chest press machine', 1),
  ('Incline chest press', 2),
  ('Cable fly', 3),
  ('Shoulder press machine', 4),
  ('Cable lateral raise', 5),
  ('Tricep pushdown rope', 6),
  ('Overhead tricep extension', 7)
) AS ex(name, ord)
UNION ALL
SELECT id, name, ord FROM s_pull, (VALUES
  ('Lat pulldown wide', 1),
  ('Seated cable row', 2),
  ('Chest-supported row', 3),
  ('Face pull', 4),
  ('Cable bicep curl', 5),
  ('Hammer curl', 6)
) AS ex(name, ord)
UNION ALL
SELECT id, name, ord FROM s_legs, (VALUES
  ('Leg press', 1),
  ('Lying leg curl', 2),
  ('Leg extension', 3),
  ('Hip abductor', 4),
  ('Standing calf raise', 5),
  ('Goblet squat', 6),
  ('Plank', 7),
  ('Hanging knee raise', 8),
  ('Cable crunch', 9)
) AS ex(name, ord);

-- Programme 2 — 5-day Push/Pull/Legs/Upper/Lower
WITH p2 AS (
  INSERT INTO programmes (name, days_per_week, description, is_preloaded)
  VALUES ('5-day Push/Pull/Legs/Upper/Lower', 5, '5-day PPL + Upper/Full body split.', TRUE)
  RETURNING id
),
s1 AS (INSERT INTO programme_sessions (programme_id, session_name, session_order) SELECT id, 'Push', 1 FROM p2 RETURNING id),
s2 AS (INSERT INTO programme_sessions (programme_id, session_name, session_order) SELECT id, 'Pull', 2 FROM p2 RETURNING id),
s3 AS (INSERT INTO programme_sessions (programme_id, session_name, session_order) SELECT id, 'Legs', 3 FROM p2 RETURNING id),
s4 AS (INSERT INTO programme_sessions (programme_id, session_name, session_order) SELECT id, 'Upper body', 4 FROM p2 RETURNING id),
s5 AS (INSERT INTO programme_sessions (programme_id, session_name, session_order) SELECT id, 'Full body + Core', 5 FROM p2 RETURNING id)
INSERT INTO session_exercises (session_id, exercise_name, exercise_order)
SELECT id, name, ord FROM s1, (VALUES
  ('Chest press machine', 1),
  ('Incline chest press', 2),
  ('Cable fly', 3),
  ('Shoulder press machine', 4),
  ('Cable lateral raise', 5),
  ('Tricep pushdown rope', 6),
  ('Overhead tricep extension', 7)
) AS ex(name, ord)
UNION ALL
SELECT id, name, ord FROM s2, (VALUES
  ('Lat pulldown wide', 1),
  ('Seated cable row', 2),
  ('Chest-supported row', 3),
  ('Face pull', 4),
  ('Cable bicep curl', 5),
  ('Hammer curl', 6)
) AS ex(name, ord)
UNION ALL
SELECT id, name, ord FROM s3, (VALUES
  ('Leg press', 1),
  ('Lying leg curl', 2),
  ('Leg extension', 3),
  ('Hip abductor', 4),
  ('Standing calf raise', 5),
  ('Goblet squat', 6)
) AS ex(name, ord)
UNION ALL
SELECT id, name, ord FROM s4, (VALUES
  ('Chest press machine', 1),
  ('Lat pulldown wide', 2),
  ('Shoulder press machine', 3),
  ('Seated cable row', 4),
  ('Cable bicep curl', 5),
  ('Tricep pushdown rope', 6)
) AS ex(name, ord)
UNION ALL
SELECT id, name, ord FROM s5, (VALUES
  ('Goblet squat', 1),
  ('Chest-supported row', 2),
  ('Shoulder press machine', 3),
  ('Plank', 4),
  ('Hanging knee raise', 5),
  ('Cable crunch', 6)
) AS ex(name, ord);

-- ============================================================================
-- PER-USER DEFAULTS — supplements + reminders
-- Call SELECT seed_user_defaults(auth.uid()); once after a new user's profile
-- row is created (e.g. right after sign-up) to populate their starting
-- supplement stack and reminder schedule.
-- ============================================================================

CREATE OR REPLACE FUNCTION seed_user_defaults(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO supplements (user_id, name, dose, status, display_order) VALUES
    (target_user_id, 'Electrolyte capsule', '1 capsule on waking', 'continue', 1),
    (target_user_id, 'SELF Micro Whey', '3 scoops (split 600ml/400ml)', 'continue', 2),
    (target_user_id, 'Omega-3 Möller', '2 caps with smoothie', 'continue', 3),
    (target_user_id, 'Creatine monohydrate', '5g pre-gym or after lunch', 'continue', 4),
    (target_user_id, 'Glutamine', '5g post-workout', 'finish', 5),
    (target_user_id, 'Magnesium bisglycinate', '1 tsp before bed', 'finish', 6),
    (target_user_id, 'Glycine powder', '2g morning + 2g bed', 'finish', 7),
    (target_user_id, 'HBCD cluster dextrin', '20g in training water', 'finish', 8);

  INSERT INTO reminders (user_id, label, time_of_day, only_on, message) VALUES
    (target_user_id, 'Wake up — electrolyte + water', '06:00', NULL, 'Electrolyte capsule + water'),
    (target_user_id, 'Morning smoothie + omega-3', '07:00', NULL, 'Time for your morning smoothie and omega-3'),
    (target_user_id, 'Pre-gym creatine', '09:00', 'gym', 'Take your pre-gym creatine'),
    (target_user_id, 'Post-gym shake', '11:30', 'gym', 'Post-gym shake time'),
    (target_user_id, 'Lunch — boil eggs if needed', '13:00', NULL, 'Lunch time — boil eggs if needed'),
    (target_user_id, 'Pre-football banana', '17:00', 'football', 'Eat a banana before football'),
    (target_user_id, 'Evening protein scoop', '16:30', NULL, 'Evening protein scoop'),
    (target_user_id, 'Post-football shake', '22:00', 'football', 'Post-football shake time'),
    (target_user_id, 'Bed reminder', '23:30', NULL, 'Time to wind down for bed');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- AUTO-CREATE PROFILE + DEFAULTS ON SIGN-UP
-- Every other per-user table has a FK to profiles(id), so a profile row must
-- exist before the app can write anything. This trigger creates it (and
-- seeds supplements/reminders) the moment a new auth.users row appears.
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id) VALUES (NEW.id);
  PERFORM seed_user_defaults(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
