-- Create function to get Moscow time (UTC+3)
CREATE OR REPLACE FUNCTION public.moscow_now()
RETURNS timestamp with time zone
LANGUAGE sql
STABLE
AS $$
  SELECT now() AT TIME ZONE 'Europe/Moscow';
$$;

-- Update automation_settings table defaults
ALTER TABLE public.automation_settings 
ALTER COLUMN created_at SET DEFAULT moscow_now(),
ALTER COLUMN updated_at SET DEFAULT moscow_now();

-- Update order_attachments table defaults
ALTER TABLE public.order_attachments 
ALTER COLUMN uploaded_at SET DEFAULT moscow_now(),
ALTER COLUMN created_at SET DEFAULT moscow_now(),
ALTER COLUMN updated_at SET DEFAULT moscow_now();

-- Update users table defaults
ALTER TABLE public.users 
ALTER COLUMN created_at SET DEFAULT moscow_now(),
ALTER COLUMN updated_at SET DEFAULT moscow_now(),
ALTER COLUMN last_seen SET DEFAULT moscow_now();

-- Update zadachi table defaults
ALTER TABLE public.zadachi 
ALTER COLUMN created_at SET DEFAULT moscow_now();

-- Update zakazi table defaults
ALTER TABLE public.zakazi 
ALTER COLUMN created_at SET DEFAULT moscow_now(),
ALTER COLUMN updated_at SET DEFAULT moscow_now();

-- Update trigger function to use Moscow time
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = moscow_now();
    RETURN NEW;
END;
$$;

-- Update overdue status function to use Moscow time
CREATE OR REPLACE FUNCTION public.update_task_overdue_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Calculate if task is overdue using Moscow time
  IF NEW.due_date IS NOT NULL AND NEW.due_date < moscow_now() AND NEW.status != 'completed' THEN
    NEW.is_overdue = true;
  ELSE
    NEW.is_overdue = false;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Update user activity functions to use Moscow time
CREATE OR REPLACE FUNCTION public.update_user_activity(user_uuid uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users 
  SET updated_at = moscow_now(),
      last_seen = moscow_now(),
      status = 'online'::user_status
  WHERE uuid_user = user_uuid;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_user_online(user_uuid uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users 
  SET status = 'online'::user_status, 
      last_seen = moscow_now(),
      updated_at = moscow_now()
  WHERE uuid_user = user_uuid;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_user_offline(user_uuid uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users 
  SET status = 'offline'::user_status,
      updated_at = moscow_now()
  WHERE uuid_user = user_uuid;
END;
$$;