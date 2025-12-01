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


-- PROCEDURES

CREATE OR REPLACE FUNCTION calculate_strength_rank(
    p_user_id UUID,
    p_body_weight NUMERIC DEFAULT NULL
)
RETURNS TABLE (
    exercise_name TEXT,
    max_weight NUMERIC,
    ratio NUMERIC,
    rank TEXT,
    score NUMERIC,
    next_rank TEXT,
    next_target_weight NUMERIC,
    progress NUMERIC
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_body_weight NUMERIC;
    v_bw_factor NUMERIC;
    v_workout_log RECORD;
    v_exercise_log JSONB;
    v_exercise JSONB;
    v_set JSONB;
    v_weight NUMERIC;
    v_reps INTEGER;
    v_max_lifts JSONB := '{}'::JSONB;
    v_current_max NUMERIC;
    v_standards JSONB;
    v_rank TEXT;
    v_score NUMERIC;
    v_next_rank TEXT;
    v_next_target NUMERIC;
    v_progress NUMERIC;
BEGIN
    -- 1. Obtener peso corporal (usar el más reciente o el proporcionado)
    IF p_body_weight IS NULL THEN
        SELECT weight_kg INTO v_body_weight
        FROM weight_logs
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 1;
        
        -- Si no hay peso registrado, usar 75kg por defecto
        IF v_body_weight IS NULL THEN
            v_body_weight := 75.0;
        END IF;
    ELSE
        v_body_weight := p_body_weight;
    END IF;
    
    -- Calcular factor de peso corporal (Allometric Scaling)
    v_bw_factor := POWER(v_body_weight / 75.0, 0.66);
    
    -- 2. Extraer pesos máximos de workout_logs
    FOR v_workout_log IN 
        SELECT exercises_log 
        FROM workout_logs 
        WHERE user_id = p_user_id 
        AND finished_at IS NOT NULL
        AND exercises_log IS NOT NULL
    LOOP
        -- Parsear exercises_log como JSONB
        BEGIN
            v_exercise_log := v_workout_log.exercises_log::JSONB;
            
            -- Iterar sobre cada ejercicio
            FOR v_exercise IN SELECT * FROM jsonb_array_elements(v_exercise_log)
            LOOP
                -- Iterar sobre cada set
                FOR v_set IN SELECT * FROM jsonb_array_elements(v_exercise->'sets')
                LOOP
                    v_weight := (v_set->>'weight')::NUMERIC;
                    
                    -- Actualizar máximo si es necesario
                    IF v_weight > 0 THEN
                        v_current_max := COALESCE((v_max_lifts->(v_exercise->>'exercise_name'))::NUMERIC, 0);
                        
                        IF v_weight > v_current_max THEN
                            v_max_lifts := jsonb_set(
                                v_max_lifts,
                                ARRAY[v_exercise->>'exercise_name'],
                                to_jsonb(v_weight),
                                true
                            );
                        END IF;
                    END IF;
                END LOOP;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            -- Ignorar errores de parsing
            CONTINUE;
        END;
    END LOOP;
    
    -- 3. Calcular ranking para ejercicios principales
    FOR exercise_name, v_current_max IN 
        SELECT * FROM jsonb_each_text(v_max_lifts)
    LOOP
        -- Solo procesar ejercicios principales
        IF exercise_name NOT IN ('Sentadilla', 'Press Banca', 'Peso Muerto', 'Press Militar') AND
           NOT (exercise_name ILIKE '%squat%' OR 
                exercise_name ILIKE '%bench%' OR 
                exercise_name ILIKE '%deadlift%' OR 
                exercise_name ILIKE '%press%') THEN
            CONTINUE;
        END IF;
        
        -- Obtener estándares para este ejercicio
        v_standards := get_exercise_standards(exercise_name, v_bw_factor);
        
        -- Calcular ratio peso levantado / peso corporal
        ratio := v_current_max::NUMERIC / v_body_weight;
        
        -- Determinar rango y score
        IF ratio >= (v_standards->>'elite')::NUMERIC THEN
            v_rank := 'Élite';
            v_score := 3.0;
            v_next_rank := NULL;
            v_next_target := NULL;
            v_progress := 1.0;
        ELSIF ratio >= (v_standards->>'advanced')::NUMERIC THEN
            v_rank := 'Avanzado';
            v_score := 2.0 + (ratio - (v_standards->>'advanced')::NUMERIC) / 
                      ((v_standards->>'elite')::NUMERIC - (v_standards->>'advanced')::NUMERIC);
            v_next_rank := 'Élite';
            v_next_target := (v_standards->>'elite')::NUMERIC * v_body_weight;
            v_progress := (ratio - (v_standards->>'advanced')::NUMERIC) / 
                         ((v_standards->>'elite')::NUMERIC - (v_standards->>'advanced')::NUMERIC);
        ELSIF ratio >= (v_standards->>'intermediate')::NUMERIC THEN
            v_rank := 'Intermedio';
            v_score := 1.0 + (ratio - (v_standards->>'intermediate')::NUMERIC) / 
                      ((v_standards->>'advanced')::NUMERIC - (v_standards->>'intermediate')::NUMERIC);
            v_next_rank := 'Avanzado';
            v_next_target := (v_standards->>'advanced')::NUMERIC * v_body_weight;
            v_progress := (ratio - (v_standards->>'intermediate')::NUMERIC) / 
                         ((v_standards->>'advanced')::NUMERIC - (v_standards->>'intermediate')::NUMERIC);
        ELSE
            v_rank := 'Novato';
            v_score := LEAST(ratio / (v_standards->>'intermediate')::NUMERIC, 1.0);
            v_next_rank := 'Intermedio';
            v_next_target := (v_standards->>'intermediate')::NUMERIC * v_body_weight;
            v_progress := ratio / (v_standards->>'intermediate')::NUMERIC;
        END IF;
        
        -- Retornar fila
        RETURN QUERY SELECT 
            exercise_name,
            v_current_max::NUMERIC,
            ratio,
            v_rank,
            v_score,
            v_next_rank,
            v_next_target,
            v_progress;
    END LOOP;
    
    RETURN;
END;
$$;

-- Devuelve los estándares de fuerza para un ejercicio específico

CREATE OR REPLACE FUNCTION get_exercise_standards(
    p_exercise_name TEXT,
    p_bw_factor NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_standards JSONB;
BEGIN
    -- Normalizar nombre del ejercicio
    p_exercise_name := LOWER(TRIM(p_exercise_name));
    
    -- Sentadilla / Squat
    IF p_exercise_name LIKE '%sentadilla%' OR p_exercise_name LIKE '%squat%' THEN
        v_standards := jsonb_build_object(
            'novice', 0.78 * p_bw_factor,
            'intermediate', 1.42 * p_bw_factor,
            'advanced', 2.05 * p_bw_factor,
            'elite', 2.72 * p_bw_factor
        );
    
    -- Press Banca / Bench Press
    ELSIF p_exercise_name LIKE '%press banca%' OR p_exercise_name LIKE '%bench%' THEN
        v_standards := jsonb_build_object(
            'novice', 0.53 * p_bw_factor,
            'intermediate', 0.97 * p_bw_factor,
            'advanced', 1.45 * p_bw_factor,
            'elite', 1.96 * p_bw_factor
        );
    
    -- Peso Muerto / Deadlift
    ELSIF p_exercise_name LIKE '%peso muerto%' OR p_exercise_name LIKE '%deadlift%' THEN
        v_standards := jsonb_build_object(
            'novice', 0.97 * p_bw_factor,
            'intermediate', 1.74 * p_bw_factor,
            'advanced', 2.51 * p_bw_factor,
            'elite', 3.31 * p_bw_factor
        );
    
    -- Press Militar / Overhead Press
    ELSIF p_exercise_name LIKE '%press militar%' OR p_exercise_name LIKE '%overhead%' OR p_exercise_name LIKE '%military%' THEN
        v_standards := jsonb_build_object(
            'novice', 0.35 * p_bw_factor,
            'intermediate', 0.65 * p_bw_factor,
            'advanced', 0.97 * p_bw_factor,
            'elite', 1.32 * p_bw_factor
        );
    
    -- Estándar genérico
    ELSE
        v_standards := jsonb_build_object(
            'novice', 0.5 * p_bw_factor,
            'intermediate', 1.0 * p_bw_factor,
            'advanced', 1.5 * p_bw_factor,
            'elite', 2.0 * p_bw_factor
        );
    END IF;
    
    RETURN v_standards;
END;
$$;

-- Calcula el rango general del usuario (promedio de todos los ejercicios)

CREATE OR REPLACE FUNCTION get_overall_strength_rank(p_user_id UUID)
RETURNS TABLE (
    overall_rank TEXT,
    rank_index INTEGER,
    strength_score NUMERIC,
    valid_lifts INTEGER,
    body_weight NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_avg_score NUMERIC;
    v_count INTEGER;
    v_rank TEXT;
    v_body_weight NUMERIC;
BEGIN
    -- Obtener peso corporal
    SELECT weight_kg INTO v_body_weight
    FROM weight_logs
    WHERE user_id = p_user_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_body_weight IS NULL THEN
        v_body_weight := 75.0;
    END IF;
    
    -- Calcular promedio de scores
    SELECT AVG(score), COUNT(*) INTO v_avg_score, v_count
    FROM calculate_strength_rank(p_user_id, v_body_weight);
    
    -- Si no hay datos, retornar valores por defecto
    IF v_count = 0 THEN
        RETURN QUERY SELECT 
            'Sin datos'::TEXT,
            0::INTEGER,
            0.0::NUMERIC,
            0::INTEGER,
            v_body_weight;
        RETURN;
    END IF;
    
    -- Determinar rango basado en score promedio
    IF v_avg_score >= 3.0 THEN
        v_rank := 'Élite';
    ELSIF v_avg_score >= 2.0 THEN
        v_rank := 'Avanzado';
    ELSIF v_avg_score >= 1.0 THEN
        v_rank := 'Intermedio';
    ELSE
        v_rank := 'Novato';
    END IF;
    
    -- Determinar índice del rango
    RETURN QUERY SELECT 
        v_rank,
        CASE v_rank
            WHEN 'Novato' THEN 0
            WHEN 'Intermedio' THEN 1
            WHEN 'Avanzado' THEN 2
            WHEN 'Élite' THEN 3
            ELSE 0
        END,
        v_avg_score,
        v_count,
        v_body_weight;
END;
$$;

-- CREAR TABLA weight_logs (si no existe)

CREATE TABLE IF NOT EXISTS public.weight_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    weight_kg NUMERIC NOT NULL CHECK (weight_kg > 0),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT weight_logs_user_id_fkey FOREIGN KEY (user_id) 
        REFERENCES public.users_profiles(auth_user_id) ON DELETE CASCADE
);

-- Índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_weight_logs_user_created 
ON public.weight_logs(user_id, created_at DESC);

-- Obtener ranking de ejercicios individuales
-- SELECT * FROM calculate_strength_rank('user-uuid-here');

-- Obtener ranking general del usuario
-- SELECT * FROM get_overall_strength_rank('user-uuid-here');

-- Obtener ranking con peso corporal específico
-- SELECT * FROM calculate_strength_rank('user-uuid-here', 80.0);