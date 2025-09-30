-- Add is_overdue column to zadachi table
ALTER TABLE public.zadachi 
ADD COLUMN is_overdue boolean DEFAULT false;

-- Create function to automatically calculate is_overdue
CREATE OR REPLACE FUNCTION public.update_task_overdue_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Calculate if task is overdue
  -- Task is overdue if due_date has passed and status is not completed
  IF NEW.due_date IS NOT NULL AND NEW.due_date < NOW() AND NEW.status != 'completed' THEN
    NEW.is_overdue = true;
  ELSE
    NEW.is_overdue = false;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to automatically update is_overdue on insert or update
CREATE TRIGGER trigger_update_task_overdue_status
BEFORE INSERT OR UPDATE ON public.zadachi
FOR EACH ROW
EXECUTE FUNCTION public.update_task_overdue_status();

-- Update existing records
UPDATE public.zadachi 
SET is_overdue = (due_date < NOW() AND status != 'completed')
WHERE due_date IS NOT NULL;