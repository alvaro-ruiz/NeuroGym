CREATE TABLE public.exercises (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  primary_muscle text,
  equipment text,
  difficulty text,
  type text,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT exercises_pkey PRIMARY KEY (id),
  CONSTRAINT exercises_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users_profiles(auth_user_id)
);
CREATE TABLE public.routine_days (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  routine_id uuid NOT NULL,
  day_order integer NOT NULL,
  title text,
  notes text,
  duration_minutes integer,
  CONSTRAINT routine_days_pkey PRIMARY KEY (id),
  CONSTRAINT routine_days_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES public.routines(id)
);
CREATE TABLE public.routine_exercises (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  routine_day_id uuid NOT NULL,
  exercise_id uuid NOT NULL,
  exercise_order integer NOT NULL,
  sets integer,
  reps text,
  target_weight numeric,
  rest_seconds integer,
  tempo text,
  notes text,
  CONSTRAINT routine_exercises_pkey PRIMARY KEY (id),
  CONSTRAINT routine_exercises_routine_day_id_fkey FOREIGN KEY (routine_day_id) REFERENCES public.routine_days(id),
  CONSTRAINT routine_exercises_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES public.exercises(id)
);
CREATE TABLE public.routines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  owner_user_id uuid,
  is_public boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  embedding jsonb,
  CONSTRAINT routines_pkey PRIMARY KEY (id),
  CONSTRAINT routines_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users_profiles(auth_user_id)
);
CREATE TABLE public.users_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  auth_user_id uuid NOT NULL UNIQUE,
  display_name text,
  avatar_url text,
  bio text,
  goal text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_profiles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.workout_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  routine_id uuid,
  routine_day_id uuid,
  started_at timestamp with time zone DEFAULT now(),
  finished_at timestamp with time zone,
  perceived_effort integer CHECK (perceived_effort >= 1 AND perceived_effort <= 10),
  notes text,
  exercises_log jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT workout_logs_pkey PRIMARY KEY (id),
  CONSTRAINT workout_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users_profiles(auth_user_id),
  CONSTRAINT workout_logs_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES public.routines(id),
  CONSTRAINT workout_logs_routine_day_id_fkey FOREIGN KEY (routine_day_id) REFERENCES public.routine_days(id)
);
